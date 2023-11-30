// Import necessary modules and initialize constants
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, TransactWriteCommand } from '@aws-sdk/lib-dynamodb';
import { v4 as uuidv4 } from 'uuid';
import { addSongs } from '/opt/nodejs/add-streaming-service-songs.mjs';

const ddbDocClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const playlistsTable = process.env.PLAYLISTS_TABLE;
const tokensTable = process.env.TOKENS_TABLE;
const usersTable = process.env.USERS_TABLE;
const MAX_SONGS = 50;

export const addSongsHandler = async (event) => {
    console.info('received:', event);
    const { playlistId, songs } = JSON.parse(event.body);
    const claims = event.requestContext.authorizer?.claims;
    const cognitoUserId = claims['sub'];
    const timestamp = new Date().toISOString();

    if (!playlistId || !songs || songs.length === 0) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Missing required fields' }) };
    }

    if (songs.length > MAX_SONGS) {
        return { statusCode: 400, body: JSON.stringify({ message: `Song limit reached: ${MAX_SONGS}` }) };
    }

    const { transactItems, songDetails } = buildTransactItemsAndAddSongId(playlistId, songs, timestamp);

    try {
        await ddbDocClient.send(new TransactWriteCommand({ TransactItems: transactItems }));
        const streamingPlaylistData = await getPlaylistData(playlistId, usersTable); // Implement this function to get playlist data
        await addSongs(streamingPlaylistData.spotify.playlistId, cognitoUserId, songDetails, usersTable, tokensTable);

        return {
            statusCode: 200,
            body: JSON.stringify({ message: 'Songs added successfully' })
        };
    } catch (err) {
        console.error('Error:', err);
        await rollbackPlaylistData(transactItems);

        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Error adding songs to Collaborative Playlist' })
        };
    }
};

// Helper function to build transaction items for adding songs
function buildTransactItemsAndAddSongId(playlistId, songs, timestamp) {
    let transactItems = [];
    let songDetails = [];

    songs.forEach(song => {
        const songId = uuidv4();
        transactItems.push(createSongItem(playlistId, song, songId, timestamp));
        songDetails.push({ ...song, songId });
    });

    return { transactItems, songDetails };
}

// Helper function to create a song item for DynamoDB
function createSongItem(playlistId, song, songId, timestamp) {
    return {
        Put: {
            TableName: playlistsTable,
            Item: {
                PK: `cp#${playlistId}`,
                SK: `song#${songId}`,
                ...song,
                createdAt: timestamp
            }
        }
    };
}

async function rollbackPlaylistData(transactItems) {
    console.info('Rollback started');
    const deleteOperations = transactItems.map(item => ({
        Delete: {
            TableName: item.Put.TableName,
            Key: {
                PK: item.Put.Item.PK,
                SK: item.Put.Item.SK
            }
        }
    }));

    try {
        await ddbDocClient.send(new TransactWriteCommand({ TransactItems: deleteOperations }));
        console.info('Rollback successful');
    } catch (error) {
        console.error('Error during cleanup:', error);
    }
}
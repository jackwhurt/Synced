import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, TransactWriteCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { v4 as uuidv4 } from 'uuid';
import { isPlaylistValid } from '/opt/nodejs/playlist-validator.mjs';
import { prepareSpotifyAccounts } from '/opt/nodejs/spotify-utils.mjs';
import { addSongs } from '/opt/nodejs/streaming-service/add-songs.mjs';
import { syncPlaylists } from '/opt/nodejs/streaming-service/sync-collaborative-playlists.mjs';

const ddbDocClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const playlistsTable = process.env.PLAYLISTS_TABLE;
const tokensTable = process.env.TOKENS_TABLE;
const usersTable = process.env.USERS_TABLE;
const MAX_SONGS = 50;

export const addSongsHandler = async (event) => {
    console.info('Received:', event);
    const { playlistId, songs } = JSON.parse(event.body);
    const validationResponse = validateEvent(playlistId, songs);
    if(!validationResponse) return validationResponse;

    const timestamp = new Date().toISOString();
    const transactItems = buildTransactItems(playlistId, songs, timestamp);

    try {
        await ddbDocClient.send(new TransactWriteCommand({ TransactItems: transactItems }));
        const collaboratorsData = await getCollaborators(playlistId);
        const spotifyUsers = await prepareSpotifyAccounts(collaboratorsData.map(c => c.userId), usersTable, tokensTable);
        const spotifyUsersMap = new Map(spotifyUsers.map(user => [user.userId, user]));
        await syncPlaylists(playlistId, spotifyUsersMap, playlistsTable)
        const unsuccessfulUpdateUserIds = await addSongsToSpotifyPlaylists(songs, collaboratorsData, spotifyUsersMap);

        return buildSuccessResponse(unsuccessfulUpdateUserIds);
    } catch (err) {
        console.error('Error in addSongsHandler:', err);
        await rollbackPlaylistData(transactItems);

        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Error adding songs to Collaborative Playlist' })
        };
    }
};

async function validateEvent(playlistId, songs) {
    if (!playlistId || !songs || songs.length === 0) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Missing required fields' }) };
    }

    if (songs.length > MAX_SONGS) {
        return { statusCode: 400, body: JSON.stringify({ message: `Song limit reached: ${MAX_SONGS}` }) };
    }

    if (!await isPlaylistValid(playlistId, playlistsTable)) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Playlist doesn\'t exist: ' + playlistId }) };
    }

    return null;
}

function buildTransactItems(playlistId, songs, timestamp) {
    let transactItems = [];

    songs.forEach(song => {
        const songId = uuidv4();
        transactItems.push(createSongItem(playlistId, song, songId, timestamp));
    });

    return transactItems;
}

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

async function getCollaborators(playlistId) {
    const queryParams = {
        TableName: playlistsTable,
        KeyConditionExpression: 'PK = :pk and begins_with(SK, :sk)',
        ExpressionAttributeValues: {
            ':pk': `cp#${playlistId}`,
            ':sk': 'collaborator#'
        }
    };

    try {
        const data = await ddbDocClient.send(new QueryCommand(queryParams));
        // TODO: Filter by apple music id when implemented (return two objects)
        const collaboratorsData = data.Items
                                    .filter(collaborator => collaborator.spotifyPlaylistId)
                                    .map(collaborator => ({
                                        userId: collaborator.SK.replace('collaborator#', ''),
                                        spotifyPlaylistId: collaborator.spotifyPlaylistId
                                    }));
        return collaboratorsData
    } catch (err) {
        console.error('Error getting collaborators:', err);
        throw err;
    }
}

async function addSongsToSpotifyPlaylists(songs, collaboratorsData, spotifyUsersMap) {
    if(!collaboratorsData) return;
    let unsuccessfulUpdateUserIds = [];
    const collaboratorsSpotifyData = collaboratorsData.filter(collaborator => collaborator.spotifyPlaylistId);

    for (const collaborator of collaboratorsSpotifyData) {
        try{
            await addSongs(collaborator.spotifyPlaylistId, spotifyUsersMap.get(collaborator.userId), songs, playlistsTable);
        } catch (error) {
            console.info('Unsuccessful Spotify Playlist for user: ', collaborator.userId);
            unsuccessfulUpdateUserIds.push(collaborator.userId);
        }
    }

    return unsuccessfulUpdateUserIds;
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

function buildSuccessResponse(unsuccessfulUpdateUserIds) {
    let message = 'Songs added successfully';
    if (unsuccessfulUpdateUserIds.length > 0) {
        // Join user IDs with a comma and space for readability
        const failedUserIds = unsuccessfulUpdateUserIds.join(', ');
        message = `Songs added successfully except for the following user(s): ${failedUserIds}`;
    }

    return {
        statusCode: 200,
        body: JSON.stringify({ message })
    };
}
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, TransactWriteCommand } from '@aws-sdk/lib-dynamodb';
import { v4 as uuidv4 } from 'uuid';
import { createPlaylist } from '/opt/nodejs/create-streaming-service-playlist.mjs';

const ddbDocClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const playlistsTable = process.env.PLAYLISTS_TABLE;
const tokensTable = process.env.TOKENS_TABLE;
const usersTable = process.env.USERS_TABLE;
const MAX_SONGS = 50;
const MAX_COLLABORATORS = 10;

export const createCollaborativePlaylistHandler = async (event) => {
    console.info('received:', event);
    const response = parseAndValidateEvent(event);
    if (response) return response;

    const { playlist, collaborators, songs } = JSON.parse(event.body);
    const claims = event.requestContext.authorizer?.claims;
    const cognitoUserId = claims['sub'];
    const timestamp = new Date().toISOString();
    const playlistId = uuidv4();

    collaborators.push(cognitoUserId);

    const transactItems = buildTransactItems(playlistId, cognitoUserId, playlist, collaborators, songs, timestamp);

    try {
        await ddbDocClient.send(new TransactWriteCommand({ TransactItems: transactItems }));
    } catch (err) {
        console.error('Error', err);
        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Error creating the collaborative playlist' })
        };
    }

    try {
        await createPlaylist(playlist, cognitoUserId, usersTable, tokensTable);

        return {
            statusCode: 200,
            body: JSON.stringify({
                id: playlistId,
                playlist,
                collaborators,
                songs,
                createdAt: timestamp
            })
        };
    } catch (err) {
        await rollbackPlaylistData(transactItems);
        console.error('Error', err);

        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Error creating the collaborative playlist on Streaming Service' })
        };
    }
};

function parseAndValidateEvent(event) {
    if (!event.body) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Missing body' }) };
    }

    const { playlist, collaborators, songs } = JSON.parse(event.body);
    if (!playlist || !playlist.title) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Missing required fields' }) };
    }
    if (songs && songs.length > MAX_SONGS) {
        return { statusCode: 400, body: JSON.stringify({ message: `Song limit reached: ${MAX_SONGS}` }) };
    }
    if (collaborators && collaborators.length > MAX_COLLABORATORS) {
        return { statusCode: 400, body: JSON.stringify({ message: `Collaborator limit reached: ${MAX_COLLABORATORS}` }) };
    }
}

function buildTransactItems(playlistId, cognitoUserId, playlist, collaborators, songs, timestamp) {
    let transactItems = [createPlaylistItem(playlistId, cognitoUserId, playlist, collaborators, songs, timestamp)];

    if (songs) {
        transactItems.push(...songs.map(song => createSongItem(playlistId, song, timestamp)));
    }

    if (collaborators) {
        transactItems.push(...collaborators.map(collaboratorId => createCollaboratorItem(playlistId, cognitoUserId, collaboratorId, timestamp)));
    }

    return transactItems;
}

function createPlaylistItem(playlistId, userId, playlist, collaborators, songs, timestamp) {
    return {
        Put: {
            TableName: playlistsTable,
            Item: {
                PK: `cp#${playlistId}`,
                SK: 'metadata',
                createdBy: userId,
                ...playlist,
                collaboratorCount: collaborators ? collaborators.length + 1 : 1,
                songCount: songs ? songs.length : 0,
                createdAt: timestamp,
                updatedAt: timestamp
            }
        }
    };
}

function createSongItem(playlistId, song, timestamp) {
    const songId = uuidv4();
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

function createCollaboratorItem(playlistId, addedById, collaboratorId, timestamp) {
    return {
        Put: {
            TableName: playlistsTable,
            Item: {
                PK: `cp#${playlistId}`,
                SK: `collaborator#${collaboratorId}`,
                GSI1PK: `collaborator#${collaboratorId}`,
                addedBy: addedById,
                createdAt: timestamp
            }
        }
    };
}

async function rollbackPlaylistData(transactItems) {
    console.info('Rollback started');
    // Convert Put operations to Delete operations
    const deleteOperations = transactItems.map(item => ({
        Delete: {
            TableName: item.Put.TableName,
            Key: {
                PK: item.Put.Item.PK,
                SK: item.Put.Item.SK
            }
        }
    }));

    const transactParams = {
        TransactItems: deleteOperations
    };

    try {
        await ddbDocClient.send(new TransactWriteCommand(transactParams));

        console.info('Rollback successful');
    } catch (error) {
        console.error('Error during cleanup:', error);
    }
}


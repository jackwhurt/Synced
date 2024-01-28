import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, TransactWriteCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { createSpotifyPlaylist } from '/opt/nodejs/streaming-service/create-streaming-service-playlist.mjs';
import { deleteSpotifyPlaylist } from '/opt/nodejs/streaming-service/delete-streaming-service-playlist.mjs';
import { prepareSpotifyAccounts } from '/opt/nodejs/spotify-utils.mjs';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const activitiesTable = process.env.ACTIVITIES_TABLE;
const playlistsTable = process.env.PLAYLISTS_TABLE;
const tokensTable = process.env.TOKENS_TABLE;
const usersTable = process.env.USERS_TABLE;

export const resolvePlaylistRequestHandler = async (event) => {
    console.info('Received:', event);

    try {
        const claims = event.requestContext.authorizer?.claims;
        const userId = claims['sub'];
        const requestId = event.queryStringParameters.requestId;
        const result = event.queryStringParameters.result === 'true';
        const spotifyPlaylist = event.queryStringParameters.spotifyPlaylist === 'true';
        const playlistId = await getPlaylistId(userId, requestId);

        await resolveRequest(userId, requestId, playlistId, result, spotifyPlaylist);

        console.info(`Request with ID ${requestId} resolved successfully`);
        return createSuccessResponse(200, { message: 'Request resolved successfully' });
    } catch (err) {
        console.error('Error resolving request:', err);
        return createErrorResponse(err);
    }
};

async function getPlaylistId(userId, requestId) {
    const queryParams = {
        TableName: activitiesTable,
        KeyConditionExpression: 'PK = :userId AND SK = :requestId',
        ExpressionAttributeValues: {
            ':userId': userId,
            ':requestId': requestId
        }
    };

    try {
        const data = await ddbDocClient.send(new QueryCommand(queryParams));
        if (data.Items.length > 0) {
            return data.Items[0].playlistId;
        } else {
            throw new Error('Playlist request not found');
        }
    } catch (error) {
        console.error('Error fetching playlist request:', error);
        throw error;
    }
}

async function getPlaylistMetadata(playlistId) {
    const queryParams = {
        TableName: playlistsTable,
        KeyConditionExpression: 'PK = :pk and SK = :sk',
        ExpressionAttributeValues: {
            ':pk': `cp#${playlistId}`,
            ':sk': 'metadata'
        }
    };

    try {
        const data = await ddbDocClient.send(new QueryCommand(queryParams));
        if (data.Items.length > 0) {
            return {
                playlistId: data.Items[0].PK.split('#')[1],
                description: data.Items[0].description,
                title: data.Items[0].title,
            };
        } else {
            throw new Error('Playlist metadata not found');
        }
    } catch (error) {
        console.error('Error fetching playlist metadata:', error);
        throw error;
    }
}

async function resolveRequest(userId, requestId, playlistId, result, spotifyPlaylist) {
    const transactItems = [];
    let spotifyPlaylistId;
    let spotifyUsers, failedSpotifyUsers;

    if (result && spotifyPlaylist) {
        ({ spotifyUsers, failedSpotifyUsers } = await prepareSpotifyAccounts([userId], usersTable, tokensTable));
        if (!failedSpotifyUsers) throw new Error('Spotify account could not be prepared for user: ' + userId);

        spotifyPlaylistId = await handleSpotifyPlaylistCreation(spotifyUsers, playlistId);

        transactItems.push(updateCollaboratorStatus(userId, playlistId));
    } else {
        transactItems.push(deleteCollaborator(userId, playlistId));
    }

    transactItems.push(deleteRequest(userId, requestId));

    try {
        await ddbDocClient.send(new TransactWriteCommand({ TransactItems: transactItems }));
    } catch (error) {
        console.error('Failed to update db for resolve playlist request');

        console.info('Rollback started');
        await deleteSpotifyPlaylist(spotifyPlaylistId, spotifyUsers[0]);
        console.info('Rollback successful');

        throw error;
    }
}

async function handleSpotifyPlaylistCreation(spotifyUsers, playlistId) {
    const playlist = await getPlaylistMetadata(playlistId);
    const spotifyPlaylistId = await createSpotifyPlaylist(playlist, spotifyUsers[0], playlistsTable);
    return spotifyPlaylistId;
}

function updateCollaboratorStatus(userId, playlistId) {
    return {
        Update: {
            TableName: playlistsTable,
            Key: {
                PK: `cp#${playlistId}`,
                SK: `collaborator#${userId}`
            },
            UpdateExpression: 'SET requestStatus = :status',
            ExpressionAttributeValues: {
                ':status': 'accepted'
            }
        }
    };
}

function deleteCollaborator(userId, playlistId) {
    return {
        Delete: {
            TableName: playlistsTable,
            Key: {
                PK: `cp#${playlistId}`,
                SK: `collaborator#${userId}`
            }
        }
    };
}

function deleteRequest(userId, requestId) {
    return {
        Delete: {
            TableName: activitiesTable,
            Key: {
                PK: userId,
                SK: requestId
            }
        }
    };
}

function createSuccessResponse(statusCode, body) {
    return {
        statusCode,
        body: JSON.stringify(body)
    };
}

function createErrorResponse(error) {
    return {
        statusCode: error.statusCode || 500,
        body: JSON.stringify({ error: error.message || 'An unknown error occurred' })
    };
}

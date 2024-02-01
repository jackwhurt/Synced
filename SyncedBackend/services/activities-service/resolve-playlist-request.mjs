import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, TransactWriteCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { createSpotifyPlaylist } from '/opt/nodejs/streaming-service/create-streaming-service-playlist.mjs';
import { deleteSpotifyPlaylist } from '/opt/nodejs/streaming-service/delete-streaming-service-playlist.mjs';
import { prepareSpotifyAccounts } from '/opt/nodejs/spotify-utils.mjs';
import { getCollaboratorsByPlaylistId } from '/opt/nodejs/get-collaborators.mjs';
import { createNotifications } from '/opt/nodejs/create-notifications.mjs';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const activitiesTable = process.env.ACTIVITIES_TABLE;
const playlistsTable = process.env.PLAYLISTS_TABLE;
const tokensTable = process.env.TOKENS_TABLE;
const usersTable = process.env.USERS_TABLE;
const isDevEnvironment = process.env.DEV_ENVIRONMENT === 'true';

export const resolvePlaylistRequestHandler = async (event) => {
    console.info('Received:', event);

    const claims = event.requestContext.authorizer?.claims;
    const cognitoUserId = claims['sub'];
    const requestId = event.queryStringParameters.requestId;
    const result = event.queryStringParameters.result === 'true';
    const spotifyPlaylist = event.queryStringParameters.spotifyPlaylist === 'true';

    let playlist;

    try {
        const playlistId = await getPlaylistId(cognitoUserId, requestId);
        playlist = await getPlaylistMetadata(playlistId);
        if (!playlist) await performTransactions([], requestId, null, [], cognitoUserId);
        else await performTransactionsAndResolve(cognitoUserId, requestId, playlist, result, spotifyPlaylist);

        console.info(`Request with ID ${requestId} resolved successfully`);
    } catch (err) {
        console.error('Error resolving request:', err);
        return createErrorResponse(err);
    }

    if (playlist) await sendNotifications(playlist, cognitoUserId);

    return createSuccessResponse(200, { message: 'Request resolved successfully' });
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
            return null;
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
        }
    } catch (error) {
        console.error('Error fetching playlist metadata:', error);
        throw error;
    }
}

async function performTransactions(transactItems, requestId, spotifyPlaylistId, spotifyUsers, userId) {
    transactItems.push(deleteRequest(userId, requestId));

    try {
        await ddbDocClient.send(new TransactWriteCommand({ TransactItems: transactItems }));
    } catch (error) {
        console.error('Failed to update db for resolve playlist request');

        if (spotifyPlaylistId && spotifyUsers) {
            console.info('Rollback started');
            await deleteSpotifyPlaylist(spotifyPlaylistId, spotifyUsers[0]);
            console.info('Rollback successful');
        }

        throw error;
    }
}

async function performTransactionsAndResolve(userId, requestId, playlist, result, spotifyPlaylist) {
    const transactItems = [];
    let spotifyPlaylistId;
    let spotifyUsers, failedSpotifyUsers;

    if (result) {
        transactItems.push(updateCollaboratorStatus(userId, playlist.playlistId));
        if (spotifyPlaylist) {
            ({ spotifyUsers, failedSpotifyUsers } = await prepareSpotifyAccounts([userId], usersTable, tokensTable));
            if (failedSpotifyUsers) throw new Error('Spotify account could not be prepared for user: ' + userId);

            spotifyPlaylistId = await createSpotifyPlaylist(playlist, spotifyUsers[0], playlistsTable);
        }
    } else {
        transactItems.push(deleteCollaborator(userId, playlist.playlistId));
    }

    await performTransactions(transactItems, requestId, spotifyPlaylistId, spotifyUsers, userId);
}

async function sendNotifications(playlist, cognitoUserId) {
    const message = `@{user} has joined ${playlist.title}!`;

    try {
        const collaborators = await getCollaboratorsByPlaylistId(playlist.playlistId, playlistsTable);
        await createNotifications(collaborators.map(collaborator => collaborator.userId), message, cognitoUserId,
            playlist.playlistId, activitiesTable, usersTable, playlistsTable, isDevEnvironment);
    } catch (error) {
        console.error('Notification unsuccessful', error);
    }
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

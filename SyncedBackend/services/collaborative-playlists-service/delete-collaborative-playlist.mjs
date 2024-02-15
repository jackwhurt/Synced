import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand, TransactWriteCommand } from '@aws-sdk/lib-dynamodb';
import { deleteSpotifyPlaylist } from '/opt/nodejs/streaming-service/delete-streaming-service-playlist.mjs';
import { prepareSpotifyAccounts } from '/opt/nodejs/spotify-utils.mjs';

const ddbDocClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const playlistsTable = process.env.PLAYLISTS_TABLE;
const tokensTable = process.env.TOKENS_TABLE;
const usersTable = process.env.USERS_TABLE;

const MAX_TRANSACTION_ITEMS = 100;

// TODO: Delete images
export const deleteCollaborativePlaylistHandler = async (event) => {
    console.info('Received:', event);

    if (!event.pathParameters || !event.pathParameters.id) {
        return createErrorResponse({ statusCode: 400, message: 'Missing playlistId in path parameters' });
    }

    const userId = event.requestContext.authorizer.claims.sub;
    const playlistId = event.pathParameters.id;
    let deletedRecords, error;

    try {
        const playlistRecords = await fetchPlaylistRecords(playlistId);
        const metadataRecord = playlistRecords.find(record => record.SK === 'metadata');
        if (!metadataRecord) {
            return createErrorResponse({ statusCode: 404, message: 'Playlist not found' });
        } else if (metadataRecord.createdBy !== userId) {
            return createErrorResponse({ statusCode: 403, message: 'Not authorized to delete this playlist' });
        }

        ({ deletedRecords, error } = await deletePlaylistRecords(playlistRecords));
        if (error) throw new Error(error);

        const spotifyDetails = extractSpotifyPlaylistDetails(playlistRecords);
        await deleteSpotifyPlaylists(spotifyDetails);

        await addAppleMusicDeleteFlag(playlistRecords);

        return createSuccessResponse(playlistId);
    } catch (err) {
        console.error('Error:', err);
        await rollbackDeletes(deletedRecords);
        return createErrorResponse(err);
    }
};

async function deleteSpotifyPlaylists(spotifyDetails) {
    const uniqueUserIds = [...new Set(spotifyDetails.map(detail => detail.userId))];
    const { spotifyUsers, failedSpotifyUsers } = await prepareSpotifyAccounts(uniqueUserIds, usersTable, tokensTable);

    for (const { userId, spotifyPlaylistId } of spotifyDetails) {
        try {
            const spotifyUser = spotifyUsers.find(user => user.userId === userId);
            if (spotifyUser && spotifyPlaylistId) {
                await deleteSpotifyPlaylist(spotifyPlaylistId, spotifyUser);
            }
        } catch (err) {
            console.error(`Failed to delete Spotify playlist: ${spotifyPlaylistId} for user: ${userId}`, err);
        }
    }
}

function extractSpotifyPlaylistDetails(playlistRecords) {
    return playlistRecords
        .filter(record => record.SK.startsWith('collaborator#') && record.spotifyPlaylistId)
        .map(record => ({ userId: record.SK.split('#')[1], spotifyPlaylistId: record.spotifyPlaylistId }));
}

async function fetchPlaylistRecords(playlistId) {
    const queryParams = { TableName: playlistsTable, KeyConditionExpression: 'PK = :pk', ExpressionAttributeValues: { ':pk': `cp#${playlistId}` } };
    const result = await ddbDocClient.send(new QueryCommand(queryParams));
    return result.Items;
}

async function deletePlaylistRecords(playlistRecords) {
    const deletedRecords = [];
    let error = null;

    try {
        for (let i = 0; i < playlistRecords.length; i += MAX_TRANSACTION_ITEMS) {
            const slice = playlistRecords.slice(i, i + MAX_TRANSACTION_ITEMS);
            const batch = createDeleteBatch(slice);
            await ddbDocClient.send(new TransactWriteCommand({ TransactItems: batch }));
            deletedRecords.push(...slice);
        }
    } catch (err) {
        console.error('Failed to delete playlist records:', err);
        error = err;
    }

    return { deletedRecords, error };
}

async function addAppleMusicDeleteFlag(playlistRecords) {
    const deleteFlags = playlistRecords
        .filter(record => record.SK.startsWith('collaborator#') && record.appleMusicPlaylistId)
        .map(record => ({
            PK: `deleteFlag#${record.SK.split('#')[1]}`,
            SK: record.PK,
            appleMusicPlaylistId: record.appleMusicPlaylistId
        }));
    const transactItems = deleteFlags.map(record => ({ Put: { TableName: playlistsTable, Item: record } }));

    try {
        await ddbDocClient.send(new TransactWriteCommand({ TransactItems: transactItems }));
    } catch (err) {
        console.error('Failed to add Apple Music delete flags:', err);
    }
}

function createDeleteBatch(batch) {
    return batch.map(record => ({ Delete: { TableName: playlistsTable, Key: { PK: record.PK, SK: record.SK } } }));
}

async function rollbackDeletes(deletedRecords) {
    for (const record of deletedRecords) {
        const putParams = {
            TableName: playlistsTable,
            Item: record
        };
        try {
            await ddbDocClient.send(new TransactWriteCommand({ TransactItems: [{ Put: putParams }] }));
        } catch (rollbackError) {
            console.error('Rollback error:', rollbackError);
        }
    }
}

function createSuccessResponse(playlistId) {
    console.info('Deleted playlist data:', { playlistId });
    return { statusCode: 200, body: JSON.stringify({ id: playlistId }) };
}

function createErrorResponse(error) {
    console.error(error.message || 'Error processing request');
    return { statusCode: error.statusCode || 500, body: JSON.stringify({ message: error.message || 'Error processing request' }) };
}

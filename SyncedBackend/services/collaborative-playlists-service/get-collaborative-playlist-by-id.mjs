import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand, BatchGetCommand } from '@aws-sdk/lib-dynamodb';
import { getUsers } from '/opt/nodejs/get-users.mjs';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);
const playlistsTable = process.env.PLAYLISTS_TABLE;
const usersTable = process.env.USERS_TABLE;

export const getCollaborativePlaylistByIdHandler = async (event) => {
    console.info('received:', event);
    const playlistUuid = event.pathParameters?.id;

    if (!playlistUuid) {
        return handleError('No playlist ID provided', null, 400);
    }

    const userId = event.requestContext.authorizer?.claims['sub'];
    const playlistId = `cp#${playlistUuid}`;

    try {
        const playlist = await getPlaylistData(playlistId, userId);
        if (!playlist) {
            return handleError('Playlist not found', null, 404);
        }

		console.info(`returned: ${JSON.stringify(playlist)}`);

        return {
            statusCode: 200,
            body: JSON.stringify(playlist)
        };
    } catch (err) {
        return handleError('Error retrieving playlist', err, 500);
    }
};

async function getPlaylistData(playlistId, userId) {
    const playlistItemsData = await queryPlaylistItems(playlistId);
    if (playlistItemsData.Items.length === 0) {
        return null;
    }
    return await processPlaylistItems(playlistItemsData.Items, userId);
}

async function queryPlaylistItems(playlistId) {
    const params = {
        TableName: playlistsTable,
        KeyConditionExpression: 'PK = :pk',
        ExpressionAttributeValues: { ':pk': playlistId }
    };

    try {
        return await ddbDocClient.send(new QueryCommand(params));
    } catch (err) {
        throw new Error('Failed to query playlist items');
    }
}

async function processPlaylistItems(items, userId) {
    const collaboratorsIds = items.filter(item => item.SK.startsWith('collaborator#')).map(item => item.GSI1PK.split('#')[1]);
    const collaborators = collaboratorsIds.length > 0 ? await getUsers(collaboratorsIds, usersTable) : [];
    const playlistMetadata = items.find(item => item.SK === 'metadata') || null;
    const songs = items.filter(item => item.SK.startsWith('song#')).map(item => ({ ...item, songId: item.SK.substring(5) })).sort((a, b) => a.createdAt.localeCompare(b.createdAt));
    const userItem = items.find(item => item.SK === `collaborator#${userId}`);
    const appleMusicPlaylistId = userItem ? userItem.appleMusicPlaylistId : '';

    return {
        playlistId: playlistMetadata ? playlistMetadata.PK.substring(3) : 'Unknown',
        metadata: playlistMetadata,
        collaborators,
        songs,
        appleMusicPlaylistId
    };
}

function handleError(message, err, statusCode) {
    console.error(message, err);
    return {
        statusCode: statusCode || 500,
        body: JSON.stringify({ error: message })
    };
}

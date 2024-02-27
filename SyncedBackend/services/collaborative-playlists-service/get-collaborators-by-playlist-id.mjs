import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { getUsers } from '/opt/nodejs/get-users.mjs';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);
const playlistsTable = process.env.PLAYLISTS_TABLE;
const usersTable = process.env.USERS_TABLE;

export const getCollaboratorsByPlaylistIdHandler = async (event) => {
    console.info('received:', event);
    const queryStringParameters = event.queryStringParameters || {};
    const playlistId = queryStringParameters.playlistId || null;
    if (!playlistId) {
        return handleError('No playlist ID provided', null, 400);
    }
    try {
        const playlistItemsData = await queryPlaylistItems(playlistId);
        if (playlistItemsData.Items.length === 0) {
            return handleError('Collaborators not found', null, 404);
        }
        const metadataItem = playlistItemsData.Items.find(item => item.SK === 'metadata');
        const ownerId = metadataItem?.createdBy;
        const collaboratorsWithStatus = await processPlaylistItemsForCollaborators(playlistItemsData.Items, ownerId);
        console.info(`returned: ${JSON.stringify(collaboratorsWithStatus)}`);
        return {
            statusCode: 200,
            body: JSON.stringify({ collaborators: collaboratorsWithStatus })
        };
    } catch (err) {
        return handleError('Error retrieving collaborators', err, 500);
    }
};

async function queryPlaylistItems(playlistId) {
    const params = {
        TableName: playlistsTable,
        KeyConditionExpression: 'PK = :pk',
        ExpressionAttributeValues: { ':pk': `cp#${playlistId}` }
    };
    try {
        return await ddbDocClient.send(new QueryCommand(params));
    } catch (err) {
        throw new Error('Failed to query playlist items');
    }
}

async function processPlaylistItemsForCollaborators(items, ownerId) {
    const collaboratorsDetails = items.filter(item => item.SK.startsWith('collaborator#'))
        .map(item => ({
            userId: item.GSI1PK.split('#')[1],
            requestStatus: item.requestStatus
        }));
    const userIds = collaboratorsDetails.map(detail => detail.userId);
    const users = await getUsers(userIds, usersTable);
    const userMap = users.reduce((acc, user) => {
        acc[user.userId] = user;
        return acc;
    }, {});
    const collaboratorsWithStatus = collaboratorsDetails.map(detail => {
        const user = userMap[detail.userId];
        return {
            userId: user.userId,
            username: user.username,
            email: user.email,
            photoUrl: user.photoUrl,
            requestStatus: detail.requestStatus,
            isPlaylistOwner: detail.userId === ownerId
        };
    });
    return collaboratorsWithStatus;
}

function handleError(message, err, statusCode) {
    console.error(message, err);
    return {
        statusCode: statusCode || 500,
        body: JSON.stringify({ error: message })
    };
}

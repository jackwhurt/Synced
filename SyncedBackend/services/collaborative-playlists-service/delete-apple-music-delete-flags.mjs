import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, TransactWriteCommand } from '@aws-sdk/lib-dynamodb';

const ddbDocClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const playlistsTable = process.env.PLAYLISTS_TABLE;

export const deleteAppleMusicDeleteFlagsHandler = async (event) => {
    console.info('Received:', event);

    const playlistIds = parseEventBody(event.body);
    if (!playlistIds) {
        return createErrorResponse({ statusCode: 400, message: 'Missing or invalid playlistIds in request body' });
    }

    const userId = event.requestContext.authorizer.claims.sub;

    try {
        await deletePlaylists(userId, playlistIds);
        return createSuccessResponse({ message: 'Delete flags deleted successfully' });
    } catch (err) {
        return createErrorResponse(err);
    }
};

function parseEventBody(body) {
    try {
        const parsedBody = JSON.parse(body);
        if (Array.isArray(parsedBody.playlistIds) && parsedBody.playlistIds.length > 0) {
            return parsedBody.playlistIds;
        }
    } catch (err) {
        console.error('Error parsing event body:', err);
    }
    return null;
}

async function deletePlaylists(userId, playlistIds) {
    const deleteOperations = playlistIds.map(playlistId => createDeleteOperation(userId, playlistId));

    for (let i = 0; i < deleteOperations.length; i += 100) {
        const batch = deleteOperations.slice(i, i + 100);
        await ddbDocClient.send(new TransactWriteCommand({ TransactItems: batch }));
    }
}

function createDeleteOperation(userId, playlistId) {
    return {
        Delete: {
            TableName: playlistsTable,
            Key: {
                PK: `deleteFlag#${userId}`,
                SK: `cp#${playlistId}`
            }
        }
    };
}

function createSuccessResponse(body) {
    console.info('Response:', body);
    return { statusCode: 200, body: JSON.stringify(body) };
}

function createErrorResponse(error) {
    console.error('Error:', error);
    return { statusCode: error.statusCode || 500, body: JSON.stringify({ message: error.message || 'Error processing request' }) };
}

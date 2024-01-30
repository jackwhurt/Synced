import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand, BatchGetCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const activitiesTable = process.env.ACTIVITIES_TABLE;
const playlistsTable = process.env.PLAYLISTS_TABLE;

// TODO: Deal with old playlist ids that have been deleted
export const getRequestsHandler = async (event) => {
    console.info('received:', event);

    try {
        const claims = event.requestContext.authorizer?.claims;
        const userId = claims['sub'];

        const queryStringParameters = event.queryStringParameters || {};
        const page = parseInt(queryStringParameters.page || "1", 10);
        const lastEvaluatedKey = queryStringParameters.lastEvaluatedKey || null;

        const result = await queryRequestsByUserId(userId, page, lastEvaluatedKey);
        console.info('Found: ', result)

        return createSuccessResponse(200, result);
    } catch (err) {
        console.error('Error querying requests by userId:', err);
        return createErrorResponse(err);
    }
}

async function queryRequestsByUserId(userId, page, lastEvaluatedKey) {
    const queryResult = await executeQuery(userId, lastEvaluatedKey);
    let items = transformItems(queryResult.Items);

    const playlistIds = extractUniquePlaylistIds(items);
    if (playlistIds.length > 0) {
        const playlistMetadata = await fetchPlaylistMetadata(playlistIds);
        items = addPlaylistMetadataToItems(items, playlistMetadata);
    }

    console.info(`Page ${page} of requests found for userId: ${userId}`);
    return formatResponse(items, queryResult.LastEvaluatedKey);
}

async function executeQuery(userId, lastEvaluatedKey) {
    const params = {
        TableName: activitiesTable,
        KeyConditionExpression: 'PK = :userId AND begins_with(SK, :requestPrefix)',
        ExpressionAttributeValues: { ':userId': userId, ':requestPrefix': 'request' },
        Limit: 10,
        ExclusiveStartKey: lastEvaluatedKey ? JSON.parse(lastEvaluatedKey) : undefined
    };

    return await ddbDocClient.send(new QueryCommand(params));
}

function transformItems(items) {
    return items.map(({ PK, SK, ...rest }) => ({
        ...rest,
        userId: PK,
        requestId: SK
    }));
}

function extractUniquePlaylistIds(items) {
    return [...new Set(items.filter(item => item.requestId.startsWith('requestPlaylist'))
                           .map(item => item.playlistId))];
}

async function fetchPlaylistMetadata(playlistIds) {
    const keysToGet = playlistIds.map(id => ({ PK: `cp#${id}`, SK: 'metadata' }));
    const batchParams = { RequestItems: { [playlistsTable]: { Keys: keysToGet } } };
    const batchResult = await ddbDocClient.send(new BatchGetCommand(batchParams));

    return batchResult.Responses[playlistsTable].reduce((acc, item) => {
        acc[item.PK.split('#')[1]] = { title: item.title, description: item.description };
        return acc;
    }, {});
}

function addPlaylistMetadataToItems(items, playlistMetadata) {
    return items.map(item => {
        if (item.requestId.startsWith('requestPlaylist')) {
            const playlistId = item.playlistId;
            const metadata = playlistMetadata[playlistId] || {};
            return { ...item, playlistTitle: metadata.title || 'Unknown', playlistDescription: metadata.description || 'No description' };
        }
        return item;
    });
}

function formatResponse(items, lastEvaluatedKey) {
    return {
        requests: {
            playlistRequests: items.filter(item => item.requestId.startsWith('requestPlaylist')),
            userRequests: items.filter(item => item.requestId.startsWith('requestUser'))
        },
        lastEvaluatedKey: lastEvaluatedKey ? JSON.stringify(lastEvaluatedKey) : null
    };
}

function createSuccessResponse(statusCode, body) {
    return {
        statusCode: statusCode,
        body: JSON.stringify(body)
    };
}

function createErrorResponse(error) {
    console.error('Error: ', error);
    
    return {
        statusCode: error.statusCode || 500,
        body: JSON.stringify({
            error: error.message || 'An unknown error occurred'
        })
    };
}

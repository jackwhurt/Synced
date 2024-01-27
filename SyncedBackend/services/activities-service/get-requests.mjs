import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const activitiesTable = process.env.ACTIVITIES_TABLE;

export const getRequestsHandler = async (event) => {
    console.info('received:', event);

    try {
        const claims = event.requestContext.authorizer?.claims;
        const userId = claims['sub'];
        const page = parseInt(event.queryStringParameters.page || "1", 10);
        const lastEvaluatedKey = event.queryStringParameters.lastEvaluatedKey || null;
        const result = await queryRequestsByUserId(userId, page, lastEvaluatedKey);
        console.info('Found: ', result)

        return createResponse(200, result);
    } catch (err) {
        console.error('Error querying requests by userId:', err);
        return createErrorResponse(err);
    }
}

async function queryRequestsByUserId(userId, page, lastEvaluatedKey) {
    const params = {
        TableName: activitiesTable,
        KeyConditionExpression: 'PK = :userId AND begins_with(SK, :requestPrefix)',
        ExpressionAttributeValues: {
            ':userId': userId,
            ':requestPrefix': 'request'
        },
        Limit: 10,
    };

    if (lastEvaluatedKey) {
        params.ExclusiveStartKey = JSON.parse(lastEvaluatedKey);
    }

    const result = await ddbDocClient.send(new QueryCommand(params));

    console.info(`Page ${page} of requests found for userId: ${userId}`);
    return {
        requests: {
            playlists: result.Items.filter(item => item.SK.startsWith('requestPlaylist')),
            users: result.Items.filter(item => item.SK.startsWith('requestUser'))
        },
        lastEvaluatedKey: result.LastEvaluatedKey ? JSON.stringify(result.LastEvaluatedKey) : null
    };
}

function createResponse(statusCode, body) {
    return {
        statusCode,
        body: JSON.stringify(body)
    };
}

function createErrorResponse(err) {
    return {
        statusCode: err.statusCode || 500,
        body: JSON.stringify({ error: err.message })
    };
}

import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const activitiesTable = process.env.ACTIVITIES_TABLE;

export const getNotificationsHandler = async (event) => {
    console.info('received:', event);

    try {
        const claims = event.requestContext.authorizer?.claims;
        const userId = claims['sub'];

        const queryStringParameters = event.queryStringParameters || {};
        const lastEvaluatedKey = queryStringParameters.lastEvaluatedKey || null;

        const result = await queryNotificationsByUserId(userId, lastEvaluatedKey);
        console.info('Notifications Found: ', result)

        return createSuccessResponse(200, result);
    } catch (err) {
        console.error('Error querying notifications by userId:', err);
        return createErrorResponse(err);
    }
};

async function queryNotificationsByUserId(userId, lastEvaluatedKey) {
    const params = {
        TableName: activitiesTable,
        KeyConditionExpression: 'PK = :userId AND begins_with(SK, :notificationPrefix)',
        ExpressionAttributeValues: { ':userId': userId, ':notificationPrefix': 'notification#' },
        Limit: 20, 
        ExclusiveStartKey: lastEvaluatedKey ? JSON.parse(lastEvaluatedKey) : undefined,
        ScanIndexForward: false 
    };

    const queryResult = await ddbDocClient.send(new QueryCommand(params));
    
    let items = queryResult.Items.map(({ PK, SK, ...rest }) => ({
        ...rest,
        userId: PK,
        notificationId: SK
    }));

    items.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    console.info(`Notifications found for userId: ${userId}`);
    return {
        notifications: items,
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

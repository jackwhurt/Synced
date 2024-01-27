import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const usersTable = process.env.USERS_TABLE;

export const getUsersHandler = async (event) => {
    console.info('received:', event);

    try {
        const claims = event.requestContext.authorizer?.claims;
        const userId = claims['sub'];
        const username = event.queryStringParameters.username;
        const page = parseInt(event.queryStringParameters.page || "1", 10);
        const lastEvaluatedKey = event.queryStringParameters.lastEvaluatedKey || null;
        const result = await queryUserByUsername(username, userId, page, lastEvaluatedKey);
        console.info('Found: ', result)

        return createResponse(200, result);
    } catch (err) {
        console.error('Error querying user by username:', err);
        return createErrorResponse(err);
    }
}

async function queryUserByUsername(username, userId, page, lastEvaluatedKey) {
    const params = {
        TableName: usersTable,
        IndexName: 'SearchIndex',
        KeyConditionExpression: 'userAttribute = :userAttribute AND begins_with(attributeValue, :username)',
        ExpressionAttributeValues: {
            ':userAttribute': 'username',
            ':username': username
        },
        Limit: 10,
    };

    if (lastEvaluatedKey) {
        params.ExclusiveStartKey = JSON.parse(lastEvaluatedKey);
    }

    const result = await ddbDocClient.send(new QueryCommand(params));

    const users = result.Items
        .filter(item => item.userId !== userId)
        .map(item => {
            const { attributeValue, ...rest } = item;
            return {
                ...rest,
                username: attributeValue
            };
        });

    console.info(`Page ${page} of users found with username: ${username}`);
    return {
        users: users,
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

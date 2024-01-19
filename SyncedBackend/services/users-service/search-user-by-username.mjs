import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const usersTable = process.env.USERS_TABLE;

export const queryUserByUsernameHandler = async (event) => {
    console.info('received:', event);

    try {
        const username = event.queryStringParameters.username;
        const page = parseInt(event.queryStringParameters.page || "1", 10);
        const lastEvaluatedKey = event.queryStringParameters.lastEvaluatedKey || null;
        const result = await queryUserByUsername(username, page, lastEvaluatedKey);

        return createResponse(200, result);
    } catch (err) {
        console.error('Error querying user by username:', err);
        return createErrorResponse(err);
    }
}

async function queryUserByUsername(username, page, lastEvaluatedKey) {
    const params = {
        TableName: usersTable,
        IndexName: 'UsernameIndex',
        KeyConditionExpression: 'username = :username',
        ExpressionAttributeValues: {
            ':username': username
        },
        Limit: 10,
    };

    if (lastEvaluatedKey) {
        params.ExclusiveStartKey = JSON.parse(lastEvaluatedKey);
    }

    const result = await ddbDocClient.send(new QueryCommand(params));

    if (!result.Items || result.Items.length === 0) {
        throw new Error('No matching user found in the database.');
    }

    console.info(`Page ${page} of users found with username: ${username}`);
    return {
        items: result.Items,
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

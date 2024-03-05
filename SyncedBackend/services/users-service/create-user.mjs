import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const usersTable = process.env.USERS_TABLE;

export const createUserHandler = async (event, context, callback) => {
    console.info('Received Cognito event:', JSON.stringify(event, null, 2));

    const cognitoUserId = event.userName;
    const email = event.request.userAttributes.email;
    const username = event.request.userAttributes['custom:username'] || 'defaultUsername';
    const timestamp = new Date().toISOString();

    try {
        const usernameExists = await checkUsernameExists(username);
        if (usernameExists) {
            console.error('Username already exists:', username);
            callback(new Error('Username already exists'));
            return;
        }

        await addUserToDynamoDB(cognitoUserId, username, email, timestamp);
        console.info('Success - user added:', cognitoUserId);

        // Auto-confirm the user
        event.response.autoConfirmUser = true;
        callback(null, event); 
    } catch (err) {
        console.error('Error performing sign-up actions', err);
        callback(err);
    }
};

async function checkUsernameExists(username) {
    const params = {
        TableName: usersTable,
        IndexName: 'SearchIndex',
        KeyConditionExpression: 'userAttribute = :ua AND attributeValue = :av',
        ExpressionAttributeValues: {
            ':ua': 'username',
            ':av': username,
        },
    };

    const { Items } = await ddbDocClient.send(new QueryCommand(params));
    return Items.length > 0; 
}

async function addUserToDynamoDB(userId, username, email, timestamp) {
    const params = {
        TableName: usersTable,
        Item: {
            userId: userId,
            userAttribute: 'username',
            attributeValue: username,
            email: email,
            createdAt: timestamp,
            updatedAt: timestamp,
        }
    };

    await ddbDocClient.send(new PutCommand(params));
}

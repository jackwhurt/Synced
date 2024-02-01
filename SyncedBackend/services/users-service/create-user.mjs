import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const usersTable = process.env.USERS_TABLE;

export const createUserHandler = async (event) => {
    console.info('Received Cognito event:', JSON.stringify(event, null, 2));

    const cognitoUserId = event.userName;
    const email = event.request.userAttributes.email;
    const username = event.request.userAttributes['custom:username'] || 'defaultUsername';
    const timestamp = new Date().toISOString();

    try {
        await addUserToDynamoDB(cognitoUserId, username, email, timestamp);
        console.info('Success - user added:', cognitoUserId);

        // Auto-confirm the user
        event.response.autoConfirmUser = true;
    } catch (err) {
        console.error('Error performing sign-up actions', err);
        return;
    }

    return event;
};

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
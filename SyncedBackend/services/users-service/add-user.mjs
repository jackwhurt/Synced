import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const tableName = process.env.USERS_TABLE;

export const addUserHandler = async (event) => {
    // This function is triggered by a Cognito event, not an API Gateway event, 
    // so we don't check for `event.httpMethod` here.
    console.info('Received Cognito event:', JSON.stringify(event, null, 2));

    const cognitoUserId = event.request.userAttributes.sub;
    const email = event.request.userAttributes.email;

    const params = {
        TableName: tableName,
        Item: {
            id: cognitoUserId, // Primary Key
            email: email,      // User email
        }
    };

    try {
        const data = await ddbDocClient.send(new PutCommand(params));
        console.log('Success - user added to DynamoDB', data);
    } catch (err) {
        console.error('Error adding user to DynamoDB', err);
        // Handle the error here as necessary
        throw err;
    }

    const response = {
        statusCode: 200,
        body: JSON.stringify({
            userId: cognitoUserId,
            email: email,
        }),
    };

    console.info('Successfully processed Cognito event:', JSON.stringify(event, null, 2));
    
    return response;
};

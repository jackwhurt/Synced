import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand } from '@aws-sdk/lib-dynamodb';

// Create a DocumentClient that represents the query to get items by cognito_user_id
const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

// Get the DynamoDB table name from environment variables
const tableName = process.env.COLLABORATIVE_PLAYLISTS_TABLE;

export const getAllCollaborativePlaylistsHandler = async (event) => {
    if (event.httpMethod !== 'GET') {
        throw new Error(`getAllCollaborativePlaylistsForUserHandler only accepts GET method, you tried: ${event.httpMethod}`);
    }

    // All log statements are written to CloudWatch
    console.info('received:', event);

    // Extract the Cognito User ID from the Lambda event object
    const claims = event.requestContext.authorizer?.claims;
    if (!claims) {
        return {
            statusCode: 401,
            body: JSON.stringify({ message: 'Unauthorized' })
        };
    }

    const cognitoUserId = claims['sub']; // The subject claim contains the Cognito User ID

    var params = {
        TableName: tableName,
        IndexName: 'CognitoUserIdIndex', // Replace with your GSI name
        KeyConditionExpression: 'cognito_user_id = :cognitoUserId',
        ExpressionAttributeValues: {
            ':cognitoUserId': cognitoUserId
        }
    };    

    try {
        const data = await ddbDocClient.send(new QueryCommand(params));
        var items = data.Items;
    } catch (err) {
        console.error("Error", err);
        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Error retrieving items' })
        };
    }

    const response = {
        statusCode: 200,
        body: JSON.stringify(items)
    };

    // All log statements are written to CloudWatch
    console.info(`response from: ${event.path} statusCode: ${response.statusCode} body: ${response.body}`);
    return response;
};

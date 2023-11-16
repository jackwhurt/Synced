import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand, BatchGetCommand } from '@aws-sdk/lib-dynamodb';

// Create a DocumentClient that represents the query to get items by cognito_user_id
const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

// Get the DynamoDB table name from environment variables
const tableName = process.env.PLAYLISTS_TABLE;

export const getAllCollaborativePlaylistsHandler = async (event) => {
    if (event.httpMethod !== 'GET') {
        return {
            statusCode: 405,
            body: { message: `Method Not Allowed, expected GET, received ${event.httpMethod}` }
        };
    }

    console.info('received:', event);

    const claims = event.requestContext.authorizer?.claims;
    if (!claims) {
        return {
            statusCode: 401,
            body: { message: 'Unauthorized' }
        };
    }

    const cognitoUserId = claims['sub'];

    const playlistIdsParams = {
        TableName: tableName,
        IndexName: 'CollaboratorIndex',
        KeyConditionExpression: 'GSI1PK = :gsi1pk',
        ExpressionAttributeValues: {
            ':gsi1pk': `collaborator#${cognitoUserId}`
        }
    };

    try {
        const playlistIdsData = await ddbDocClient.send(new QueryCommand(playlistIdsParams));
        const playlistIds = playlistIdsData.Items.map(item => item.PK);

        // Second query to get playlist metadata
        const playlistMetadataParams = {
            RequestItems: {
                [tableName]: {
                    Keys: playlistIds.map(id => ({ PK: id, SK: 'metadata' })),
                    ConsistentRead: false // Change to true if strong consistency is needed
                }
            }
        };

        const playlistMetadataData = await ddbDocClient.send(new BatchGetCommand(playlistMetadataParams));
        return {
            statusCode: 200,
            body: playlistMetadataData.Responses[tableName]
        };
    } catch (err) {
        console.error("Error", err);
        return {
            statusCode: 500,
            body: { message: 'Error retrieving collaborative playlists' }
        };
    }
};

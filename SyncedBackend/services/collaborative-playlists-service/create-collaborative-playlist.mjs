import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb';

// Create a DocumentClient that represents the query to put an item
const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

// Get the DynamoDB table name from environment variables
const tableName = process.env.COLLABORATIVE_PLAYLISTS_TABLE;

export const handler = async (event) => {
    console.info('received:', event);

    const { cognitoUserId, playlistName, description, collaborators, songs } = JSON.parse(event.body);
    if (!cognitoUserId || !playlistName || !collaborators || !songs) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Missing required fields' }) };
    }

    const timestamp = new Date().toISOString();
    const playlistId = uuidv4();
    const transactItems = [];

    transactItems.push({
        Put: {
            TableName: tableName,
            Item: {
                PK: `cp#${playlistId}`,
                SK: `metadata`,
                cognitoUserId,
                playlistName,
                description,
                playlistId,
                createdAt: timestamp,
                updatedAt: timestamp,
            }
        }
    });

    songs.forEach((song) => {
        const songId = uuidv4();
        transactItems.push({
            Put: {
                TableName: tableName,
                Item: {
                    PK: `cp#${playlistId}`,
                    SK: `song#${songId}`,
                    ...song,
                    createdAt: timestamp,
                    updatedAt: timestamp,
                }
            }
        });
    });

    collaborators.forEach((collaboratorUserId) => {
        transactItems.push({
            Put: {
                TableName: tableName,
                Item: {
                    PK: `cp#${playlistId}`,
                    SK: `collaborator#${collaboratorUserId}`,
                    GSI1PK: `collaborator#${collaboratorUserId}`,
                    addedBy: cognitoUserId,
                    createdAt: timestamp,
                    updatedAt: timestamp,
                }
            }
        });
    });

    try {
        await ddbDocClient.send(new TransactWriteCommand({ TransactItems: transactItems }));
        return {
            statusCode: 200,
            body: JSON.stringify({ playlistId, playlistName, description, collaborators, songs, createdAt: timestamp, updatedAt: timestamp })
        };
    } catch (err) {
        console.error("Error", err);
        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Error creating the collaborative playlist' })
        };
    }
};
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, UpdateCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

export async function updateCollaboratorSyncStatus(playlistId, userId, playlistsTable, syncStatus) {
    const params = {
        TableName: playlistsTable,
        Key: {
            PK: `cp#${playlistId}`,
            SK: `collaborator#${userId}`
        },
        UpdateExpression: 'SET inSync = :inSync',
        ExpressionAttributeValues: {
            ':inSync': syncStatus
        }
    };

    try {
        await ddbDocClient.send(new UpdateCommand(params));
        console.log(`Updated inSync status for collaborator ${userId} in playlist ${playlistId}`);
    } catch (err) {
        console.error('Error updating inSync status:', err);
        throw err;
    }
}
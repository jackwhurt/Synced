import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, UpdateCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

export async function updateCollaboratorSyncStatus(playlistId, userId, syncStatus, service, playlistsTable) {
    const validServices = ['spotify', 'appleMusic'];
    if (!validServices.includes(service)) {
        throw new Error(`Invalid streaming service: ${service}`); 
    }

    const syncAttributeName = `${service}InSync`; 
    const params = {
        TableName: playlistsTable,
        Key: {
            PK: `cp#${playlistId}`,
            SK: `collaborator#${userId}`
        },
        UpdateExpression: `SET #syncAttr = :syncStatus`,
        ExpressionAttributeNames: {
            '#syncAttr': syncAttributeName 
        },
        ExpressionAttributeValues: {
            ':syncStatus': syncStatus 
        }
    };

    try {
        await ddbDocClient.send(new UpdateCommand(params)); 
        console.info(`Updated ${syncAttributeName} status for collaborator ${userId} in playlist ${playlistId}`);
    } catch (err) {
        console.error(`Error updating ${syncAttributeName} status:`, err);
        throw err; 
    }
}

import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

export async function isPlaylistValid(playlistId, playlistsTable) {
    const params = {
        TableName: playlistsTable,
        Key: {
            PK: `cp#${playlistId}`,
            SK: 'metadata'
        }
    };

    try {
        const { Item } = await ddbDocClient.send(new GetCommand(params));
        return Item ? true : false;
    } catch (err) {
        console.error('Error checking playlist existence:', err);
        return false;
    }
}

export async function isCollaboratorInPlaylist(playlistId, userId, playlistsTable) {
    const params = {
        TableName: playlistsTable,
        Key: {
            PK: `cp#${playlistId}`,
            SK: `collaborator#${userId}`
        }
    };

    try {
        const { Item } = await ddbDocClient.send(new GetCommand(params));
        return Item ? true : false;
    } catch (err) {
        console.error('Error checking collaborator in playlist:', err);
        return false;
    }
}

import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);
const playlistsTableName = process.env.PLAYLISTS_TABLE;

export const getCollaborativePlaylistMetadataByIdHandler = async (event) => {
    console.info('received:', event);

    const playlistId = event.pathParameters?.id;
    if (!playlistId) {
        return { statusCode: 400, body: JSON.stringify('No playlist ID provided') };
    }

    try {
        const playlistMetadata = await queryPlaylistItems(playlistId);

        if (!playlistMetadata) {
            return { statusCode: 404, body: JSON.stringify('Playlist not found') };
        }

        return {
            statusCode: 200,
            body: JSON.stringify({ playlistId: playlistId, metadata: playlistMetadata })
        };
    } catch (err) {
        console.error('Error retrieving playlist metadata', err);
        return { statusCode: 500, body: JSON.stringify('Error retrieving playlist metadata') };
    }
}

async function queryPlaylistItems(playlistId) {
    const playlistItemsParams = {
        TableName: playlistsTableName,
        KeyConditionExpression: 'PK = :pk and SK = :sk',
        ExpressionAttributeValues: { 
            ':pk': `cp#${playlistId}`,
            ':sk': 'metadata'
        }
    };
    
    const response = await ddbDocClient.send(new QueryCommand(playlistItemsParams));

    return response.Items ? response.Items[0] : null;
}
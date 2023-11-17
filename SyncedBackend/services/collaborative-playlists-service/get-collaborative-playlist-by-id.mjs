import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand, BatchGetCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);
const playlistsTableName = process.env.PLAYLISTS_TABLE;
const usersTableName = process.env.USERS_TABLE;

export const getCollaborativePlaylistByIdHandler = async (event) => {
    if (!playlistsTableName || !usersTableName) {
        console.error('Environment variables for table names are not set');

        return { statusCode: 500, body: JSON.stringify('Server Configuration Error') };
    }

    if (event.httpMethod !== 'GET') {
        return { statusCode: 405, body: JSON.stringify('Method Not Allowed') };
    }

    const playlistUuid = event.pathParameters?.id;
    if (!playlistUuid) {
        return { statusCode: 400, body: JSON.stringify('No playlist ID provided') };
    }
    const playlistId = 'cp#' + playlistUuid;

    try {
        const playlistItemsData = await queryPlaylistItems(playlistId);
        const { collaborators, playlistMetadata, songs } = await processPlaylistItems(playlistItemsData.Items);

        if (!playlistMetadata && collaborators.length === 0 && songs.length === 0) {
            return { statusCode: 404, body: JSON.stringify('Playlist not found') };
        }

        return {
            statusCode: 200,
            body: JSON.stringify({ playlistId: playlistId, metadata: playlistMetadata, collaborators: collaborators, songs: songs })
        };
    } catch (err) {
        console.error("Error", err);

        return { statusCode: 500, body: JSON.stringify('Error retrieving playlist items') };
    }
};

async function queryPlaylistItems(playlistId) {
    const playlistItemsParams = {
        TableName: playlistsTableName,
        KeyConditionExpression: 'PK = :pk',
        ExpressionAttributeValues: { ':pk': playlistId }
    };

    return ddbDocClient.send(new QueryCommand(playlistItemsParams));
}

async function processPlaylistItems(items) {
    let collaborators = [], playlistMetadata = null, songs = [];
    const userIds = items
        .filter(item => item.SK.startsWith('collaborator#'))
        .map(item => ({ cognito_user_id: item.GSI1PK.split('#')[1] }));
   
    collaborators = await fetchUsersData(userIds);

    for (const item of items) {
        if (item.SK === 'metadata') {
            playlistMetadata = item;
        } else if (item.SK.startsWith('song#')) {
            songs.push(item);
        }
    }

    return { collaborators, playlistMetadata, songs };
}

async function fetchUsersData(userIds) {
    if (userIds.length === 0) {
        return [];
    }

    const batchGetParams = {
        RequestItems: {
            [usersTableName]: {
                Keys: userIds
            }
        }
    };

    try {
        const usersData = await ddbDocClient.send(new BatchGetCommand(batchGetParams));
        
        return usersData.Responses[usersTableName] || [];
    } catch (err) {
        console.error('Error in batch get users:', err);

        return [];
    }
}

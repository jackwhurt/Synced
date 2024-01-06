import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand, BatchGetCommand } from '@aws-sdk/lib-dynamodb';

const ddbDocClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));

export async function getAllPlaylistsMetadata(userId, playlistsTable) {
    let userPlaylists = [], metadataMap = {};
    try {
        userPlaylists = await getUserPlaylists(userId, playlistsTable);
        metadataMap = await getPlaylistsMetadata(userPlaylists, playlistsTable);
    } catch (error) {
        console.error('Failed to retrieve metadata for all playlists by user id', error);
        throw error;
    }

    return { userPlaylists, metadataMap };
}

async function getUserPlaylists(userId, playlistsTable) {
    const queryParams = {
        TableName: playlistsTable,
        IndexName: 'CollaboratorIndex',
        KeyConditionExpression: 'GSI1PK = :gsi1pk',
        ExpressionAttributeValues: {
            ':gsi1pk': `collaborator#${userId}`
        }
    };

    const queryResult = await ddbDocClient.send(new QueryCommand(queryParams));
    return queryResult.Items;
};

async function getPlaylistsMetadata(playlists, playlistsTable) {
    const chunks = chunkArray(playlists, 100); // Split playlists into chunks of 100
    let metadataMap = {};

    for (const chunk of chunks) {
        const keys = chunk.map(playlist => ({ PK: playlist.PK, SK: 'metadata' }));
        const batchGetParams = {
            RequestItems: {
                [playlistsTable]: {
                    Keys: keys
                }
            }
        };

        const batchGetResult = await ddbDocClient.send(new BatchGetCommand(batchGetParams));
        const chunkMetadataMap = batchGetResult.Responses[playlistsTable].reduce((acc, item) => {
            acc[item.PK] = item;
            return acc;
        }, {});

        metadataMap = { ...metadataMap, ...chunkMetadataMap };
    }

    return metadataMap;
};

function chunkArray(array, chunkSize) {
    const chunks = [];
    for (let i = 0; i < array.length; i += chunkSize) {
        chunks.push(array.slice(i, i + chunkSize));
    }
    return chunks;
}
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand, BatchGetCommand } from '@aws-sdk/lib-dynamodb';

const ddbDocClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const playlistsTable = process.env.PLAYLISTS_TABLE;

export const getSongsForAppleMusicHandler = async (event) => {
    console.info('Received:', event);

    const timestamp = event.queryStringParameters?.timestamp || '1970-01-01T00:00:00Z';
    const claims = event.requestContext.authorizer?.claims;
    const userId = claims['sub'];

    try {
        const userPlaylists = await getUserPlaylists(userId);
        const filteredPlaylists = await filterPlaylists(userPlaylists, timestamp);
        const playlistsWithSongs = await getSongsForPlaylists(filteredPlaylists);

        return {
            statusCode: 200,
            body: JSON.stringify(playlistsWithSongs)
        };
    } catch (err) {
        console.error('Error:', err);
        return createErrorResponse(err.message);
    }
};

async function getUserPlaylists(userId) {
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

async function filterPlaylists(playlists, timestamp) {
    const metadataMap = await getPlaylistsMetadata(playlists);
    return playlists.filter(playlist => {
        const metadata = metadataMap[playlist.PK];
        return metadata && metadata.updatedAt > timestamp && playlist.appleMusicPlaylistId;
    });
};

async function getPlaylistsMetadata(playlists) {
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

async function getSongsForPlaylists(playlists) {
    const results = [];

    for (const playlist of playlists) {
        try {
            const queryParams = {
                TableName: playlistsTable,
                KeyConditionExpression: 'PK = :pk and begins_with(SK, :sk)',
                ExpressionAttributeValues: {
                    ':pk': playlist.PK,
                    ':sk': 'song#'
                }
            };

            const queryResult = await ddbDocClient.send(new QueryCommand(queryParams));
            const formattedSongs = queryResult.Items.reduce((acc, song) => {
                if (song.appleMusicId) {
                    acc.push({
                        id: song.appleMusicId,
                        type: 'songs',
                        attributes: {
                            url: song.appleMusicUrl
                        }
                    });
                }
                return acc;
            }, []);

            results.push({
                playlistId: playlist.PK.replace('cp#', ''),
                appleMusicPlaylistId: playlist.appleMusicPlaylistId,
                songs: formattedSongs
            });
        } catch (err) {
            console.error(`Error querying songs for playlist ${playlist.PK}:`, err);
        }
    }

    return results;
};

// Helper functions for creating error and success responses
function createErrorResponse(message) {
    return {
        statusCode: 500,
        body: JSON.stringify({ error: message }),
    };
}

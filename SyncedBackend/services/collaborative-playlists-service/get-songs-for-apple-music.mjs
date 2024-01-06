import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { getAllPlaylistsMetadata } from '/opt/nodejs/get-all-playlists-metadata.mjs';

const ddbDocClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const playlistsTable = process.env.PLAYLISTS_TABLE;

export const getSongsForAppleMusicHandler = async (event) => {
    console.info('Received:', event);

    const timestamp = event.queryStringParameters?.timestamp || '1970-01-01T00:00:00Z';
    const claims = event.requestContext.authorizer?.claims;
    const userId = claims['sub'];

    try {
        const { userPlaylists, metadataMap } = await getAllPlaylistsMetadata(userId, playlistsTable);
        const filteredPlaylists = await filterPlaylists(userPlaylists, metadataMap, timestamp);
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

async function filterPlaylists(playlists, metadataMap, timestamp) {
    return playlists.filter(playlist => {
        const metadata = metadataMap[playlist.PK];
        return metadata && metadata.updatedAt > timestamp && playlist.appleMusicPlaylistId;
    });
};

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

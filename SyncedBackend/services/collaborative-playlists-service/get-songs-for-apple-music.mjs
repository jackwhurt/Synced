import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand } from '@aws-sdk/lib-dynamodb';

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
        const songsInPlaylists = await getSongsForPlaylists(filteredPlaylists);

        return {
            statusCode: 200,
            body: JSON.stringify(songsInPlaylists)
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

function filterPlaylists(playlists, timestamp) {
    return playlists.filter(playlist => playlist.updatedAt > timestamp && playlist.appleMusicId);
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
            results.push({
                playlist: playlist.appleMusicId,
                name: playlist.appleMusicPlaylistName,
                songs: queryResult.Items
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

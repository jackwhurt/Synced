import { getAllPlaylistsMetadata } from '/opt/nodejs/get-all-playlists-metadata.mjs';

// Get the DynamoDB table name from environment variables
const tableName = process.env.PLAYLISTS_TABLE;

export const getAllCollaborativePlaylistsHandler = async (event) => {
    console.info('received:', event);

    const claims = event.requestContext.authorizer?.claims;
    const userId = claims['sub'];

    try {
        const { userPlaylists, metadataMap } = await getAllPlaylistsMetadata(userId, tableName);
        const map = Object.values(metadataMap);

        // Map, transform, and sort the playlists
        const playlists = map.map(playlist => {
            const { PK: id, ...rest } = playlist;
            return { id, ...rest };
        }).sort((a, b) => a.title.localeCompare(b.title));

        return {
            statusCode: 200,
            body: JSON.stringify(playlists)
        };
    } catch (err) {
        console.error('Error', err);
        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Error retrieving collaborative playlists' })
        };
    }
};


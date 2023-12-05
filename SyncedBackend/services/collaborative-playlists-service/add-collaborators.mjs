import { addCollaborators } from '/opt/nodejs/add-collaborators.mjs';
import { isPlaylistValid } from '/opt/nodejs/playlist-validator.mjs';
import { isCollaboratorInPlaylist } from '/opt/nodejs/playlist-validator.mjs';

const playlistsTable = process.env.PLAYLISTS_TABLE;
const usersTable = process.env.USERS_TABLE;

export const addCollaboratorsHandler = async (event) => {
    console.info('received:', event);

    const { playlistId, collaboratorIds } = JSON.parse(event.body);
    const claims = event.requestContext.authorizer?.claims;
    const validationError = validateEvent(playlistId, collaboratorIds, claims['sub']);
    if (validationError) {
		return {
            statusCode: 400,
            body: JSON.stringify({ message: validationError })
        };
    }

    try {
        await addCollaborators(playlistId, collaboratorIds, claims['sub'], playlistsTable, usersTable);

        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Collaborators added successfully',
                playlistId,
                collaboratorIds
            })
        };
    } catch (err) {
        console.error('Error', err);
		return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Error adding collaborators' })
        };
    }
};

async function validateEvent(playlistId, collaboratorIds, userId) {
    if (!playlistId || !collaboratorIds || collaboratorIds.length === 0) {
        return 'Missing required fields';
    }

    if (!userId) return 'Unauthorised';

    if (!await isPlaylistValid(playlistId, playlistsTable, ddbDocClient)) {
        return 'Playlist doesn\'t exist: ' + playlistId;
    }

    if (!await isCollaboratorInPlaylist(playlistId, userId, playlistsTable, ddbDocClient)) {
        return 'Not authorised to edit this playlist';
    }

    return null;
}
import { addCollaborators } from '/opt/nodejs/add-collaborators.mjs';
import { isPlaylistValid } from '/opt/nodejs/playlist-validator.mjs';
import { isCollaboratorInPlaylist } from '/opt/nodejs/playlist-validator.mjs';

const playlistsTable = process.env.PLAYLISTS_TABLE;
const usersTable = process.env.USERS_TABLE;
const activitiesTable = process.env.ACTIVITIES_TABLE

export const addCollaboratorsHandler = async (event) => {
    console.info('received:', event);

    const { playlistId, collaboratorIds } = JSON.parse(event.body);
    const claims = event.requestContext.authorizer?.claims;
    const validationResponse = await validateEvent(playlistId, collaboratorIds, claims['sub']);
    if (validationResponse) return validationResponse;

    try {
        await addCollaborators(playlistId, collaboratorIds, claims['sub'], playlistsTable, activitiesTable, usersTable);

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
        return { statusCode: 400, body: JSON.stringify({ message: 'Missing required fields' }) };
    }

    if (!await isPlaylistValid(playlistId, playlistsTable)) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Playlist doesn\'t exist: ' + playlistId }) };
    }

    if(!await isCollaboratorInPlaylist(playlistId, userId, playlistsTable)) {
        return { statusCode: 403, body: JSON.stringify({ message: 'Not authorised to edit this playlist' }) };
    }
}
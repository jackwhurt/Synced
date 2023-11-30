import { addCollaborators } from '/opt/nodejs/add-collaborators.mjs';

const playlistsTable = process.env.PLAYLISTS_TABLE;
const usersTable = process.env.USERS_TABLE;

export const addCollaboratorsHandler = async (event) => {
    console.info('received:', event);

    const validationError = validateEvent(event);
    if (validationError) {
		return {
            statusCode: 400,
            body: JSON.stringify({ message: validationError })
        };
    }

    const { playlistId, collaboratorIds } = JSON.parse(event.body);
    const claims = event.requestContext.authorizer?.claims;

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

function validateEvent(event) {
    if (!event.body) return 'Missing body';

    const { playlistId, collaboratorIds } = JSON.parse(event.body);
    if (!playlistId || !collaboratorIds || collaboratorIds.length === 0) {
        return 'Missing required fields';
    }

    const claims = event.requestContext.authorizer?.claims;
    if (!claims) return 'Unauthorised';

    return null;
}
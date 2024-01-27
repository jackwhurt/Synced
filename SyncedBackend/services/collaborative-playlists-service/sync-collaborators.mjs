import { getCollaboratorsByPlaylistIdAndCollaboratorIds } from '/opt/nodejs/get-collaborators.mjs';
import { prepareSpotifyAccounts } from '/opt/nodejs/spotify-utils.mjs';
import { syncPlaylists } from '/opt/nodejs/streaming-service/sync-collaborative-playlists.mjs';

const playlistsTable = process.env.PLAYLISTS_TABLE;
const tokensTable = process.env.TOKENS_TABLE;
const usersTable = process.env.USERS_TABLE;

export async function syncCollaboratorsHandler(event) {
    console.info('received: ', event);
    const { playlistId, collaboratorIds } = JSON.parse(event.body);

    try {
        const collaboratorsData = await getCollaboratorsByPlaylistIdAndCollaboratorIds(playlistId, collaboratorIds, playlistsTable);
        if (collaboratorsData.length !== collaboratorIds.length) {
            return buildErrorResponse(400, 'Invalid playlist or collaborator ID(s)');
        }

        const unsuccessfulUpdateUserIds = await prepareAndSyncUsers(playlistId, collaboratorsData, collaboratorIds);
        return buildSuccessResponse(unsuccessfulUpdateUserIds);
    } catch (error) {
        console.error('Error in syncCollaboratorsHandler:', error);
        return buildErrorResponse(500, error.message);
    }
}

async function prepareAndSyncUsers(playlistId, collaboratorsData, collaboratorIds) {
    const { spotifyUsers, failedSpotifyUsers } = await prepareSpotifyAccounts(collaboratorsData.map(c => c.userId), usersTable, tokensTable);
    const spotifyUsersMap = new Map(spotifyUsers.map(user => [user.userId, user]));
    const { failedUsers } = await syncPlaylists(playlistId, spotifyUsersMap, collaboratorsData, playlistsTable);
    
    if (failedUsers.length === collaboratorIds.length) {
        throw new Error('No users were able to be resynced');
    }

    return [...failedSpotifyUsers.map(user => user.userId), ...failedUsers];
}

function buildErrorResponse(statusCode, errorMessage) {
    return {
        statusCode,
        body: JSON.stringify({ message: errorMessage })
    };
}

function buildSuccessResponse(unsuccessfulUpdateUserIds) {
    const message = unsuccessfulUpdateUserIds.length > 0 ? 
        `Success syncing users except for: ${unsuccessfulUpdateUserIds.join(', ')}` : 
        'Success syncing users';

    return {
        statusCode: 200,
        body: JSON.stringify({ message })
    };
}
import { DynamoDBClient, QueryCommand } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb';
import { createPlaylist, deletePlaylist } from '../playlist-management.mjs';
import { addSongs } from '../song-management.mjs';
import { updateCollaboratorSyncStatus } from '/opt/nodejs/utils.mjs';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

export async function syncPlaylists(playlistId, spotifyUsers, playlistsTable) {
    await syncSpotifyPlaylists(playlistId, spotifyUsers, playlistsTable);
}

async function syncSpotifyPlaylists(playlistId, spotifyUsers, playlistsTable) {
    const spotifyCollaborators = await getSpotifyCollaboratorsNotInSync(playlistId);

    for (const collaborator of spotifyCollaborators) {
        const userId = collaborator.userId;
        const oldPlaylistId = collaborator.spotifyPlaylistId;

        try {
            const spotifyUsers = await prepareSpotifyAccounts([userId], usersTable, tokensTable);
            // Create new Spotify playlist and add songs
            const newPlaylistId = await createPlaylist(playlistDetails, spotifyUsers[0]);
            const spotifyUser = spotifyUsers.get(userId);
            // TODO: Get songs from db
            await addSongs(newPlaylistId, spotifyUser, songs);

            // Update the spotifyInSync status to true
            await updateCollaboratorSyncStatus(playlistId, userId, true, 'spotify', playlistsTable);
        } catch (error) {
            console.error(`Error processing collaborator ${userId}:`, error);
            continue;
        }

        // Attempt to delete old Spotify playlist
        try {
            await deletePlaylist(oldPlaylistId, spotifyUsers);
        } catch (error) {
            console.error(`Error deleting Spotify playlist for collaborator ${userId}:`, error);
        }
    }
}


async function getSpotifyCollaboratorsNotInSync(playlistId, playlistsTable) {
    const queryParams = {
        TableName: playlistsTable,
        KeyConditionExpression: 'PK = :pk and begins_with(SK, :sk)',
        FilterExpression: 'spotifyInSync = :syncStatus',
        ExpressionAttributeValues: {
            ':pk': `cp#${playlistId}`,
            ':sk': 'collaborator#',
            ':syncStatus': false
        }
    };

    try {
        const data = await ddbDocClient.send(new QueryCommand(queryParams));
        return data.Items.map(item => ({
            userId: item.SK.split('#')[1],
            playlistDetails: { /* TODO: Extract necessary playlist details here */ },
            spotifyPlaylistId: item.spotifyPlaylistId,
            playlistId: item.PK.split('#')[1]
        }));
    } catch (error) {
        console.error('Error fetching collaborators with false spotifyInSync:', error);
        throw error;
    }
}

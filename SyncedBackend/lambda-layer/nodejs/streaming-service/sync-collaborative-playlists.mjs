import { DynamoDBClient, QueryCommand } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb';
import { deletePlaylist } from '/opt/nodejs/streaming-service/delete-streaming-service-playlist.mjs';
import { createPlaylist } from '/opt/nodejs/streaming-service/create-streaming-service-playlist.mjs';
import { addSongs } from '/opt/nodejs/streaming-service/add-songs.mjs';
import { updateCollaboratorSyncStatus } from '/opt/nodejs/update-collaborator-sync-status.mjs';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

export async function syncPlaylists(playlistId, spotifyUsers, playlistsTable) {
    await syncSpotifyPlaylists(playlistId, spotifyUsers, playlistsTable);
}

async function syncSpotifyPlaylists(playlistId, spotifyUsersMap, playlistsTable) {
    const spotifyCollaborators = await getSpotifyCollaboratorsNotInSync(playlistId);

    for (const collaborator of spotifyCollaborators) {
        const userId = collaborator.userId;
        const oldSpotifyPlaylistId = collaborator.spotifyPlaylistId;

        try {
            // Create new Spotify playlist and add songs
            const spotifyUser = spotifyUsersMap.get(userId);
            const playlistDetails = await getPlaylistMetadata(playlistId, playlistsTable)
            const newSpotifyPlaylistId = await createPlaylist(playlistDetails, spotifyUser);
            const songs = await getSongData(playlistId, playlistsTable)
            await addSongs(newSpotifyPlaylistId, spotifyUser, songs);

            // Update the spotifyInSync status to true
            await updateCollaboratorSyncStatus(playlistId, userId, true, 'spotify', playlistsTable);
        } catch (error) {
            console.error(`Error resyncing collaborator ${userId}:`, error);
            // Continue attempting to delete the rest of the playlists
            continue;
        }

        // Attempt to delete old Spotify playlist
        try {
            await deletePlaylist(oldSpotifyPlaylistId, spotifyUser);
        } catch (error) {
            console.error(`Error deleting Spotify playlist for collaborator ${userId}:`, error);
        }
    }
}

// TODO: Some error here
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
            playlistDetails: { 
                title: item.title,
                description: item.description || ''
             },
            spotifyPlaylistId: item.spotifyPlaylistId,
            playlistId: item.PK.split('#')[1]
        }));
    } catch (error) {
        console.error('Error fetching collaborators with false spotifyInSync:', error);
    }
}

async function getSongData(playlistId, playlistsTable) {
    const queryParams = {
        TableName: playlistsTable,
        KeyConditionExpression: 'PK = :pk and begins_with(SK, :sk)',
        ExpressionAttributeValues: {
            ':pk': `cp#${playlistId}`,
            ':sk': 'song#'
        }
    };

    try {
        const data = await ddbDocClient.send(new QueryCommand(queryParams));
        return data.Items;
    } catch (error) {
        console.error('Error fetching songs for playlist:', error);
        throw error;
    }
}

async function getPlaylistMetadata(playlistId, playlistsTable) {
    const queryParams = {
        TableName: playlistsTable,
        KeyConditionExpression: 'PK = :pk and SK = :sk',
        ExpressionAttributeValues: {
            ':pk': `cp#${playlistId}`,
            ':sk': 'metadata'
        }
    };

    try {
        const data = await ddbDocClient.send(new QueryCommand(queryParams));
        if (data.Items.length > 0) {
            return data.Items[0];
        } else {
            throw new Error('Playlist metadata not found');
        }
    } catch (error) {
        console.error('Error fetching playlist metadata:', error);
        throw error;
    }
}

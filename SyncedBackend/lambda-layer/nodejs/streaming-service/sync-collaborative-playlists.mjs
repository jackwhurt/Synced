import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { deleteSpotifyPlaylist } from '/opt/nodejs/streaming-service/delete-streaming-service-playlist.mjs';
import { createSpotifyPlaylist } from '/opt/nodejs/streaming-service/create-streaming-service-playlist.mjs';
import { addSongsToSpotifyPlaylist } from '/opt/nodejs/streaming-service/add-songs.mjs';
import { updateCollaboratorSyncStatus } from '/opt/nodejs/update-collaborator-sync-status.mjs';
import { deleteSpotifyPlaylist } from './delete-streaming-service-playlist.mjs';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

export async function syncPlaylists(playlistId, spotifyUsers, collaboratorsData, playlistsTable) {
    return await syncSpotifyPlaylists(playlistId, spotifyUsers, collaboratorsData, playlistsTable);
}

async function syncSpotifyPlaylists(playlistId, spotifyUsersMap, collaboratorsData, playlistsTable) {
    const outOfSyncCollaborators = collaboratorsData.filter(collaborator => !collaborator.spotifyInSync);
    const updatedUsers = [];
    const failedUsers = [];

    for (const collaborator of outOfSyncCollaborators) {
        const userId = collaborator.userId;
        const oldSpotifyPlaylistId = collaborator.spotifyPlaylistId;
        const spotifyUser = spotifyUsersMap.get(userId);
        // If user hasn't been prepared for spotify, continue since they won't have a corresponding spotify playlist
        if (!spotifyUser) continue;

        try {
            // Create new Spotify playlist and add songs
            const playlistDetails = await getPlaylistMetadata(playlistId, playlistsTable);
            const newPlaylistIds = await createSpotifyPlaylist(playlistDetails, spotifyUser, playlistsTable);
            const newSpotifyPlaylistId = newPlaylistIds.spotify;
            const songs = await getSongData(playlistId, playlistsTable)
            await addSongsToSpotifyPlaylist(newSpotifyPlaylistId, spotifyUser, songs, playlistsTable);

            // Update the spotifyInSync status to true
            await updateCollaboratorSyncStatus(playlistId, userId, true, 'spotify', playlistsTable);
            await deleteSpotifyPlaylist(oldSpotifyPlaylistId, spotifyUser);
            updatedUsers.push(userId);
            console.info(`Successful resync for collaborator ${userId}`);
        } catch (error) {
            failedUsers.push(userId);
            console.error(`Error resyncing collaborator ${userId}:`, error);
        }
    }

    return { updatedUsers, failedUsers };
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
            return {
                playlistId: data.Items[0].PK.split('#')[1],
                description: data.Items[0].description,
                title: data.Items[0].title,
            };
        } else {
            throw new Error('Playlist metadata not found');
        }
    } catch (error) {
        console.error('Error fetching playlist metadata:', error);
        throw error;
    }
}

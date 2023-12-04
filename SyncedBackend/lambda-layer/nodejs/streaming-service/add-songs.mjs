import axios from 'axios';
import { updateCollaboratorSyncStatus } from '/opt/nodejs/update-collaborator-sync-status.mjs';

export async function addSongs(playlistId, spotifyUser, songs, playlistsTable) {
    await addSongsToSpotifyPlaylist(playlistId, spotifyUser, songs, playlistsTable);
}

// TODO: Pagination to handle 100 limit on queries
async function addSongsToSpotifyPlaylist(playlistId, spotifyUser, songs, playlistsTable, maxRetries = 3) {
    const url = `https://api.spotify.com/v1/playlists/${playlistId}/tracks`;
    const headers = {
        'Authorization': `Bearer ${spotifyUser.token}`,
        'Content-Type': 'application/json'
    };

    const songUris = songs.map(song => song.spotifyUri);
    const data = { uris: songUris };

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            await axios.post(url, data, { headers });
            console.info('Songs added to Spotify playlist successfully for user: ', spotifyUser.userId);
            return; // Success, exit the function
        } catch (error) {
            console.error(`Attempt ${attempt} failed: Error adding songs to Spotify playlist for user ${spotifyUser.userId}:`, error);
            if (attempt < maxRetries) {
                await new Promise(resolve => setTimeout(resolve, 1000 * attempt)); // Exponential back-off
            } else {
                updateCollaboratorSyncStatus(playlistId, spotifyUser.userId, false, 'spotify', playlistsTable);
                throw error; // All attempts failed, throw the error
            }
        }
    }
}

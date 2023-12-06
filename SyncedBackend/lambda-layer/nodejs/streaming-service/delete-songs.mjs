import axios from 'axios';
import { updateCollaboratorSyncStatus } from '/opt/nodejs/update-collaborator-sync-status.mjs';

export async function deleteSongsFromSpotifyPlaylist(playlistId, spotifyUser, songs, playlistsTable, maxRetries = 3) {
    const url = `https://api.spotify.com/v1/playlists/${playlistId}/tracks`;
    const headers = {
        'Authorization': `Bearer ${spotifyUser.token}`,
        'Content-Type': 'application/json'
    };

    // Function to split the songs array into chunks of 100
    const chunkSize = 100;
    for (let i = 0; i < songs.length; i += chunkSize) {
        const songChunk = songs.slice(i, i + chunkSize);
        const songUris = songChunk.map(song => song.spotifyUri);
        const data = { uris: songUris };

        for (let attempt = 1; attempt <= maxRetries; attempt++) {
            try {
                await axios.delete(url, { headers, data });
                console.info('Songs deleted from Spotify playlist successfully for user: ', spotifyUser.userId);
                break; // Break out of the retry loop on success
            } catch (error) {
                console.error(`Attempt ${attempt} failed: Error deleting songs from Spotify playlist for user ${spotifyUser.userId}:`, error);
                if (attempt === maxRetries) {
                    await updateCollaboratorSyncStatus(playlistId, spotifyUser.userId, false, 'spotify', playlistsTable);
                    throw error; // All attempts failed, throw the error
                }
                await new Promise(resolve => setTimeout(resolve, 1000 * attempt)); // Exponential back-off
            }
        }
    }
}

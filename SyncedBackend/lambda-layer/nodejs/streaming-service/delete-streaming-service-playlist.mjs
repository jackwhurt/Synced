import axios from 'axios';

export async function deleteSpotifyPlaylist(playlistId, spotifyUser, maxRetries = 3) {
    const url = `https://api.spotify.com/v1/playlists/${playlistId}/followers`;
    const headers = {
        'Authorization': `Bearer ${spotifyUser.token}`,
        'Content-Type': 'application/json'
    };

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            await axios.delete(url, { headers });
            console.info('Spotify playlist deleted successfully.');
            return;
        } catch (error) {
            console.error(`Attempt ${attempt} failed to delete Spotify playlist:`, error);
            if (attempt < maxRetries) {
                await new Promise(resolve => setTimeout(resolve, 1000 * attempt)); // Exponential backoff
            } else {
                throw error; // All attempts failed, rethrow the error
            }
        }
    }
}

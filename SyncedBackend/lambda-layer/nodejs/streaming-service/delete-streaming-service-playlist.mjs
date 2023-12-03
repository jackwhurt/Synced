import axios from 'axios';

async function deleteSpotifyPlaylist(playlistId, spotifyUser) {
    try {
        const url = `https://api.spotify.com/v1/playlists/${playlistId}/followers`;
        const headers = {
            'Authorization': `Bearer ${spotifyUser.token}`,
            'Content-Type': 'application/json'
        };

        await axios.delete(url, { headers });
    } catch (error) {
        console.error('Error deleting Spotify playlist:', error);
        throw error;
    }
}

export async function deletePlaylist(spotifyPlaylistId, userId, usersTable, tokensTable) {
    await deleteSpotifyPlaylist(spotifyPlaylistId, userId, usersTable, tokensTable);
}

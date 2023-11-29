import { prepareSpotifyAccounts } from './spotify-utils.mjs';
import axios from 'axios';

async function deleteSpotifyPlaylist(playlistId, userId, usersTable, tokensTable) {
    try {
        const spotifyUsers = await prepareSpotifyAccounts([userId], usersTable, tokensTable);
        
        if (spotifyUsers.length === 0) {
            throw new Error('No Spotify user found for the given user ID.');
        }

        const spotifyUser = spotifyUsers[0];
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

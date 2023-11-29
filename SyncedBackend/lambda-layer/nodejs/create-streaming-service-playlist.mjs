import { prepareSpotifyAccounts } from './spotify-utils.mjs';
import axios from 'axios';

async function createSpotifyPlaylist(playlistDetails, userId, usersTable, tokensTable) {
    const data = {
        name: playlistDetails.title,
        description: playlistDetails.description || '',
        public: false
    };

    try {
        const spotifyUsers = await prepareSpotifyAccounts([userId], usersTable, tokensTable);

        if (spotifyUsers.length === 0) {
            throw new Error('No Spotify user found for the given user ID.');
        }

        const spotifyUser = spotifyUsers[0];
        const url = `https://api.spotify.com/v1/users/${spotifyUser.spotifyUserId}/playlists`;
        const headers = {
            'Authorization': `Bearer ${spotifyUser.token}`,
            'Content-Type': 'application/json'
        };

        const response = await axios.post(url, data, { headers });
        return {
            userId: spotifyUser.userId,
            spotifyUserId: spotifyUser.spotifyUserId,
            playlistId: response.data.id,
            token: spotifyUser.token
        };
    } catch (error) {
        console.error('Error creating Spotify playlist:', error);
        throw error;
    }
}

export async function createPlaylist(playlistDetails, userId, usersTable, tokensTable) {
    return { spotify: await createSpotifyPlaylist(playlistDetails, userId, usersTable, tokensTable) };
}


import axios from 'axios';

async function createSpotifyPlaylist(playlistDetails, spotifyUser) {
    const data = {
        name: playlistDetails.title,
        description: playlistDetails.description || '',
        public: false
    };

    try {
        const url = `https://api.spotify.com/v1/users/${spotifyUser.spotifyUserId}/playlists`;
        const headers = {
            'Authorization': `Bearer ${spotifyUser.token}`,
            'Content-Type': 'application/json'
        };

        const response = await axios.post(url, data, { headers });
        return response.data.id;
    } catch (error) {
        console.error('Error creating Spotify playlist:', error);
        throw error;
    }
}

export async function createPlaylist(playlistDetails, spotifyUser) {
    return { spotify: await createSpotifyPlaylist(playlistDetails, spotifyUser) };
}

// TODO: Function that updates spotify playlist id in db
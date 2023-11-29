import { prepareSpotifyAccounts } from './spotify-utils.mjs';
import axios from 'axios';

async function addSongsToSpotify(playlistId, userId, songs, usersTable, tokensTable) {
    try {
        const spotifyUsers = await prepareSpotifyAccounts([userId], usersTable, tokensTable);

        if (spotifyUsers.length === 0) {
            throw new Error('No Spotify user found for the given user ID.');
        }

        const spotifyUser = spotifyUsers[0];
        const url = `https://api.spotify.com/v1/playlists/${playlistId}/tracks`;
        const headers = {
            'Authorization': `Bearer ${spotifyUser.token}`,
            'Content-Type': 'application/json'
        };

        const songUris = songs.map(song => song.spotifyUri);

        const data = {
            uris: songUris
        };

        await axios.post(url, data, { headers });
        console.log('Songs added to playlist successfully.');
    } catch (error) {
        console.error('Error adding songs to Spotify playlist:', error);
        throw error;
    }
}

export async function addSongs(playlistId, userId, songs, usersTable, tokensTable) {
    return await addSongsToSpotify(playlistId, userId, songs, usersTable, tokensTable);
}

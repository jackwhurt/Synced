import axios from 'axios';
import { updateCollaboratorSyncStatus } from '/opt/nodejs/update-collaborator-sync-status.mjs';

export async function addSongs(playlistId, spotifyUser, songs) {
    addSongsToSpotifyPlaylist(playlistId, spotifyUser, songs);
}

async function addSongsToSpotifyPlaylist(playlistId, spotifyUser, songs) {
    try {
        const url = `https://api.spotify.com/v1/playlists/${playlistId}/tracks`;
        const headers = {
            'Authorization': `Bearer ${spotifyUser.token}`,
            'Content-Type': 'application/json'
        };

        const songUris = songs.map(song => song.spotifyUri);
        const data = { uris: songUris };

        await axios.post(url, data, { headers });
        console.info('Songs added to Spotify playlist successfully.');
    } catch (error) {
        updateCollaboratorSyncStatus(playlistId, spotifyUser.userId, false, 'spotify', playlistsTable);
        console.error(`Error adding songs to Spotify playlist for user ${spotifyUser.userId}:`, error);
    }
}
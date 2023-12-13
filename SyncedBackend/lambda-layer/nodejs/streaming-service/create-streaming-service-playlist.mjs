import axios from 'axios';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import { deleteSpotifyPlaylist } from '/opt/nodejs/streaming-service/delete-streaming-service-playlist.mjs';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

async function addPlaylistToSpotify(playlistDetails, spotifyUser, maxRetries = 3) {
    const url = `https://api.spotify.com/v1/users/${spotifyUser.spotifyUserId}/playlists`;
    const headers = {
        'Authorization': `Bearer ${spotifyUser.token}`,
        'Content-Type': 'application/json'
    };

    const data = {
        name: playlistDetails.title,
        description: playlistDetails.description || '',
        public: false
    };

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            const response = await axios.post(url, data, { headers });
            console.info('Spotify playlist created successfully for: ', spotifyUser.userId);
            return response.data.id;
        } catch (error) {
            console.error(`Attempt ${attempt} failed to create Spotify playlist:`, error);
            if (attempt < maxRetries) {
                await new Promise(resolve => setTimeout(resolve, 1000 * attempt)); // Exponential backoff
            } else {
                throw error; // All attempts failed, rethrow the error
            }
        }
    }
}

async function addPlaylistToAppleMusic(playlistDetails, appleMusicUser, maxRetries = 3) {
    const url = `https://api.music.apple.com/v1/me/library/playlists`;
    const headers = {
        'Authorization': `Bearer ${appleMusicUser.devToken}`,
        'Music-User-Token': appleMusicUser.token,
        'Content-Type': 'application/json'
    };

    const data = {
        attributes: {
            name: playlistDetails.title,
            description: playlistDetails.description || ''
        }
    };

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            const response = await axios.post(url, data, { headers });
            console.info('Apple Music playlist created successfully for: ', appleMusicUser.userId);
            return response.data.data[0].id;
        } catch (error) {
            console.error(`Attempt ${attempt} failed to create Apple Music playlist:`, error);
            if (attempt < maxRetries) {
                await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
            } else {
                throw error;
            }
        }
    }
}

async function updatePlaylistId(playlistDetails, playlistId, userId, playlistsTable, platform) {
    const attributeName = platform === 'spotify' ? 'spotifyPlaylistId' : 'appleMusicPlaylistId';
    const params = {
        TableName: playlistsTable,
        Key: {
            PK: `cp#${playlistDetails.playlistId}`,
            SK: `collaborator#${userId}`
        },
        UpdateExpression: `SET ${attributeName} = :playlistId`,
        ExpressionAttributeValues: {
            ':playlistId': playlistId,
        },
        ReturnValues: 'UPDATED_NEW'
    };

    try {
        const result = await ddbDocClient.send(new UpdateCommand(params));
        console.info(`${platform} Playlist ID updated successfully for user:`, userId);
        return result;
    } catch (error) {
        console.error(`Error updating ${platform} Playlist ID:`, error);
        throw error;
    }
}

export async function createSpotifyPlaylist(playlistDetails, spotifyUser, playlistsTable) {
    const spotifyPlaylistId = await addPlaylistToSpotify(playlistDetails, spotifyUser);

    try {
        await updatePlaylistId(playlistDetails, spotifyPlaylistId, spotifyUser.userId, playlistsTable, 'spotify');
    } catch (error) {
        console.error('Error updating Spotify playlist ID: ', error);
        deleteSpotifyPlaylist(spotifyUser, spotifyPlaylistId);
        throw error;
    }

    return spotifyPlaylistId;
}

export async function createAppleMusicPlaylist(playlistDetails, appleMusicUser, playlistsTable) {
    const appleMusicPlaylistId = await addPlaylistToAppleMusic(playlistDetails, appleMusicUser);

    try {
        await updatePlaylistId(playlistDetails, appleMusicPlaylistId, appleMusicUser.userId, playlistsTable, 'appleMusic');
    } catch (error) {
        console.error('Error updating Apple Music playlist ID: ', error);
        // TODO: Implement
        // deleteAppleMusicPlaylist(appleMusicUser, appleMusicPlaylistId);
        throw error;
    }

    return appleMusicPlaylistId;
}
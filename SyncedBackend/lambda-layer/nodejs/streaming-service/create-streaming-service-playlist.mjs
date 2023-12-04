import axios from 'axios';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, UpdateCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

async function createSpotifyPlaylist(playlistDetails, spotifyUser, maxRetries = 3) {
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

async function updateSpotifyPlaylistId(playlistDetails, spotifyPlaylistId, userId, playlistsTable) {
    const params = {
        TableName: playlistsTable,
        Key: {
            PK: `cp#${playlistDetails.playlistId}`,
            SK: `collaborator#${userId}`
        },
        UpdateExpression: 'SET spotifyPlaylistId = :spotifyPlaylistId',
        ExpressionAttributeValues: {
            ':spotifyPlaylistId': spotifyPlaylistId,
        },
        ReturnValues: 'UPDATED_NEW'
    };

    try {
        const result = await ddbDocClient.send(new UpdateCommand(params));
        console.info('Spotify Playlist ID updated successfully for user:', userId);
        return result;
    } catch (error) {
        console.error('Error updating Spotify Playlist ID:', error);
        throw error;
    }
}

export async function createPlaylist(playlistDetails, spotifyUser, playlistsTable) {
    const spotifyPlaylistId = await createSpotifyPlaylist(playlistDetails, spotifyUser);
    await updateSpotifyPlaylistId(playlistDetails, spotifyPlaylistId, spotifyUser.userId, playlistsTable);

    return { spotify: spotifyPlaylistId };
}
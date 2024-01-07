import axios from 'axios';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const tokensTable = process.env.TOKENS_TABLE;

export const spotifySongsToAppleMusicHandler = async (event) => {
    console.info('received:', event);

    try {
        // Parse Spotify track list from event body
        const spotifyTracks = JSON.parse(event.body);

        // Get Apple Music token
        const appleMusicToken = await getAppleMusicAccessToken();

        // Search for corresponding tracks on Apple Music
        const appleMusicTracks = await searchForAppleMusicTracks(spotifyTracks, appleMusicToken);
        console.info('returned:', appleMusicTracks)

        return createResponse(200, appleMusicTracks);
    } catch (err) {
        console.error('Error processing music tracks:', err);
        return createErrorResponse(err);
    }
};

async function searchForAppleMusicTracks(spotifyTracks, appleMusicToken) {
    const appleMusicTracks = [];
    for (const track of spotifyTracks) {
        try {
            const results = await searchAppleMusicTrack(track.artist, track.title, track.album, appleMusicToken);
            const modifiedResults = results.map(result => ({ ...result, spotifyUri: track.spotifyUri }));
            appleMusicTracks.push(...modifiedResults);
        } catch (error) {
            console.error('Error searching for a track on Apple Music:', error);
            // TODO: Handle individual track search error
        }
    }
    return appleMusicTracks;
}

async function searchAppleMusicTrack(artist, track, album, appleMusicToken) {
    const baseUrl = 'https://api.music.apple.com/v1/catalog/GB/search';
    const query = `${track} ${album} ${artist}`;

    const config = {
        method: 'get',
        url: `${baseUrl}?term=${encodeURIComponent(query)}&types=songs`,
        headers: {
            'Authorization': `Bearer ${appleMusicToken}`,
        }
    };

    try {
        const response = await axios(config);
        if (response.data && response.data.results && response.data.results.songs) {
            const formattedResponse = response.data.results.songs.data.map(item => ({
                title: item.attributes.name,
                artist: item.attributes.artistName,
                album: item.attributes.albumName,
                appleMusicId: item.id,
                appleMusicUrl: item.href
            }));

            return formattedResponse; 
        } else {
            return []; 
        }
    } catch (error) {
        console.error('Error searching Apple Music:', error);
        throw error;
    }
}

async function getAppleMusicAccessToken() {
    const params = {
        TableName: tokensTable,
        Key: { 'token_id': 'appleMusicDev' },
    };

    try {
        const result = await ddbDocClient.send(new GetCommand(params));
        if (result.Item && result.Item.accessToken) {
            return result.Item.accessToken;
        } else {
            throw new Error('Apple Music access token not found in the database.');
        }
    } catch (error) {
        console.error('Error getting Apple Music access token:', error);
        throw error;
    }
}

function createResponse(statusCode, body) {
    return {
        statusCode,
        body: JSON.stringify(body),
    };
}

function createErrorResponse(error) {
    return {
        statusCode: 500,
        body: JSON.stringify({ error: error.message || 'Internal server error' }),
    };
}

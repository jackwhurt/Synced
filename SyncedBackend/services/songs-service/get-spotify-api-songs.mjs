import axios from 'axios';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const tokensTable = process.env.TOKENS_TABLE;

export const getSpotifyApiSongsHandler = async (event) => {
    console.info('received:', event);

    try {
        const searchQuery = event.queryStringParameters.searchQuery;
        const page = event.queryStringParameters.page || 0;
        const limit = event.queryStringParameters.limit || 20;
        const spotifyToken = await getSpotifyAccessToken();
        const result = await querySpotifySongs(spotifyToken, searchQuery, page, limit);
        console.info('returned:', result)

        return createResponse(200, result);
    } catch (err) {
        console.error('Error querying Spotify songs:', err);
        return createErrorResponse(err);
    }
};

async function querySpotifySongs(token, searchQuery, page, limit) {
    const config = {
        method: 'get',
        url: `https://api.spotify.com/v1/search?q=${encodeURIComponent(searchQuery)}&type=track&page=${page}&limit=${limit}&market=GB`,
        headers: {
            'Authorization': `Bearer ${token}`
        }
    };

    try {
        const response = await axios(config);
        const formattedItems = response.data.tracks.items.map(item => ({
            title: item.name,
            artist: item.artists.map(artist => artist.name).join(', '),
            album: item.album.name,
            spotifyUri: item.uri,
            coverImageUrl: item.album.images && item.album.images.length != 0 ? item.album.images[item.album.images.length - 1].url : ''
        }));
        return {
            items: formattedItems,
            total: response.data.tracks.total,
            limit: response.data.tracks.limit,
            page: response.data.tracks.page,
            next: response.data.tracks.next,
            previous: response.data.tracks.previous
        };
    } catch (error) {
        console.error('Error querying Spotify songs:', error);
        throw error;
    }
}

async function getSpotifyAccessToken() {
    const params = {
        TableName: tokensTable,
        Key: { 'token_id': 'spotifyDev' },
    };

    try {
        const result = await ddbDocClient.send(new GetCommand(params));
        if (result.Item && result.Item.accessToken) {
            return result.Item.accessToken;
        } else {
            throw new Error('Spotify access token not found in the database.');
        }
    } catch (error) {
        console.error('Error getting Spotify access token:', error);
        throw error;
    }
}

function createResponse(statusCode, body) {
    return {
        statusCode,
        body: JSON.stringify(body)
    };
}

function createErrorResponse(err) {
    return {
        statusCode: err.statusCode || 500,
        body: JSON.stringify({ error: err.message })
    };
}

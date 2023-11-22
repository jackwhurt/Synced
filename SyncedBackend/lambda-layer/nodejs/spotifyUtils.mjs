import { SSMClient, GetParameterCommand } from '@aws-sdk/client-ssm';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb';
import axios from 'axios';

const ssmClient = new SSMClient({});
const dynamoDBClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));

// Function to check if the token is still valid or about to expire
function isTokenValid(expiresAt) {
    const now = new Date();
    const expiresAtDate = new Date(expiresAt);
    const bufferTime = 300 * 1000;

    return now < new Date(expiresAtDate.getTime() - bufferTime);
}

// Function to get current token info from DynamoDB
async function getCurrentTokenInfo(key, tableName) {
    const params = {
        TableName: tableName,
        Key: key
    };

    try {
        const data = await dynamoDBClient.get(params);

        return {
            currentToken: data.Item.access_token,
            refreshToken: data.Item.refresh_token,
            expiresAt: data.Item.expires_at
        };
    } catch (error) {
        console.error('Error getting token info from table:', error);
        throw error;
    }
}

// Function to update the new token info in DynamoDB
async function updateTokenInfo(newTokenData, key, tableName) {
    const params = {
        TableName: tableName,
        Key: key,
        UpdateExpression: 'set accessToken = :t, expiresAt = :e',
        ExpressionAttributeValues: {
            ':t': newTokenData.token,
            ':e': new Date().getTime() + (newTokenData.expiresIn * 1000)
        }
    };

    try {
        await dynamoDBClient.update(params);
    } catch (error) {
        console.error('Error updating token info:', error);
        throw error;
    }
}

// Function to refresh Spotify token
async function refreshSpotifyToken(refreshToken) {
    const clientId = await getParameter('spotifyClientId');
    const clientSecret = await getParameter('spotifyClientSecret');
    const auth = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');
    const postData = new URLSearchParams({ grant_type: 'refresh_token', refresh_token: refreshToken });

    const config = {
        method: 'post',
        url: 'https://accounts.spotify.com/api/token',
        headers: {
            'Authorization': `Basic ${auth}`,
            'Content-Type': 'application/x-www-form-urlencoded'
        },
        data: postData
    };

    try {
        const response = await axios(config);
        return { token: response.data.access_token, expiresIn: response.data.expires_in };
    } catch (error) {
        console.error('Error refreshing Spotify token:', error);
        return { error: 'Failed to refresh Spotify token' };
    }
}

async function getParameter(name) {
    try {
        const parameter = await ssmClient.send(new GetParameterCommand({ Name: name, WithDecryption: true }));
        
        return parameter.Parameter.Value;
    } catch (error) {
        console.error(`Error getting parameter ${name}:`, error);
        throw error;
    }
}

// Main function to handle token validation and refresh
export async function handleTokenRefresh(userId, tableName) {
    try {
        const key = { token_id: `spotify#${userId}` };
        const { currentToken, refreshToken, expiresAt } = await getCurrentTokenInfo(key, tableName);

        if (isTokenValid(expiresAt)) {
            return { token: currentToken };
        } else {
            const response = await refreshSpotifyToken(refreshToken);
            if (response.token) {
                await updateTokenInfo(response, key, tableName);

                return { token: response.token };
            } else {
                return { error: response.error };
            }
        }
    } catch (error) {
        console.error('Error during token refresh process:', error);

        return { error: 'Error during token handling' };
    }
}

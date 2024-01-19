import { SSMClient, GetParameterCommand } from '@aws-sdk/client-ssm';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand, UpdateCommand } from '@aws-sdk/lib-dynamodb';
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
async function getCurrentTokenInfo(tokenKey, tableName) {
    const params = {
        TableName: tableName,
        Key: tokenKey
    };

    try {
        const data = await dynamoDBClient.send(new GetCommand(params));

        return {
            currentToken: data.Item.accessToken,
            refreshToken: data.Item.refreshToken,
            expiresAt: data.Item.expiresAt
        };
    } catch (error) {
        console.error('Error getting token info from table:', error);
        throw error;
    }
}

// Function to update the new token info in DynamoDB
async function updateTokenInfo(newToken, expiresIn, tokenKey, tableName) {
    const params = {
        TableName: tableName,
        Key: tokenKey,
        UpdateExpression: 'set accessToken = :t, expiresAt = :e',
        ExpressionAttributeValues: {
            ':t': newToken,
            ':e': new Date().getTime() + (expiresIn * 1000)
        }
    };

    try {
        await dynamoDBClient.send(new UpdateCommand(params));
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

        throw error;
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

async function getSpotifyUserId(userId, usersTable) {
    const params = {
        TableName: usersTable,
        Key: {
            userId: userId
        }
    };

    try {
        const data = await dynamoDBClient.send(new GetCommand(params));
        if (data.Item && data.Item.spotifyUserId) {
            return data.Item.spotifyUserId;
        } else {
            throw new Error(`Spotify user ID not found for user ID: ${userId}`);
        }
    } catch (error) {
        throw error;
    }
}

async function handleTokenRefresh(userId, tokensTable) {
    try {
        const tokenKey = { token_id: `spotify#${userId}` };
        const { currentToken, refreshToken, expiresAt } = await getCurrentTokenInfo(tokenKey, tokensTable);

        if (isTokenValid(expiresAt)) {
            return currentToken;
        } else {
            const response = await refreshSpotifyToken(refreshToken);
            if (response.token) {
                await updateTokenInfo(response.token, response.expiresIn, tokenKey, tokensTable);
                return response.token;
            } else {
                throw new Error(`Failed to retrieve Spotify token for user ID ${userId}`);
            }
        }
    } catch (error) {
        console.error(`Error during token refresh process for user ID ${userId}`);
        throw error;
    }
}

export async function prepareSpotifyAccounts(userIds, usersTable, tokensTable) {
    const spotifyUsers = [];
    const failedSpotifyUsers = [];

    for (const userId of userIds) {
        try {
            const spotifyUserId = await getSpotifyUserId(userId, usersTable);
            const token = await handleTokenRefresh(userId, tokensTable);

            spotifyUsers.push({
                userId,
                spotifyUserId,
                token
            });
        } catch (error) {
            console.error(`Error preparing Spotify account for user ID ${userId}:`, error);
            failedSpotifyUsers.push({ userId, error: error.message });
        }
    }

    return { spotifyUsers, failedSpotifyUsers };
}

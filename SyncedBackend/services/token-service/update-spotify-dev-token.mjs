const AWS = require('aws-sdk');
const axios = require('axios');
const ssm = new AWS.SSM();
const dynamoDB = new AWS.DynamoDB.DocumentClient();

const tokensTable = process.env.TOKENS_TABLE;

export const updateSpotifyDevTokenHandler = async (event) => {
    try {
        // Retrieve Client ID and Client Secret from Parameter Store
        const clientId = await getParameter('spotifyClientId');
        const clientSecret = await getParameter('spotifyClientSecret');

        // Retrieve Refresh Token from DynamoDB
        const refreshTokenData = await dynamoDB.get({
            TableName: tokensTable,
            Key: { PK: 'SpotifyDev' }
        }).promise();
        const refreshToken = refreshTokenData.Item.refreshToken;

        // Prepare the request for token refresh
        const tokenRefreshUrl = 'https://accounts.spotify.com/api/token';
        const authHeader = 'Basic ' + Buffer.from(`${clientId}:${clientSecret}`).toString('base64');
        const body = new URLSearchParams();
        body.append('grant_type', 'refresh_token');
        body.append('refresh_token', refreshToken);

        // Make the request to Spotify
        const response = await axios.post(tokenRefreshUrl, body, {
            headers: { 
                'Content-Type': 'application/x-www-form-urlencoded',
                'Authorization': authHeader
            }
        });

        const newAccessToken = response.data.access_token;
        const expiresIn = response.data.expires_in;
        const newRefreshToken = response.data.refresh_token;

        await updateAccessToken(tokensTable, 'SpotifyDev', newAccessToken, expiresIn, newRefreshToken);

        return { statusCode: 200, body: JSON.stringify({ message: 'Token refreshed successfully' }) };
    } catch (apiError) {
        console.error('Error refreshing token:', apiError);

        return { statusCode: 500, body: JSON.stringify({ message: 'Failed to refresh token' }) };
    }
};

async function getParameter(name) {
    const parameter = await ssm.getParameter({ Name: name, WithDecryption: true }).promise();

    return parameter.Parameter.Value;
}

async function updateAccessToken(tableName, primaryKeyValue, accessToken, expiresIn, newRefreshToken = null) {
    const updateExpression = newRefreshToken ? 
        'set AccessToken = :a, ExpiresAt = :e, RefreshToken = :r' : 
        'set AccessToken = :a, ExpiresAt = :e';
    
    const expressionAttributeValues = newRefreshToken ? 
        { ':a': accessToken, ':e': new Date().getTime() + expiresIn * 1000, ':r': newRefreshToken } : 
        { ':a': accessToken, ':e': new Date().getTime() + expiresIn * 1000 };

    const updateParams = {
        TableName: tableName,
        Key: { token_id: primaryKeyValue },
        UpdateExpression: updateExpression,
        ExpressionAttributeValues: expressionAttributeValues,
        ReturnValues: 'UPDATED_NEW'
    };

    await dynamoDB.update(updateParams).promise();
}

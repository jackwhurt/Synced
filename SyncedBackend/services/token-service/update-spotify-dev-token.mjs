import { SSMClient, GetParameterCommand } from '@aws-sdk/client-ssm';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import axios from 'axios';

const ssmClient = new SSMClient({});
const dynamoDBClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const snsClient = new SNSClient({});

const tokensTable = process.env.TOKENS_TABLE;
const snsTopic = process.env.LAMBDA_FAILURE_TOPIC;
const MAX_RETRIES = 3;

export const updateSpotifyDevTokenHandler = async (event) => {
	let retryCount = 0;

	while (retryCount < MAX_RETRIES) {
		try {
			// Retrieve Client ID and Client Secret from Parameter Store
			const clientId = await getParameter('spotifyClientId');
			const clientSecret = await getParameter('spotifyClientSecret');

			// Retrieve Refresh Token from DynamoDB
			const refreshTokenData = await dynamoDBClient.send(new GetCommand({
				TableName: tokensTable,
				Key: { token_id: 'SpotifyDev' }
			}));
			const refreshToken = refreshTokenData.Item.refresh_token;

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
			const newRefreshToken = response.data.refresh_token || refreshToken;

			// Update the access token (and refresh token, if new one is provided) in DynamoDB
			await updateAccessToken(tokensTable, 'SpotifyDev', newAccessToken, expiresIn, newRefreshToken);

			return { statusCode: 200, body: JSON.stringify({ message: 'Token refreshed successfully' }) };
		} catch (apiError) {
			console.error('Attempt', retryCount + 1, 'failed:', apiError);
			retryCount++;

			if (retryCount >= MAX_RETRIES) {
				// Handle the case where all retries have failed
				console.error('All attempts failed.');
				// Send alert
				await snsClient.publish({
					Message: 'Update Spotify Dev Token function failed after max retries',
					TopicArn: snsTopic
				}).promise();
				return { statusCode: 500, body: JSON.stringify({ message: 'Failed to refresh token after retries' }) };
			}
		}
	}
};

async function getParameter(name) {
	const parameter = await ssmClient.send(new GetParameterCommand({ Name: name, WithDecryption: true }));

	return parameter.Parameter.Value;
}

async function updateAccessToken(tableName, primaryKeyValue, accessToken, expiresIn, newRefreshToken = null) {
	const updateExpression = 'set access_token = :a, ExpiresAt = :e' + (newRefreshToken ? ', refresh_token = :r' : '');

	const expressionAttributeValues = {
		':a': accessToken,
		':e': new Date().getTime() + expiresIn * 1000
	};
	if (newRefreshToken) {
		expressionAttributeValues[':r'] = newRefreshToken;
	}

	const updateParams = {
		TableName: tableName,
		Key: { token_id: primaryKeyValue },
		UpdateExpression: updateExpression,
		ExpressionAttributeValues: expressionAttributeValues
	};

	await dynamoDBClient.send(new UpdateCommand(updateParams));
}

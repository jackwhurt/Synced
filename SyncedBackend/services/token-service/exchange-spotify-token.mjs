import { SSMClient, GetParameterCommand } from '@aws-sdk/client-ssm';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand, PutCommand, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import axios from 'axios';

const dynamoDbDocumentClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const ssmClient = new SSMClient({});
const tokensTable = process.env.TOKENS_TABLE;
const usersTable = process.env.USERS_TABLE;
const redirectUri = 'syncedapp://callback';

export const spotifyTokenExchangeHandler = async (event) => {
	try {
		const { cognitoUserId, code, receivedState } = validateEvent(event);
		await validateState(cognitoUserId, receivedState);

		const tokenResponse = await exchangeCodeForTokens(code, redirectUri);
		await storeTokens(cognitoUserId, tokenResponse);

        const spotifyUserId = await fetchSpotifyUserId(tokenResponse.access_token);
        await storeUserCredentials(cognitoUserId, spotifyUserId);

		return { statusCode: 200, body: JSON.stringify(tokenResponse) };
	} catch (error) {
		console.error('Error during token exchange:', error);

		return { statusCode: 500, body: JSON.stringify({ message: error.message || 'Internal Server Error' }) };
	}
};

function validateEvent(event) {
	const claims = event.requestContext.authorizer?.claims;
	const code = event.queryStringParameters?.code;
	const receivedState = event.queryStringParameters?.state;
	if (!code || !receivedState) {
		throw new Error('Missing required query parameters');
	}

	return { cognitoUserId: claims['sub'], code, receivedState };
}

async function validateState(cognitoUserId, receivedState) {
	const params = {
		TableName: tokensTable,
		Key: { 'token_id': `spotifyState#${cognitoUserId}` }
	};
	const response = await dynamoDbDocumentClient.send(new GetCommand(params));

	const storedState = response.Item?.state;
	if (receivedState !== storedState) {
		throw new Error('Invalid state parameter');
	}
}

async function exchangeCodeForTokens(code, redirectUri) {
	const clientId = await getParameter('spotifyClientId');
	const clientSecret = await getParameter('spotifyClientSecret');

	const response = await axios({
		method: 'post',
		url: 'https://accounts.spotify.com/api/token',
		data: new URLSearchParams({
			grant_type: 'authorization_code',
			code: code,
			redirect_uri: redirectUri
		}),
		headers: {
			'Content-Type': 'application/x-www-form-urlencoded',
			'Authorization': 'Basic ' + Buffer.from(`${clientId}:${clientSecret}`).toString('base64')
		}
	});

	return response.data;
}

async function getParameter(name) {
	const parameter = await ssmClient.send(new GetParameterCommand({ Name: name, WithDecryption: true }));

	return parameter.Parameter.Value;
}

async function storeTokens(cognitoId, tokenResponse) {
	const params = {
		TableName: tokensTable,
		Item: {
			token_id: `spotify#${cognitoId}`,
			accessToken: tokenResponse.access_token,
			refreshToken: tokenResponse.refresh_token,
			timestamp: `${Date.now()}`
		}
	};

	await dynamoDbDocumentClient.send(new PutCommand(params));
}

async function fetchSpotifyUserId(accessToken) {
    const url = 'https://api.spotify.com/v1/me';
    const headers = {
        'Authorization': `Bearer ${accessToken}`
    };

    const response = await axios.get(url, { headers });
    return response.data.id;
}

async function storeUserCredentials(cognitoId, spotifyUserId) {
	const updateParams = {
        TableName: usersTable,
        Key: {
            userId: cognitoId
        },
        UpdateExpression: "set spotifyUserId = :suid, updatedAt = :ts",
        ExpressionAttributeValues: {
            ":suid": spotifyUserId,
            ":ts": new Date().toISOString()
        }
    };

    try {
		await dynamoDbDocumentClient.send(new UpdateCommand(updateParams));
        console.log('User credentials updated successfully');
    } catch (error) {
        console.error('Error in storing user credentials:', error);
        throw error;
    }
}

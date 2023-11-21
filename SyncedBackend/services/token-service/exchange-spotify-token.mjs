import { SSMClient, GetParameterCommand } from '@aws-sdk/client-ssm';
import { DynamoDBClient, GetItemCommand } from '@aws-sdk/client-dynamodb';
import axios from 'axios';

const ssmClient = new SSMClient({});
const dynamoDbClient = new DynamoDBClient({});
const tokensTable = process.env.TOKENS_TABLE;
const redirectUri = 'https://www.google.com';

export const spotifyTokenExchangeHandler = async (event) => {
	const claims = event.requestContext.authorizer?.claims;
	if (!claims) {
		return { statusCode: 401, body: JSON.stringify({ message: 'Unauthorised' }) };
	}
	const cognitoUserId = claims['sub'];

	const code = event.queryStringParameters?.code;
	const receivedState = event.queryStringParameters?.state;
	if (!code || !receivedState) {
		return { statusCode: 400, body: JSON.stringify({ message: 'Missing required query parameters' }) };
	}

	try {
		const storedState = await getStoredState(cognitoUserId);
		if (receivedState !== storedState) {
			return { statusCode: 400, body: JSON.stringify({ message: 'Invalid state parameter' }) };
		}

		const clientId = await getParameter('spotifyClientId');
		const clientSecret = await getParameter('spotifyClientSecret');

		const tokenResponse = await exchangeCodeForTokens(clientId, clientSecret, code, redirectUri);
		await storeTokens(cognitoUserId, tokenResponse.access_token, tokenResponse.refresh_token);

		return {
			statusCode: 200,
			body: JSON.stringify(tokenResponse)
		};
	} catch (error) {
		console.error('Error during token exchange:', error);

		return {
			statusCode: 500,
			body: JSON.stringify({ message: 'Internal Server Error' })
		};
	}
};

async function getStoredState(cognitoUserId) {
	const params = {
		TableName: tokensTable,
		Key: { 'token_id': { S: `state#${cognitoUserId}` } }
	};
	const response = await dynamoDbClient.send(new GetItemCommand(params));

	return response.Item?.UUID?.S;
}

async function exchangeCodeForTokens(clientId, clientSecret, code, redirectUri) {
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

async function storeTokens(cognitoId, accessToken, refreshToken) {
	const params = {
		TableName: tokensTable,
		Item: {
			token_id: { S: `spotify#${cognitoId}` },
			access_token: { S: accessToken },
			refresh_token: { S: refreshToken },
			timestamp: { N: `${Date.now()}` }
		}
	};

	await dynamoDbClient.send(new PutItemCommand(params));
}
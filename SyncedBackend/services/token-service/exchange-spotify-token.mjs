import { SSMClient, GetParameterCommand } from '@aws-sdk/client-ssm';
import { DynamoDBClient, GetItemCommand, PutItemCommand } from '@aws-sdk/client-dynamodb';
import axios from 'axios';

// Initialize clients and environment variables
const ssmClient = new SSMClient({});
const dynamoDbClient = new DynamoDBClient({});
const tokensTable = process.env.TOKENS_TABLE;
const redirectUri = 'https://www.google.com';

export const spotifyTokenExchangeHandler = async (event) => {
	try {
		const { cognitoUserId, code, receivedState } = validateEvent(event);
		await validateState(cognitoUserId, receivedState);

		const tokenResponse = await exchangeCodeForTokens(code, redirectUri);
		await storeTokens(cognitoUserId, tokenResponse);

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
		Key: { 'token_id': { S: `spotifyState#${cognitoUserId}` } }
	};
	const response = await dynamoDbClient.send(new GetItemCommand(params));

	const storedState = response.Item?.UUID?.S;
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
			token_id: { S: `spotify#${cognitoId}` },
			access_token: { S: tokenResponse.access_token },
			refresh_token: { S: tokenResponse.refresh_token },
			timestamp: { N: `${Date.now()}` }
		}
	};

	await dynamoDbClient.send(new PutItemCommand(params));
}

import { SSMClient, GetParameterCommand } from '@aws-sdk/client-ssm';
import { DynamoDBClient, PutItemCommand } from '@aws-sdk/client-dynamodb';
import { v4 as uuidv4 } from 'uuid';

const ssmClient = new SSMClient({});
const dynamoDbClient = new DynamoDBClient({});

const tokensTable = process.env.TOKENS_TABLE;
const redirectUrl = 'https://www.google.com';

export const spotifyAuthUrlHandler = async (event) => {
	const claims = event.requestContext.authorizer?.claims;
	if (!claims) {
		return { statusCode: 401, body: JSON.stringify({ message: 'Unauthorised' }) };
	}

	const cognitoUserId = claims['sub'];
	const clientId = await getParameter('spotifyClientId');
	const redirectUri = redirectUrl;
	const stateUuid = uuidv4();
	const scopes = 'playlist-modify-private playlist-modify-public';

	try {
		await storeUuid(cognitoUserId, stateUuid);
	} catch (error) {
		console.error('Error storing UUID in DynamoDB:', error);
		return {
			statusCode: 500,
			body: JSON.stringify({ message: 'Internal Server Error' })
		};
	}

	const params = new URLSearchParams({
		response_type: 'code',
		client_id: clientId,
		scope: scopes,
		redirect_uri: redirectUri,
		state: stateUuid
	}).toString();

	const authoriseURL = `https://accounts.spotify.com/authorize?${params}`;

	return {
		statusCode: 302,
		headers: {
			Location: authoriseURL
		}
	};
};

async function getParameter(name) {
	const parameter = await ssmClient.send(new GetParameterCommand({ Name: name, WithDecryption: true }));

	return parameter.Parameter.Value;
}

async function storeUuid(cognitoId, stateUuid) {
	const params = {
		TableName: tokensTable,
		Item: {
			token_id: { S: `spotifyState#${cognitoId}` },
			UUID: { S: stateUuid },
			Timestamp: { N: `${Date.now()}` }
		}
	};

	await dynamoDbClient.send(new PutItemCommand(params));
}

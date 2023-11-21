import { SSMClient, GetParameterCommand } from '@aws-sdk/client-ssm';
import { DynamoDBClient, PutItemCommand } from '@aws-sdk/client-dynamodb';
import { v4 as uuidv4 } from 'uuid';

const ssmClient = new SSMClient({});
const dynamoDbClient = new DynamoDBClient({});
const tokensTable = process.env.TOKENS_TABLE;
const redirectUrl = 'https://www.google.com';

export const spotifyAuthUrlHandler = async (event) => {
	try {
        const claims = event.requestContext.authorizer?.claims;
		const cognitoUserId = claims['sub'];
		const clientId = await getParameter('spotifyClientId');
        const stateUuid = uuidv4();

		await storeState(cognitoUserId, stateUuid);

		const authoriseURL = buildSpotifyAuthUrl(clientId, stateUuid);

		return {
			statusCode: 302,
			headers: { Location: authoriseURL }
		};
	} catch (error) {
		console.error('Error in spotifyAuthUrlHandler:', error);

		return { statusCode: 500, body: JSON.stringify({ message: error.message || 'Internal Server Error' }) };
	}
};

async function getParameter(name) {
	const parameter = await ssmClient.send(new GetParameterCommand({ Name: name, WithDecryption: true }));

	return parameter.Parameter.Value;
}

async function storeState(cognitoId, stateUuid) {
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

function buildSpotifyAuthUrl(clientId, stateUuid) {
	const scopes = 'playlist-modify-private playlist-modify-public';
	const params = new URLSearchParams({
		response_type: 'code',
		client_id: clientId,
		scope: scopes,
		redirect_uri: redirectUrl,
		state: stateUuid
	}).toString();

	return `https://accounts.spotify.com/authorize?${params}`;
}

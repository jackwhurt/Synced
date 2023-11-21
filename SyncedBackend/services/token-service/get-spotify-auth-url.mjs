import { SSMClient } from '@aws-sdk/client-ssm';

const ssmClient = new SSMClient({});

const clientId = process.env.SPOTIFY_CLIENT_ID; // Set this in your Lambda environment variables
const redirectUri = process.env.SPOTIFY_REDIRECT_URI; // Set this in your Lambda environment variables

export const spotifyAuthUrlHandler = async (event) => {
	const scopes = 'playlist-modify-private playlist-modify-public'; // Adjust the scopes to your needs

	const params = new URLSearchParams({
		response_type: 'code',
		client_id: clientId,
		scope: scopes,
		redirect_uri: redirectUri,
		state: 'yourUniqueStateString' // Optional, but recommended for security
	}).toString();

	const authorizeURL = `https://accounts.spotify.com/authorize?${params}`;

	return {
		statusCode: 302,
		headers: {
			Location: authorizeURL
		}
	};
};

async function getParameter(name) {
	const parameter = await ssmClient.send(new GetParameterCommand({ Name: name, WithDecryption: true }));

	return parameter.Parameter.Value;
}
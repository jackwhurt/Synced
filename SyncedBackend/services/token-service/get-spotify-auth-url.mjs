import { SSMClient } from '@aws-sdk/client-ssm';

const ssmClient = new SSMClient({});

export const spotifyAuthUrlHandler = async () => {
	const clientId = await getParameter('spotifyClientId');
	const redirectUri = await getParameter('spotifyClientSecret');

	const scopes = 'playlist-modify-private playlist-modify-public'; // Adjust the scopes to your needs

	const params = new URLSearchParams({
		response_type: 'code',
		client_id: clientId,
		scope: scopes,
		redirect_uri: redirectUri,
		state: 'yourUniqueStateString' // Optional, but recommended for security
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
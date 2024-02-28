import { prepareSpotifyAccounts } from '/opt/nodejs/spotify-utils.mjs';

const usersTable = process.env.USERS_TABLE;
const tokensTable = process.env.TOKENS_TABLE;

export const getSpotifyAuthStatusHandler = async (event) => {
    console.info('received:', event);

    const claims = event.requestContext.authorizer?.claims;
    const userId = claims['sub'];

    try {
        const { spotifyUsers, failedSpotifyUsers } = await prepareSpotifyAccounts([userId], usersTable, tokensTable);
        const response = { isSpotifyConnected: spotifyUsers.length === 1 ? true : false }

        console.info(`returned: ${JSON.stringify(response)}`);

        return {
            statusCode: 200,
            body: JSON.stringify(response)
        };
    } catch (err) {
        return handleError('Error checking spotify auth status', err, 500);
    }
};

function handleError(message, err, statusCode) {
    console.error(message, err);
    return {
        statusCode: statusCode || 500,
        body: JSON.stringify({ error: message })
    };
}

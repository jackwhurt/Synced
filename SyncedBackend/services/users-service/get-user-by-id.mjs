import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand } from '@aws-sdk/lib-dynamodb';
import { prepareSpotifyAccounts } from '/opt/nodejs/spotify-utils.mjs';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const usersTable = process.env.USERS_TABLE;
const tokensTable = process.env.TOKENS_TABLE;

export const getUserByIdHandler = async (event) => {
    console.info('received:', event);
    const userId = event.pathParameters?.id;

    if (!userId) {
        return handleError('No user ID provided', null, 400);
    }

    try {
        const user = await getUserData(userId);
        if (!user) {
            return handleError('User not found', null, 404);
        }

        const { spotifyUsers, failedSpotifyUsers } = await prepareSpotifyAccounts([user.userId], usersTable, tokensTable);

        const filteredUser = {
            user: {
                userId: user.userId,
                username: user.attributeValue,
                photoUrl: user.photoUrl,
                isSpotifyConnected: spotifyUsers.length === 1 ? true : false
            }
        }

        console.info(`returned: ${JSON.stringify(filteredUser)}`);

        return {
            statusCode: 200,
            body: JSON.stringify(filteredUser)
        };
    } catch (err) {
        return handleError('Error retrieving user', err, 500);
    }
};

async function getUserData(userId) {
    const params = {
        TableName: usersTable,
        Key: { userId: userId }
    };

    try {
        const { Item } = await ddbDocClient.send(new GetCommand(params));
        return Item;
    } catch (err) {
        throw new Error('Failed to fetch user data');
    }
}

function handleError(message, err, statusCode) {
    console.error(message, err);
    return {
        statusCode: statusCode || 500,
        body: JSON.stringify({ error: message })
    };
}

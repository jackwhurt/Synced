import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);
const usersTableName = process.env.USERS_TABLE;

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

        const filteredUser = {
            user: {
                userId: user.userId,
                username: user.attributeValue,
                photoUrl: user.photoUrl
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
        TableName: usersTableName,
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

import { DynamoDBDocumentClient, GetCommand } from '@aws-sdk/lib-dynamodb';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';

const dynamoDBClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));

async function getAppleMusicDevToken(tokensTable) {
    const tokenKey = { token_id: 'appleMusicDev' };
    try {
        const data = await dynamoDBClient.send(new GetCommand({
            TableName: tokensTable,
            Key: tokenKey
        }));
        return data.Item ? data.Item.accessToken : null;
    } catch (error) {
        console.error('Error retrieving Apple Music Developer token:', error);
        throw error;
    }
}

async function getAppleMusicUserToken(userId, tokensTable) {
    const tokenKey = { token_id: `appleMusic#${userId}` };
    try {
        const data = await dynamoDBClient.send(new GetCommand({
            TableName: tokensTable,
            Key: tokenKey
        }));
        return data.Item ? data.Item.accessToken : null;
    } catch (error) {
        console.error(`Error retrieving Apple Music User token for user ID ${userId}:`, error);
        throw error;
    }
}

export async function prepareAppleMusicAccounts(userIds, tokensTable) {
    const appleMusicUsers = [];
    const failedAppleMusicUsers = [];

    // Retrieve the Apple Music Developer token
    const devToken = await getAppleMusicDevToken(tokensTable);

    for (const userId of userIds) {
        try {
            const token = await getAppleMusicUserToken(userId, tokensTable);

            if (!token) {
                throw new Error(`Apple Music user token not found for user ID: ${userId}`);
            }

            appleMusicUsers.push({
                userId,
                devToken, 
                token
            });
        } catch (error) {
            console.error(`Error preparing Apple Music account for user ID ${userId}:`, error);
            failedAppleMusicUsers.push({ userId, error: error.message });
        }
    }

    return { appleMusicUsers, failedAppleMusicUsers };
}

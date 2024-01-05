import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand } from '@aws-sdk/lib-dynamodb';

const dynamoDBClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const tokensTable = process.env.TOKENS_TABLE;

export const getAppleMusicDevTokenHandler = async () => {
    try {
        const appleMusicToken = await getAppleMusicToken();

        return { statusCode: 200, body: JSON.stringify({ appleMusicToken }) };
    } catch (apiError) {
        console.error('Error retrieving Apple Music token:', apiError);
        return { statusCode: 500, body: JSON.stringify({ message: 'Failed to retrieve Apple Music token' }) };
    }
};

async function getAppleMusicToken() {
    const getParams = {
        TableName: tokensTable,
        Key: { token_id: 'appleMusicDev' },
    };

    const response = await dynamoDBClient.send(new GetCommand(getParams));
    return response.Item ? response.Item.accessToken : null;
}

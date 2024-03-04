import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, UpdateCommand } from '@aws-sdk/lib-dynamodb';

const dynamoDBClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const tokensTable = process.env.TOKENS_TABLE;

export const updateAppleMusicUserTokenHandler = async (event) => {
    try {
        // Parse the appleMusicUserToken from the event body
        const { appleMusicUserToken } = JSON.parse(event.body);

        // Get the userId from the Cognito claims
        const userId = event.requestContext.authorizer.claims.sub;

        // Construct the token ID
        const tokenId = `appleMusic#${userId}`;

        // Update the token in the database
        await updateAppleMusicUserToken(tokensTable, tokenId, appleMusicUserToken);

        return { statusCode: 200, body: JSON.stringify({ message: 'Apple Music user token updated successfully' }) };
    } catch (error) {
        console.error('Error:', error);

        // Here you can add additional error handling or logging
        return { statusCode: 500, body: JSON.stringify({ message: 'Failed to update Apple Music user token' }) };
    }
};

async function updateAppleMusicUserToken(tableName, tokenId, appleMusicUserToken) {
    const updateParams = {
        TableName: tableName,
        Key: { token_id: tokenId },
        UpdateExpression: 'set accessToken = :t',
        ExpressionAttributeValues: {
            ':t': appleMusicUserToken
        }
    };

    await dynamoDBClient.send(new UpdateCommand(updateParams));
}

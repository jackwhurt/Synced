import { SSMClient, GetParameterCommand } from '@aws-sdk/client-ssm';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import { SNSClient, PublishCommand } from '@aws-sdk/client-sns';
import jwt from 'jsonwebtoken';

const ssmClient = new SSMClient({});
const dynamoDBClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const snsClient = new SNSClient({});

const tokensTable = process.env.TOKENS_TABLE;
const snsTopic = process.env.LAMBDA_FAILURE_TOPIC;
const MAX_RETRIES = 3;

export const updateAppleMusicDevTokenHandler = async () => {
    let retryCount = 0;

    while (retryCount < MAX_RETRIES) {
        try {
            const appleMusicToken = await generateAppleMusicToken();

            // Update the Apple Music token in DynamoDB
            await updateAppleMusicToken(tokensTable, 'appleMusicDev', appleMusicToken);

            return { statusCode: 200, body: JSON.stringify({ message: 'Apple Music token refreshed successfully' }) };
        } catch (apiError) {
            console.error('Attempt', retryCount + 1, 'failed:', apiError);
            retryCount++;

            if (retryCount >= MAX_RETRIES) {
                console.error('All attempts failed.');

                // Send alert using SNS
                await sendSnsAlert('Update Apple Music Dev Token function failed after max retries');

                return { statusCode: 500, body: JSON.stringify({ message: 'Failed to refresh Apple Music token after retries' }) };
            }
        }
    }
};

async function generateAppleMusicToken() {
    // Retrieve parameters from SSM
    const teamId = await getParameter('appleMusicTeamId');
    const keyId = await getParameter('appleMusicKeyId');
    const privateKey = await getParameter('appleMusicPrivateKey');

    // Calculate the expiration time (5 months from now)
    const expirationTime = Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 30 * 5;

    const token = jwt.sign({
        iss: teamId,
        exp: expirationTime,
        iat: Math.floor(Date.now() / 1000)
    }, privateKey, {
        algorithm: 'ES256',
        keyid: keyId
    });

    return token;
}

async function updateAppleMusicToken(tableName, primaryKeyValue, appleMusicToken) {
    const updateParams = {
        TableName: tableName,
        Key: { token_id: primaryKeyValue },
        UpdateExpression: 'set accessToken = :t, expiresAt = :e',
        ExpressionAttributeValues: {
            ':t': appleMusicToken,
            ':e': new Date().getTime() + 3600 * 1000 // 1 hour in milliseconds
        }
    };

    await dynamoDBClient.send(new UpdateCommand(updateParams));
}

async function getParameter(name) {
    const parameter = await ssmClient.send(new GetParameterCommand({ Name: name, WithDecryption: true }));
    return parameter.Parameter.Value;
}

async function sendSnsAlert(message) {
    await snsClient.send(new PublishCommand({
        Message: message,
        TopicArn: snsTopic
    }));
}
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import { SNSClient, CreatePlatformEndpointCommand } from "@aws-sdk/client-sns";

const snsClient = new SNSClient({});
const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const usersTable = process.env.USERS_TABLE;
const apnsPlatformArn = process.env.APNS_PLATFORM_ARN;
const isDevEnvironment = process.env.DEV_ENVIRONMENT === 'true';

export const registerUserForApnsHandler = async (event) => {
    console.info('Received event:', event);

    const claims = event.requestContext.authorizer?.claims;
    const userId = claims['sub'];
    const deviceToken = event.queryStringParameters?.deviceToken;

    if (!deviceToken) {
        console.error('Device token is missing');
        return { statusCode: 400, body: JSON.stringify({ error: 'Device token is required' }) };
    }

    try {
        const endpointArn = await createSNSEndpoint(deviceToken);
        await addTokenToDynamoDB(userId, endpointArn);
        console.info('Successfully created SNS endpoint:', endpointArn);

        return { statusCode: 200, body: JSON.stringify({ message: 'User registered for APNS successfully' }) };
    } catch (err) {
        console.error('Error registering user for APNS:', err);
        return { statusCode: 500, body: JSON.stringify({ error: 'Internal Server Error' }) };
    }
};

async function addTokenToDynamoDB(userId, endpointArn) {
    const attributeName = isDevEnvironment ? 'endpointArnDev' : 'endpointArn';

    const params = {
        TableName: usersTable,
        Key: {
            userId: userId
        },
        UpdateExpression: `SET ${attributeName} = :endpoint`,
        ExpressionAttributeValues: {
            ':endpoint': endpointArn
        }
    };

    await ddbDocClient.send(new UpdateCommand(params));

    console.info(`Successfully added ${attributeName} to the db`);
}

async function createSNSEndpoint(deviceToken) {
    const command = new CreatePlatformEndpointCommand({
        PlatformApplicationArn: apnsPlatformArn,
        Token: deviceToken
    });
    const response = await snsClient.send(command);
    return response.EndpointArn;
}

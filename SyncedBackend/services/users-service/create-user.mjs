import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const tableName = process.env.USERS_TABLE;

export const createUserHandler = async (event) => {
	// This function is triggered by a Cognito event, not an API Gateway event,
	// so we don't check for `event.httpMethod` here.
	console.info('Received Cognito event:', JSON.stringify(event, null, 2));

	const cognitoUserId = event.userName;
	const email = event.request.userAttributes.email;
	const timestamp = new Date().toISOString();

	const params = {
		TableName: tableName,
		Item: {
			cognito_user_id: cognitoUserId,
			email: email,
			createdAt: timestamp,
			updatedAt: timestamp
		}
	};

	try {
		const data = await ddbDocClient.send(new PutCommand(params));
		console.log('Success - user added to DynamoDB', data);

		return {
			statusCode: 200,
			body: JSON.stringify({
				message: 'User successfully added',
				userId: cognitoUserId,
				email: email
			})
		};

	} catch (err) {
		console.error('Error adding user to DynamoDB', err);

		return {
			statusCode: 500,
			body: JSON.stringify({
				message: 'Error adding user to DynamoDB',
				userId: cognitoUserId,
				email: email
			})
		};
	}
};

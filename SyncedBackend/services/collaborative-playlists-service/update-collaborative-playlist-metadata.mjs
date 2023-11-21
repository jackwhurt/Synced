import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, UpdateCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);
const tableName = process.env.PLAYLISTS_TABLE;

export const updateCollaborativePlaylistMetadataHandler = async (event) => {
	console.info('received:', event);

	if (!event.body) {
		return { statusCode: 400, body: JSON.stringify({ message: 'Missing body' }) };
	}

	const { playlist } = JSON.parse(event.body);

	if (!playlist || !playlist.id) {
		return { statusCode: 400, body: JSON.stringify({ message: 'Missing playlist ID' }) };
	}

	const claims = event.requestContext.authorizer?.claims;
	if (!claims) {
		return { statusCode: 401, body: JSON.stringify({ message: 'Unauthorised' }) };
	}

	const cognitoUserId = claims['sub'];
	const timestamp = new Date().toISOString();

	let updateExpression = 'set #updatedAt = :updatedAt';
	let expressionAttributeNames = { '#updatedAt': 'updatedAt' };
	let expressionAttributeValues = { ':updatedAt': timestamp };

	// Update only specific fields: title, description, coverImageUrl
	const fieldsToUpdate = ['title', 'description', 'coverImageUrl'];
	fieldsToUpdate.forEach((field) => {
		if (playlist[field] !== undefined) {
			updateExpression += `, #${field} = :${field}`;
			expressionAttributeNames[`#${field}`] = field;
			expressionAttributeValues[`:${field}`] = playlist[field];
		}
	});

	try {
		await ddbDocClient.send(new UpdateCommand({
			TableName: tableName,
			Key: {
				PK: `cp#${playlist.id}`,
				SK: 'metadata'
			},
			UpdateExpression: updateExpression,
			ConditionExpression: '#createdBy = :createdBy',
			ExpressionAttributeNames: {
				...expressionAttributeNames,
				'#createdBy': 'createdBy'
			},
			ExpressionAttributeValues: {
				...expressionAttributeValues,
				':createdBy': cognitoUserId
			}
		}));

		return {
			statusCode: 200,
			body: JSON.stringify({ message: 'Playlist updated successfully', playlist: playlist })
		};
	} catch (err) {
		if (err.name === 'ConditionalCheckFailedException') {
			return {
				statusCode: 403,
				body: JSON.stringify({ message: 'Unauthorised to update this playlist' })
			};
		}
		console.error('Error', err);
		return {
			statusCode: 500,
			body: JSON.stringify({ message: 'Error updating the collaborative playlist' })
		};
	}
};

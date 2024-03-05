import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, TransactWriteCommand, GetCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { createNotifications } from '/opt/nodejs/create-notifications.mjs';
import { getCollaboratorsByPlaylistId } from '/opt/nodejs/get-collaborators.mjs';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const activitiesTable = process.env.ACTIVITIES_TABLE;
const playlistsTable = process.env.PLAYLISTS_TABLE;
const usersTable = process.env.USERS_TABLE;
const isDevEnvironment = process.env.DEV_ENVIRONMENT === 'true';

export const deleteCollaboratorsHandler = async (event) => {
	console.info('received:', event);
	const { valid, response } = validateEvent(event);
	if (!valid) return response;

	const { playlistId, collaboratorIds, userId } = response;
	const playlistMetadata = await getPlaylistMetadata(playlistId);
	if (!playlistMetadata) return errorResponse(404, 'Playlist not found');
	if (playlistMetadata.createdBy !== userId || collaboratorIds.includes(playlistMetadata.createdBy)) return errorResponse(403, 'Not authorised to modify this data');

	try {
		const existingCollaborators = await getPlaylistCollaborators(playlistId);
		const isValidRequest = collaboratorIds.every(id => existingCollaborators.includes(id));
		if (!isValidRequest) return errorResponse(400, 'Invalid collaborator ID(s)');

		await deleteCollaborators(playlistId, collaboratorIds);
		await sendNotifications(playlistId, userId);

		return successResponse({ playlistId, collaboratorIds });
	} catch (err) {
		console.error('Error', err);
		return handleError(err);
	}
};

function validateEvent(event) {
	if (!event.body) return { valid: false, response: errorResponse(400, 'Missing body') };
	const { playlistId, collaboratorIds } = JSON.parse(event.body);
	if (!playlistId || !collaboratorIds || collaboratorIds.length === 0) return { valid: false, response: errorResponse(400, 'Missing required fields') };
	const claims = event.requestContext.authorizer?.claims;
	if (!claims) return { valid: false, response: errorResponse(401, 'Unauthorised') };
	const userId = claims['sub'];
	return { valid: true, response: { playlistId, collaboratorIds, userId } };
}

function errorResponse(statusCode, message) {
	console.info('returned:',  { statusCode, body: JSON.stringify({ error: message }) });

	return { statusCode, body: JSON.stringify({ error: message }) };
}

function successResponse(body) {
	console.info('returned:',  { statusCode: 200, body: JSON.stringify(body) });

	return { statusCode: 200, body: JSON.stringify(body) };
}

function handleError(err) {
	const message = err.name === 'TransactionCanceledException' ? 'Invalid collaborator criteria' : 'Error deleting collaborators';
	const statusCode = err.name === 'TransactionCanceledException' ? 400 : 500;
	return errorResponse(statusCode, message);
}

async function deleteCollaborators(playlistId, collaboratorIds) {
	const transactItems = collaboratorIds.flatMap(collaboratorId => [
		{
			Delete: {
				TableName: playlistsTable,
				Key: { PK: `cp#${playlistId}`, SK: `collaborator#${collaboratorId}` }
			}
		},
		{
			Delete: {
				TableName: activitiesTable,
				Key: { PK: `userId#${collaboratorId}`, SK: `requestPlaylist#${playlistId}` }
			}
		}
	]);

	transactItems.push({
		Update: {
			TableName: playlistsTable,
			Key: { PK: `cp#${playlistId}`, SK: 'metadata' },
			UpdateExpression: 'ADD #collaboratorCount :decr',
			ExpressionAttributeNames: { '#collaboratorCount': 'collaboratorCount' },
			ExpressionAttributeValues: { ':decr': -collaboratorIds.length },
			ReturnValuesOnConditionCheckFailure: 'ALL_OLD'
		}
	});

	await ddbDocClient.send(new TransactWriteCommand({ TransactItems: transactItems }));
}

async function getPlaylistMetadata(playlistId) {
	const params = {
		TableName: playlistsTable,
		Key: {
			PK: `cp#${playlistId}`,
			SK: 'metadata'
		}
	};

	try {
		const { Item } = await ddbDocClient.send(new GetCommand(params));

		return Item;
	} catch (err) {
		console.error('Error retrieving playlist metadata:', err);

		return null;
	}
}

async function getPlaylistCollaborators(playlistId) {
	const params = {
		TableName: playlistsTable,
		KeyConditionExpression: 'PK = :pk AND begins_with(SK, :sk)',
		ExpressionAttributeValues: {
			':pk': `cp#${playlistId}`,
			':sk': 'collaborator#'
		}
	};

	try {
		const { Items } = await ddbDocClient.send(new QueryCommand(params));
		return Items.map(item => item.SK.split('#')[1]);
	} catch (err) {
		console.error('Error retrieving collaborators:', err);
		return [];
	}
}

async function sendNotifications(playlistId, cognitoUserId) {
    const message = '@{user} has been removed from {playlist}.';

    try {
        const collaborators = await getCollaboratorsByPlaylistId(playlistId, playlistsTable);
        await createNotifications(collaborators.map(collaborator => collaborator.userId), message, cognitoUserId,
            playlistId, activitiesTable, usersTable, playlistsTable, isDevEnvironment);
    } catch (error) {
        console.error('Notification unsuccessful', error);
    }
}
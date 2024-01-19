import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand, BatchGetCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);
const playlistsTableName = process.env.PLAYLISTS_TABLE;
const usersTableName = process.env.USERS_TABLE;

export const getCollaborativePlaylistByIdHandler = async (event) => {
	console.info('received:', event);

	const playlistUuid = event.pathParameters?.id;
	if (!playlistUuid) {
		return { statusCode: 400, body: JSON.stringify('No playlist ID provided') };
	}
	const playlistId = 'cp#' + playlistUuid;
	const claims = event.requestContext.authorizer?.claims;
	const userId = claims['sub'];

	try {
		const playlistItemsData = await queryPlaylistItems(playlistId);
		const { appleMusicPlaylistId, collaborators, playlistMetadata, songs } = await processPlaylistItems(playlistItemsData.Items, userId);

		if (!playlistMetadata && collaborators.length === 0 && songs.length === 0) {
			return { statusCode: 404, body: JSON.stringify('Playlist not found') };
		}

		const response = { playlistId: playlistUuid, metadata: playlistMetadata, collaborators: collaborators, songs: songs }
		if (appleMusicPlaylistId) response.appleMusicPlaylistId = appleMusicPlaylistId;

		return {
			statusCode: 200,
			body: JSON.stringify(response)
		};
	} catch (err) {
		console.error('Error', err);

		return { statusCode: 500, body: JSON.stringify('Error retrieving playlist items') };
	}
};

async function queryPlaylistItems(playlistId) {
	const playlistItemsParams = {
		TableName: playlistsTableName,
		KeyConditionExpression: 'PK = :pk',
		ExpressionAttributeValues: { ':pk': playlistId }
	};

	return ddbDocClient.send(new QueryCommand(playlistItemsParams));
}

async function processPlaylistItems(items, userId) {
	let collaborators = [], playlistMetadata = null, songs = [], appleMusicPlaylistId = '';
	const userIds = items
		.filter(item => item.SK.startsWith('collaborator#'))
		.map(item => ({ cognito_user_id: item.GSI1PK.split('#')[1] }));

	const userItem = items.find(item => item.SK === `collaborator#${userId}`);
	if (userItem && userItem.appleMusicPlaylistId) {
		appleMusicPlaylistId = userItem.appleMusicPlaylistId;
	}

	collaborators = await fetchUsersData(userIds);

	for (const item of items) {
		if (item.SK === 'metadata') {
			playlistMetadata = item;
		} else if (item.SK.startsWith('song#')) {
			item.songId = item.SK.substring(5);
			delete item.SK;
			songs.push(item);
		}
	}

	return { appleMusicPlaylistId, collaborators, playlistMetadata, songs };
}

async function fetchUsersData(userIds) {
	if (userIds.length === 0) {
		return [];
	}

	const batchGetParams = {
		RequestItems: {
			[usersTableName]: {
				Keys: userIds
			}
		}
	};

	try {
		const usersData = await ddbDocClient.send(new BatchGetCommand(batchGetParams));

		return usersData.Responses[usersTableName] || [];
	} catch (err) {
		console.error('Error in batch get users:', err);

		return [];
	}
}

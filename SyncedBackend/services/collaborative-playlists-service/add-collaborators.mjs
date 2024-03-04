import { addCollaborators } from '/opt/nodejs/add-collaborators.mjs';
import { isPlaylistValid } from '/opt/nodejs/playlist-validator.mjs';
import { isCollaboratorInPlaylist } from '/opt/nodejs/playlist-validator.mjs';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const playlistsTable = process.env.PLAYLISTS_TABLE;
const usersTable = process.env.USERS_TABLE;
const activitiesTable = process.env.ACTIVITIES_TABLE
const isDevEnvironment = process.env.DEV_ENVIRONMENT === 'true';

export const addCollaboratorsHandler = async (event) => {
    console.info('received:', event);

    const { playlistId, collaboratorIds } = JSON.parse(event.body);
    const claims = event.requestContext.authorizer?.claims;
    const userId = claims['sub'];
    const validationResponse = await validateEvent(playlistId, collaboratorIds, userId);
    if (validationResponse) return validationResponse;
    collaboratorIds.push(userId);

    try {
        const title = await getPlaylistTitle(playlistId);
        await addCollaborators(playlistId, title, collaboratorIds, userId, false, playlistsTable, activitiesTable, usersTable, isDevEnvironment);

        return {
            statusCode: 200,
            body: JSON.stringify({
                playlistId,
                collaboratorIds
            })
        };
    } catch (err) {
        console.error('Error', err);
		return {
            statusCode: 500,
            body: JSON.stringify({ error: 'Error adding collaborators' })
        };
    }
};

async function getPlaylistTitle(playlistId) {
	const params = {
		TableName: playlistsTable,
		Key: {
			PK: `cp#${playlistId}`,
			SK: 'metadata'
		}
	};

	try {
		const { Item } = await ddbDocClient.send(new GetCommand(params));
        const title = Item.title || '';

		return title;
	} catch (err) {
		console.error('Error retrieving playlist metadata:', err);

		return null;
	}
}

async function validateEvent(playlistId, collaboratorIds, userId) {
    if (!playlistId || !collaboratorIds || collaboratorIds.length === 0) {
        return { statusCode: 400, body: JSON.stringify({ error: 'Missing required fields' }) };
    }

    if (!await isPlaylistValid(playlistId, playlistsTable)) {
        return { statusCode: 400, body: JSON.stringify({ error: 'Playlist doesn\'t exist: ' + playlistId }) };
    }

    if(!await isCollaboratorInPlaylist(playlistId, userId, playlistsTable)) {
        return { statusCode: 403, body: JSON.stringify({ error: 'Not authorised to edit this playlist' }) };
    }
}
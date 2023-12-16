import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, UpdateCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const playlistsTable = process.env.PLAYLISTS_TABLE;

export const updateAppleMusicPlaylistIdHandler = async (event) => {
    console.info('received:', event);

    try {
        const { playlistId, appleMusicPlaylistId } = parseEventBody(event);
        const claims = event.requestContext.authorizer?.claims;
        const userId = claims['sub'];

        const result = await updatePlaylist(playlistId, userId, appleMusicPlaylistId);

        return createResponse(200, result.Attributes);
    } catch (err) {
        console.error('Error updating appleMusicId:', err);
        return createErrorResponse(err);
    }
}

async function updatePlaylist(playlistId, userId, appleMusicPlaylistId) {
    const params = createUpdateParams(playlistId, userId, appleMusicPlaylistId);
    const result = await ddbDocClient.send(new UpdateCommand(params));

    if (!result.Attributes) {
        throw new Error('No matching item found in the database.');
    }

    console.info(`Updated appleMusicId for collaborator ${userId} in playlist ${playlistId}`);
    return result;
}

function createUpdateParams(playlistId, userId, appleMusicPlaylistId) {
    return {
        TableName: playlistsTable,
        Key: {
            PK: `cp#${playlistId}`,
            SK: `collaborator#${userId}`
        },
        UpdateExpression: 'SET appleMusicId = :appleMusicId',
        ExpressionAttributeValues: {
            ':appleMusicId': appleMusicPlaylistId
        },
        ConditionExpression: 'attribute_exists(PK) AND attribute_exists(SK)',
        ReturnValues: 'ALL_NEW'
    };
}

function createResponse(statusCode, body) {
    return {
        statusCode,
        body: JSON.stringify(body)
    };
}

function createErrorResponse(err) {
    return {
        statusCode: err.statusCode || 500,
        body: JSON.stringify({ error: err.message })
    };
}
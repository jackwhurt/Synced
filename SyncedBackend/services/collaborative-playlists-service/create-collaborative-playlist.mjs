import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, TransactWriteCommand } from '@aws-sdk/lib-dynamodb';
import { v4 as uuidv4 } from 'uuid';
import { createPlaylist } from '/opt/nodejs/create-streaming-service-playlist.mjs';
import { addCollaborators } from '/opt/nodejs/add-collaborators.mjs';

const ddbDocClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const playlistsTable = process.env.PLAYLISTS_TABLE;
const tokensTable = process.env.TOKENS_TABLE;
const usersTable = process.env.USERS_TABLE;
const MAX_COLLABORATORS = 10;

export const createCollaborativePlaylistHandler = async (event) => {
    console.info('received:', event);
    const response = parseAndValidateEvent(event);
    if (response) return response;

    const { playlist, collaborators } = JSON.parse(event.body);
    const claims = event.requestContext.authorizer?.claims;
    const cognitoUserId = claims['sub'];
    const timestamp = new Date().toISOString();
    const playlistId = uuidv4();

    collaborators.push(cognitoUserId);

    const transactItem = createPlaylistItem(playlistId, cognitoUserId, playlist, collaborators, timestamp);

    try {
        await ddbDocClient.send(new TransactWriteCommand({ TransactItems: [transactItem] }));
        await addCollaborators(playlistId, collaborators, cognitoUserId, playlistsTable, usersTable);
        await createPlaylist(playlist, cognitoUserId, usersTable, tokensTable);

        return {
            statusCode: 200,
            body: JSON.stringify({
                id: playlistId,
                playlist,
                collaborators,
                createdAt: timestamp
            })
        };
    } catch (err) {
        console.error('Error:', err);
        await rollbackPlaylistData([transactItem]);

        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Error creating Collaborative Playlist' })
        };
    }
};

// Helper function to parse and validate the event
function parseAndValidateEvent(event) {
    if (!event.body) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Missing body' }) };
    }

    const { playlist, collaborators } = JSON.parse(event.body);
    if (!playlist || !playlist.title) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Missing required fields' }) };
    }
    if (collaborators && collaborators.length > MAX_COLLABORATORS) {
        return { statusCode: 400, body: JSON.stringify({ message: `Collaborator limit reached: ${MAX_COLLABORATORS}` }) };
    }
}

// Helper function to create a playlist item for DynamoDB
function createPlaylistItem(playlistId, userId, playlist, collaborators, timestamp) {
    return {
        Put: {
            TableName: playlistsTable,
            Item: {
                PK: `cp#${playlistId}`,
                SK: 'metadata',
                createdBy: userId,
                ...playlist,
                collaboratorCount: collaborators.length,
                songCount: 0,
                createdAt: timestamp,
                updatedAt: timestamp
            }
        }
    };
}

// Helper function to rollback in case of an error
async function rollbackPlaylistData(transactItems) {
    console.info('Rollback started');
    // Convert Put operations to Delete operations
    const deleteOperations = transactItems.map(item => ({
        Delete: {
            TableName: item.Put.TableName,
            Key: {
                PK: item.Put.Item.PK,
                SK: item.Put.Item.SK
            }
        }
    }));

    try {
        await ddbDocClient.send(new TransactWriteCommand({ TransactItems: deleteOperations }));
        console.info('Rollback successful');
    } catch (error) {
        console.error('Error during cleanup:', error);
    }
}

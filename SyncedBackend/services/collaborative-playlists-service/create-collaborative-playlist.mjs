import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, TransactWriteCommand } from '@aws-sdk/lib-dynamodb';
import { v4 as uuidv4 } from 'uuid';
import { createSpotifyPlaylist } from '/opt/nodejs/streaming-service/create-streaming-service-playlist.mjs';
import { deleteSpotifyPlaylist } from '/opt/nodejs/streaming-service/delete-streaming-service-playlist.mjs';
import { addCollaborators } from '/opt/nodejs/add-collaborators.mjs';
import { prepareSpotifyAccounts } from '/opt/nodejs/spotify-utils.mjs';

const ddbDocClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const playlistsTable = process.env.PLAYLISTS_TABLE;
const tokensTable = process.env.TOKENS_TABLE;
const usersTable = process.env.USERS_TABLE;
const activitiesTable = process.env.ACTIVITIES_TABLE
const MAX_COLLABORATORS = 10;

export const createCollaborativePlaylistHandler = async (event) => {
    console.info('Received:', event);
    
    const validationResult = parseAndValidateEvent(event);
    if (validationResult.error) return createErrorResponse(validationResult.error);

    const { playlist, collaborators, spotifyPlaylist } = validationResult.data;
    const userId = getUserIdFromEvent(event);
    const timestamp = new Date().toISOString();
    playlist.playlistId = uuidv4();
    collaborators.push(userId);

    const transactItem = createPlaylistItem(playlist.playlistId, userId, playlist, timestamp);

    try {
        await handlePlaylistCreation(transactItem, playlist, collaborators, userId, spotifyPlaylist);
        return createSuccessResponse(playlist, playlist.playlistId, collaborators, timestamp);
    } catch (err) {
        console.error('Error:', err);
        await rollbackPlaylistData([transactItem]);
        return createErrorResponse(err);
    }
};

// Parse and validate the event
function parseAndValidateEvent(event) {
    try {
        if (!event.body) {
            throw new Error('Missing request body');
        }

        const body = JSON.parse(event.body);
        validateBody(body);
        return { data: body };
    } catch (error) {
        return { error: { statusCode: 400, message: error.message } };
    }
}

// Validate the body of the event
function validateBody(body) {
    if (!body.playlist || !body.playlist.title) {
        throw new Error('Missing required playlist fields');
    }
    if (body.collaborators && body.collaborators.length > MAX_COLLABORATORS) {
        throw new Error(`Collaborator limit reached: ${MAX_COLLABORATORS}`);
    }
}

// Get user ID from event
function getUserIdFromEvent(event) {
    const claims = event.requestContext.authorizer?.claims;
    return claims['sub'];
}

// Helper function to create a playlist item for DynamoDB
function createPlaylistItem(playlistId, userId, playlist, timestamp) {
    return {
        Put: {
            TableName: playlistsTable,
            Item: {
                PK: `cp#${playlistId}`,
                SK: 'metadata',
                createdBy: userId,
                ...playlist,
                collaboratorCount: 0,
                songCount: 0,
                createdAt: timestamp,
                updatedAt: timestamp
            }
        }
    };
}

const handlePlaylistCreation = async (transactItem, playlist, collaborators, userId, spotifyPlaylist) => {
    await ddbDocClient.send(new TransactWriteCommand({ TransactItems: [transactItem] }));
    await addCollaborators(playlist.playlistId, collaborators, userId, playlistsTable, activitiesTable, usersTable);
    if(!spotifyPlaylist) return;

    let spotifyPlaylistId;
    try {
        spotifyPlaylistId = await handleSpotifyPlaylist(playlist, userId);
    } catch (err) {
        console.error('Error creating Spotify playlist');
        await deleteSpotifyPlaylist(spotifyPlaylistId, spotifyUsers[0]);

        throw err;
    }
};

// Handle Spotify Playlist Creation
async function handleSpotifyPlaylist(playlist, userId) {
    const { spotifyUsers, failedSpotifyUsers } = await prepareSpotifyAccounts([userId], usersTable, tokensTable);
    if (!failedSpotifyUsers) throw new Error('Spotify account could not be prepared for user: ' + userId);

    const spotifyPlaylistId = await createSpotifyPlaylist(playlist, spotifyUsers[0], playlistsTable);
    return spotifyPlaylistId; // Indicate that Spotify playlist was successfully created
}

// Helper function to rollback in case of an error
async function rollbackPlaylistData(transactItems) {
    if (transactItems.length === 0) {
        console.info('No items to rollback.');
        return;
    }

    console.info('Rollback database transaction started');
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

// Create a success response
function createSuccessResponse(playlist, playlistId, collaborators, timestamp) {
    return {
        statusCode: 201,
        body: JSON.stringify({
            id: playlistId,
            playlist,
            collaborators,
            createdAt: timestamp
        })
    };
}

// Create an error response
function createErrorResponse(error) {
    return {
        statusCode: 500,
        body: JSON.stringify({ message: `Error creating Collaborative Playlist: ${error.message}` })
    };
}
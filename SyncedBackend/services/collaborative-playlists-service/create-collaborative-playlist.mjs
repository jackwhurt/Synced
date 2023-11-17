import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, TransactWriteCommand } from '@aws-sdk/lib-dynamodb';

// Create a DocumentClient that represents the query to put an item
const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

// Get the DynamoDB table name from environment variables
const tableName = process.env.PLAYLISTS_TABLE;

const MAX_SONGS = 50;
const MAX_COLLABORATORS = 10;

export const createCollaborativePlaylistHandler = async (event) => {
    console.info('received:', event);

    if (!event.body) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Missing body' }) };
    }

    const { playlist, collaborators, songs } = JSON.parse(event.body);
    if (!playlist || !playlist.title) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Missing required fields' }) };
    }

    if (songs && songs.length > MAX_SONGS) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Song limit reached: ' + MAX_SONGS }) };
    }

    if (collaborators && collaborators.length > MAX_COLLABORATORS) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Collaborator limit reached: ' + MAX_COLLABORATORS }) };
    }

    const claims = event.requestContext.authorizer?.claims;
    if (!claims) {
        return { statusCode: 401, body: JSON.stringify({ message: 'Unauthorised' }) };
    }

    const cognitoUserId = claims['sub'];
    const timestamp = new Date().toISOString();
    const playlistId = uuidv4();
    const transactItems = [];   
    const collaboratorCount = collaborators ? collaborators.length + 1 : 1;
    const songCount = songs ? songs.length : 0;

    transactItems.push({
        Put: {
            TableName: tableName,
            Item: {
                PK: `cp#${playlistId}`,
                SK: `metadata`,
                createdBy: cognitoUserId,
                ...playlist,
                collaboratorCount: collaboratorCount,
                songCount: songsCount,
                createdAt: timestamp,
                updatedAt: timestamp,
            }
        }
    });

    if (songs) {
        songs.forEach((song) => {
            const songId = uuidv4();
            transactItems.push({
                Put: {
                    TableName: tableName,
                    Item: {
                        PK: `cp#${playlistId}`,
                        SK: `song#${songId}`,
                        ...song,
                        createdAt: timestamp,
                    }
                }
            });
        });
    }

    if (collaborators) {
        collaborators.forEach((collaboratorId) => {
            transactItems.push({
                Put: {
                    TableName: tableName,
                    Item: {
                        PK: `cp#${playlistId}`,
                        SK: `collaborator#${collaboratorId}`,
                        GSI1PK: `collaborator#${collaboratorId}`,
                        addedBy: cognitoUserId,
                        createdAt: timestamp,
                    }
                }
            });
        });
    }

    transactItems.push({
        Put: {
            TableName: tableName,
            Item: {
                PK: `cp#${playlistId}`,
                SK: `collaborator#${cognitoUserId}`,
                GSI1PK: `collaborator#${cognitoUserId}`,
                addedBy: cognitoUserId,
                createdAt: timestamp,
            }
        }
    });

    try {
        await ddbDocClient.send(new TransactWriteCommand({ TransactItems: transactItems }));

        return {
            statusCode: 200,
            body: JSON.stringify({
                id: playlistId,
                playlist: playlist,
                collaborators: collaborators,
                songs: songs,
                createdAt: timestamp
            })
        };
    } catch (err) {
        console.error("Error", err);

        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Error creating the collaborative playlist' })
        };
    }
};

function uuidv4() {
    var dt = new Date().getTime();
    var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
        var r = (dt + Math.random() * 16) % 16 | 0;
        dt = Math.floor(dt / 16);
        return (c == 'x' ? r : (r & 0x3 | 0x8)).toString(16);
    });
    return uuid;
}

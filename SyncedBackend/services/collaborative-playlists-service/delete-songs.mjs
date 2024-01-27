import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, TransactWriteCommand } from '@aws-sdk/lib-dynamodb';
import { isPlaylistValid } from '/opt/nodejs/playlist-validator.mjs';
import { isCollaboratorInPlaylist } from '/opt/nodejs/playlist-validator.mjs';
import { prepareSpotifyAccounts } from '/opt/nodejs/spotify-utils.mjs';
import { deleteSongsFromSpotifyPlaylist } from '/opt/nodejs/streaming-service/delete-songs.mjs';
import { syncPlaylists } from '/opt/nodejs/streaming-service/sync-collaborative-playlists.mjs';
import { getCollaboratorsByPlaylistId } from '/opt/nodejs/get-collaborators.mjs';

const ddbDocClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const playlistsTable = process.env.PLAYLISTS_TABLE;
const tokensTable = process.env.TOKENS_TABLE;
const usersTable = process.env.USERS_TABLE;

export const deleteSongsHandler = async (event) => {
    console.info('Received:', event);
    const { playlistId, songs } = JSON.parse(event.body);
    const claims = event.requestContext.authorizer?.claims;
    const userId = claims['sub'];
    const validationResponse = await validateEvent(playlistId, userId, songs);
    if (validationResponse) return validationResponse;

    let collaboratorsData, failedSpotifyUsers, spotifyUsersMap, transactItems;

    try {
        ({ collaboratorsData, failedSpotifyUsers, spotifyUsersMap } = await prepareCollaborators(playlistId));
    } catch (err) {
        console.error('Error in collaborator preparation:', err);
        return buildErrorResponse(err);
    }

    try {
        transactItems = buildTransactItems(playlistId, songs);
        await ddbDocClient.send(new TransactWriteCommand({ TransactItems: transactItems }));
    } catch (err) {
        console.error('Error writing to the DB:', err);
        return buildErrorResponse(err);
    }

    try {
        let unsuccessfulUpdateUserIds = failedSpotifyUsers.map(user => user.userId);
        unsuccessfulUpdateUserIds = unsuccessfulUpdateUserIds.concat(await deleteSongsFromSpotifyPlaylists(songs, collaboratorsData, spotifyUsersMap));

        return buildSuccessResponse(unsuccessfulUpdateUserIds);
    } catch (err) {
        console.error('Error removing songs from streaming service playlists:', err);
        await rollbackPlaylistData(transactItems, songs);
        return buildErrorResponse(err);
    }
};

async function validateEvent(playlistId, userId, songs) {
    if (!playlistId || !songs || songs.length === 0) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Missing required fields' }) };
    }

    if (!await isPlaylistValid(playlistId, playlistsTable)) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Playlist doesn\'t exist: ' + playlistId }) };
    }

    if (!await isCollaboratorInPlaylist(playlistId, userId, playlistsTable)) {
        return { statusCode: 403, body: JSON.stringify({ message: 'Not authorised to edit this playlist' }) };
    }

    return null;
}

async function prepareCollaborators(playlistId) {
    const collaboratorsData = await getCollaboratorsByPlaylistId(playlistId, playlistsTable);
    const { spotifyUsers, failedSpotifyUsers } = await prepareSpotifyAccounts(collaboratorsData.map(c => c.userId), usersTable, tokensTable);
    const spotifyUsersMap = new Map(spotifyUsers.map(user => [user.userId, user]));

    const { updatedUsers } = await syncPlaylists(playlistId, spotifyUsersMap, collaboratorsData, playlistsTable);
    // Update collaborator data (streaming service playlist id) if users have been resynced
    if (updatedUsers) {
        return {
            collaboratorsData: await getCollaboratorsByPlaylistId(playlistId, playlistsTable),
            failedSpotifyUsers,
            spotifyUsersMap
        };
    }

    return { collaboratorsData, failedSpotifyUsers, spotifyUsersMap };
}

function buildTransactItems(playlistId, songs) {
    let transactItems = [];

    // Update playlist metadata
    transactItems.push({
        Update: {
            TableName: playlistsTable,
            Key: {
                PK: `cp#${playlistId}`,
                SK: 'metadata'
            },
            UpdateExpression: 'ADD #songCount :decr SET updatedAt = :updatedAt',
            ExpressionAttributeNames: {
                '#songCount': 'songCount'
            },
            ExpressionAttributeValues: {
                ':decr': -songs.length,
                ':updatedAt': new Date().toISOString()
            }
        }
    });

    songs.forEach(song => {
        transactItems.push({
            Delete: {
                TableName: playlistsTable,
                Key: {
                    PK: `cp#${playlistId}`,
                    SK: `song#${song.songId}`
                },
                // Make sure the songs exist in the DB, otherwise fail the transaction
                ConditionExpression: "attribute_exists(PK) AND attribute_exists(SK)"
            }
        });
    });

    return transactItems;
}

async function deleteSongsFromSpotifyPlaylists(songs, collaboratorsData, spotifyUsersMap) {
    if (!collaboratorsData) return;
    let unsuccessfulUpdateUserIds = [];
    const collaboratorsSpotifyData = collaboratorsData.filter(collaborator => collaborator.spotifyPlaylistId);

    for (const collaborator of collaboratorsSpotifyData) {
        try {
            await deleteSongsFromSpotifyPlaylist(collaborator.spotifyPlaylistId, spotifyUsersMap.get(collaborator.userId), songs, playlistsTable);
        } catch (error) {
            console.info('Unsuccessful Spotify Playlist update for user: ', collaborator.userId);
            unsuccessfulUpdateUserIds.push(collaborator.userId);
        }
    }

    return unsuccessfulUpdateUserIds;
}

async function rollbackPlaylistData(transactItems, songs) {
    const rollbackOperations = transactItems.map(item => {
        if (item.Delete) {
            // Reverse the delete operation by re-adding the song
            return {
                Put: {
                    TableName: item.Delete.TableName,
                    Item: {
                        PK: item.Delete.Key.PK,
                        SK: item.Delete.Key.SK,
                    }
                }
            };
        } else if (item.Update) {
            // Reverse the update operation
            return {
                Update: {
                    TableName: item.Update.TableName,
                    Key: item.Update.Key,
                    UpdateExpression: 'ADD #songCount :incr',
                    ExpressionAttributeNames: item.Update.ExpressionAttributeNames,
                    ExpressionAttributeValues: {
                        ':incr': songs.length
                    }
                }
            };
        }
    });

    try {
        await ddbDocClient.send(new TransactWriteCommand({ TransactItems: rollbackOperations }));
        console.info('Rollback successful');
    } catch (error) {
        console.error('Error during rollback:', error);
    }
}

function buildSuccessResponse(unsuccessfulUpdateUserIds) {
    let message = 'Songs deleted successfully';
    if (unsuccessfulUpdateUserIds.length > 0) {
        // Join user IDs with a comma and space for readability
        const failedUserIds = unsuccessfulUpdateUserIds.join(', ');
        message = `Songs deleted successfully except for the following user(s): ${failedUserIds}`;
    }

    return {
        statusCode: 200,
        body: JSON.stringify({ message })
    };
}

export function buildErrorResponse(err) {
    if (err.name === 'TransactionCanceledException') {
        return {
            statusCode: 400,
            body: JSON.stringify({ error: `Failed to delete songs, contained invalid ID(s).` })
        };
    }
    return {
        statusCode: 500,
        body: JSON.stringify({ error: 'Error deleting songs from Collaborative Playlist' })
    };
}
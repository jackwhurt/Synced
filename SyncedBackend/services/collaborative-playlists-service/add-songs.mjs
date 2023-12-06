import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, TransactWriteCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { v4 as uuidv4 } from 'uuid';
import { isPlaylistValid } from '/opt/nodejs/playlist-validator.mjs';
import { isCollaboratorInPlaylist } from '/opt/nodejs/playlist-validator.mjs';
import { prepareSpotifyAccounts } from '/opt/nodejs/spotify-utils.mjs';
import { getCollaboratorsByPlaylistId } from '/opt/nodejs/get-collaborators.mjs';
import { addSongsToSpotifyPlaylist } from '/opt/nodejs/streaming-service/add-songs.mjs';
import { syncPlaylists } from '/opt/nodejs/streaming-service/sync-collaborative-playlists.mjs';

const ddbDocClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const playlistsTable = process.env.PLAYLISTS_TABLE;
const tokensTable = process.env.TOKENS_TABLE;
const usersTable = process.env.USERS_TABLE;
const MAX_SONGS = 50;

// TODO: Add rest of songs just not duplicate ones
export const addSongsHandler = async (event) => {
    console.info('Received:', event);
    const { playlistId, songs } = JSON.parse(event.body);
    const claims = event.requestContext.authorizer?.claims;
    const userId = claims['sub'];
    const validationResponse = await validateEvent(playlistId, userId, songs);
    if (validationResponse) return validationResponse;

    const timestamp = new Date().toISOString();
    let collaboratorsData, failedSpotifyUsers, spotifyUsersMap, transactItems;

    try {
        ({ collaboratorsData, failedSpotifyUsers, spotifyUsersMap } = await prepareCollaboratorData(playlistId));

        transactItems = buildTransactItems(playlistId, songs, timestamp);
        await ddbDocClient.send(new TransactWriteCommand({ TransactItems: transactItems }));
    } catch (err) {
        console.error('Error in collaborator preparation:', err);
        return buildErrorResponse(err);
    }

    try {
        let unsuccessfulUpdateUserIds = failedSpotifyUsers.map(user => user.userId);
        unsuccessfulUpdateUserIds = unsuccessfulUpdateUserIds.concat(await addSongsToSpotifyPlaylists(songs, collaboratorsData, spotifyUsersMap));

        return buildSuccessResponse(unsuccessfulUpdateUserIds);
    } catch (err) {
        console.error('Error in adding songs to streaming service playlists:', err);
        await rollbackPlaylistData(transactItems);
        return buildErrorResponse(err);
    }
};

async function validateEvent(playlistId, userId, songs) {
    if (!playlistId || !songs || songs.length === 0) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Missing required fields' }) };
    }

    if (songs.length > MAX_SONGS) {
        return { statusCode: 400, body: JSON.stringify({ message: `Song limit reached: ${MAX_SONGS}` }) };
    }

    if (!await isPlaylistValid(playlistId, playlistsTable)) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Playlist doesn\'t exist: ' + playlistId }) };
    }

    if (!await isCollaboratorInPlaylist(playlistId, userId, playlistsTable)) {
        return { statusCode: 403, body: JSON.stringify({ message: 'Not authorised to edit this playlist' }) };
    }

    // Combined check for duplicate URIs within the submission and against the playlist
    const existingUris = await getExistingUrisForPlaylist(playlistId);
    const uriSet = new Set(existingUris);
    const duplicateUris = [];

    for (const song of songs) {
        if (uriSet.has(song.spotifyUri)) {
            duplicateUris.push(song.spotifyUri);
        } else {
            uriSet.add(song.spotifyUri);
        }
    }

    if (duplicateUris.length > 0) {
        return {
            statusCode: 400,
            body: JSON.stringify({ message: 'Duplicate songs cannot be added', duplicateSpotifyUris: duplicateUris })
        };
    }

    return null;
}

async function getExistingUrisForPlaylist(playlistId) {
    const queryParams = {
        TableName: playlistsTable,
        KeyConditionExpression: 'PK = :pk and begins_with(SK, :sk)',
        ExpressionAttributeValues: {
            ':pk': `cp#${playlistId}`,
            ':sk': 'song#'
        }
    };

    try {
        const data = await ddbDocClient.send(new QueryCommand(queryParams));
        return data.Items.map(item => item.spotifyUri);
    } catch (err) {
        console.error('Error querying existing URIs:', err);
        throw new Error('Error querying existing URIs');
    }
}


async function prepareCollaboratorData(playlistId) {
    const collaboratorsData = await getCollaboratorsByPlaylistId(playlistId, playlistsTable);
    const { spotifyUsers, failedSpotifyUsers } = await prepareSpotifyAccounts(collaboratorsData.map(c => c.userId), usersTable, tokensTable);
    const spotifyUsersMap = new Map(spotifyUsers.map(user => [user.userId, user]));

    const { updatedUsers, failedUsers } = await syncPlaylists(playlistId, spotifyUsersMap, collaboratorsData, playlistsTable);
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

function buildTransactItems(playlistId, songs, timestamp) {
    let transactItems = [];

    transactItems.push({
        Update: {
            TableName: playlistsTable,
            Key: {
                PK: `cp#${playlistId}`,
                SK: 'metadata'
            },
            UpdateExpression: 'ADD #songCount :incr',
            ConditionExpression: '#songCount <= :maxSongs',
            ExpressionAttributeNames: {
                '#songCount': 'songCount'
            },
            ExpressionAttributeValues: {
                ':incr': songs.length,
                ':maxSongs': MAX_SONGS - songs.length
            },
            ReturnValuesOnConditionCheckFailure: 'ALL_OLD'
        }
    });

    songs.forEach(song => {
        const songId = uuidv4();
        transactItems.push({
            Put: {
                TableName: playlistsTable,
                Item: {
                    PK: `cp#${playlistId}`,
                    SK: `song#${songId}`,
                    ...song,
                    createdAt: timestamp
                }
            }
        });
    });

    return transactItems;
}

async function addSongsToSpotifyPlaylists(songs, collaboratorsData, spotifyUsersMap) {
    if (!collaboratorsData) return;
    let unsuccessfulUpdateUserIds = [];
    const collaboratorsSpotifyData = collaboratorsData.filter(collaborator => collaborator.spotifyPlaylistId);

    for (const collaborator of collaboratorsSpotifyData) {
        try {
            await addSongsToSpotifyPlaylist(collaborator.spotifyPlaylistId, spotifyUsersMap.get(collaborator.userId), songs, playlistsTable);
        } catch (error) {
            console.info('Unsuccessful Spotify Playlist update for user: ', collaborator.userId);
            unsuccessfulUpdateUserIds.push(collaborator.userId);
        }
    }

    return unsuccessfulUpdateUserIds;
}

async function rollbackPlaylistData(transactItems) {
    if (transactItems.length === 0) {
        console.info('No items to rollback.');
        return;
    }

    console.info('Rollback started');
    const rollbackOperations = transactItems.map(item => {
        if (item.Put) {
            return {
                Delete: {
                    TableName: item.Put.TableName,
                    Key: {
                        PK: item.Put.Item.PK,
                        SK: item.Put.Item.SK
                    }
                }
            };
        } else if (item.Update) {
            return {
                Update: {
                    TableName: item.Update.TableName,
                    Key: item.Update.Key,
                    UpdateExpression: 'ADD #songCount :decr',
                    ExpressionAttributeNames: item.Update.ExpressionAttributeNames,
                    ExpressionAttributeValues: {
                        ':decr': -item.Update.ExpressionAttributeValues[':incr']
                    }
                }
            };
        }
    });

    try {
        await ddbDocClient.send(new TransactWriteCommand({ TransactItems: rollbackOperations }));
        console.info('Rollback successful');
    } catch (error) {
        console.error('Error during cleanup:', error);
    }
}

function buildSuccessResponse(unsuccessfulUpdateUserIds) {
    let message = 'Songs added successfully';
    if (unsuccessfulUpdateUserIds.length > 0) {
        // Join user IDs with a comma and space for readability
        const failedUserIds = unsuccessfulUpdateUserIds.join(', ');
        message = `Songs added successfully except for the following user(s): ${failedUserIds}`;
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
            body: JSON.stringify({ message: `Failed to add songs, reached maximum limit of ${MAX_SONGS}.` })
        };
    }
    return {
        statusCode: 500,
        body: JSON.stringify({ message: 'Error adding songs to Collaborative Playlist' })
    };
}
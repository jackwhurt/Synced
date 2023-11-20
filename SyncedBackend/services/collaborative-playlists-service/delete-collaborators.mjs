import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, TransactWriteCommand, GetCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const playlistsTable = process.env.PLAYLISTS_TABLE;

export const deleteCollaboratorsHandler = async (event) => {
    console.info('received:', event);

    if (!event.body) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Missing body' }) };
    }

    const { playlistId, collaboratorIds } = JSON.parse(event.body);
    if (!playlistId || !collaboratorIds || collaboratorIds.length === 0) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Missing required fields' }) };
    }

    const claims = event.requestContext.authorizer?.claims;
    if (!claims) {
        return { statusCode: 401, body: JSON.stringify({ message: 'Unauthorised' }) };
    }

    const cognitoUserId = claims['sub'];

    // Retrieve playlist metadata
    const playlistMetadata = await getPlaylistMetadata(playlistId);
    if (!playlistMetadata) {
        return { statusCode: 404, body: JSON.stringify({ message: 'Playlist not found' }) };
    }

    // Check if the user is authorised to modify the playlist
    if (playlistMetadata.createdBy !== cognitoUserId) {
        return {
            statusCode: 403,
            body: JSON.stringify({ message: 'Not authorised to modify this playlist' })
        };
    }

    try {
        await deleteCollaborators(playlistId, collaboratorIds);

        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Collaborators deleted successfully',
                playlistId,
                collaboratorIds
            })
        };
    } catch (err) {
        console.error("Error", err);

        if (err.name === 'TransactionCanceledException') {
            return {
                statusCode: 400,
                body: JSON.stringify({ message: 'Invalid collaborator criteria' })
            };
        }

        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Error deleting collaborators' })
        };
    }
};

async function deleteCollaborators(playlistId, collaboratorIds) {
    const transactItems = [];

    // Decrement the counter and delete collaborators atomically
    transactItems.push({
        Update: {
            TableName: playlistsTable,
            Key: { PK: `cp#${playlistId}`, SK: 'metadata' },
            UpdateExpression: "ADD #collaboratorCount :decr",
            ExpressionAttributeNames: {
                "#collaboratorCount": "collaboratorCount",
            },
            ExpressionAttributeValues: {
                ":decr": -collaboratorIds.length
            },
            ReturnValuesOnConditionCheckFailure: "ALL_OLD"
        }
    });

    collaboratorIds.forEach(collaboratorId => {
        transactItems.push({
            Delete: {
                TableName: playlistsTable,
                Key: {
                    PK: `cp#${playlistId}`,
                    SK: `collaborator#${collaboratorId}`,
                }
            }
        });
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
        console.error("Error retrieving playlist metadata:", err);

        return null;
    }
}

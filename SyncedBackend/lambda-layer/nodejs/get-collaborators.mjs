import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand } from '@aws-sdk/lib-dynamodb';

const ddbDocClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));

// Accepted collaborators
export async function getCollaboratorsByPlaylistId(playlistId, playlistsTable) {
    const queryParams = {
        TableName: playlistsTable,
        KeyConditionExpression: 'PK = :pk and begins_with(SK, :sk)',
        FilterExpression: "#requestStatus = :acceptedStatus",
        ExpressionAttributeNames: {
            "#requestStatus": "requestStatus",
        },
        ExpressionAttributeValues: {
            ':pk': `cp#${playlistId}`,
            ':sk': 'collaborator#',
            ':acceptedStatus': 'accepted',
        }
    };    

    try {
        const data = await ddbDocClient.send(new QueryCommand(queryParams));
        const collaboratorsData = data.Items.map(collaborator => ({
                userId: collaborator.SK.replace('collaborator#', ''),
                spotifyPlaylistId: collaborator.spotifyPlaylistId,
                spotifyInSync: collaborator.spotifyInSync,
            }));
        return collaboratorsData;
    } catch (err) {
        console.error('Error getting collaborators:', err);
        throw err;
    }
}

export async function getCollaboratorsByPlaylistIdAndCollaboratorIds(playlistId, collaboratorIds, playlistsTable) {
    try {
        const collaboratorsData = [];
        for (const collaboratorId of collaboratorIds) {
            const queryParams = {
                TableName: playlistsTable,
                KeyConditionExpression: 'PK = :pk and SK = :sk',
                ExpressionAttributeValues: {
                    ':pk': `cp#${playlistId}`,
                    ':sk': `collaborator#${collaboratorId}`
                }
            };

            const data = await ddbDocClient.send(new QueryCommand(queryParams));

            if (data.Items.length > 0) {
                const collaborator = data.Items[0];
                collaboratorsData.push({
                    userId: collaboratorId,
                    spotifyPlaylistId: collaborator.spotifyPlaylistId,
                    spotifyInSync: collaborator.spotifyInSync
                });
            }
        }

        return collaboratorsData;
    } catch (err) {
        console.error('Error getting collaborators by IDs:', err);
        throw err;
    }
}
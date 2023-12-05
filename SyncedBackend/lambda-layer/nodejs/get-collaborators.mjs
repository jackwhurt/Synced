import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand } from '@aws-sdk/lib-dynamodb';

const ddbDocClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));

export async function getCollaboratorsByPlaylistId(playlistId, playlistsTable) {
    const queryParams = {
        TableName: playlistsTable,
        KeyConditionExpression: 'PK = :pk and begins_with(SK, :sk)',
        ExpressionAttributeValues: {
            ':pk': `cp#${playlistId}`,
            ':sk': 'collaborator#'
        }
    };

    try {
        const data = await ddbDocClient.send(new QueryCommand(queryParams));
        const collaboratorsData = data.Items
            .filter(collaborator => collaborator.spotifyPlaylistId)
            .map(collaborator => ({
                userId: collaborator.SK.replace('collaborator#', ''),
                spotifyPlaylistId: collaborator.spotifyPlaylistId
            }));
        return collaboratorsData;
    } catch (err) {
        console.error('Error getting collaborators:', err);
        throw err;
    }
}
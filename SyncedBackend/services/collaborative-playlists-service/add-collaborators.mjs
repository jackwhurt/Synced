import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, TransactWriteCommand, BatchGetCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const playlistsTable = process.env.PLAYLISTS_TABLE;
const usersTable = process.env.USERS_TABLE;
const MAX_COLLABORATORS = 10;

export const addCollaboratorsHandler = async (event) => {
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
        return { statusCode: 401, body: JSON.stringify({ message: 'Unauthorized' }) };
    }

    if (!await validateCollaborators(collaboratorIds)) {
        return { statusCode: 400, body: JSON.stringify({ message: 'Collaborator(s) not found' }) };
    }

    try {
        await addCollaborators(playlistId, collaboratorIds, claims['sub']);
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Collaborators added successfully',
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
            body: JSON.stringify({ message: 'Error adding collaborators' })
        };
    }
};

async function addCollaborators(playlistId, collaboratorIds, cognitoUserId) {
    const timestamp = new Date().toISOString();
    const transactItems = [];

    // Increment the counter and add new collaborators atomically
    transactItems.push({
        Update: {
            TableName: playlistsTable,
            Key: { PK: `cp#${playlistId}`, SK: 'metadata' },
            UpdateExpression: "ADD #collaboratorCount :incr",
            ConditionExpression: "#collaboratorCount < :maxCollaborators",
            ExpressionAttributeNames: {
                "#collaboratorCount": "collaboratorCount",
            },
            ExpressionAttributeValues: {
                ":incr": collaboratorIds.length,
                ":maxCollaborators": MAX_COLLABORATORS
            },
            ReturnValuesOnConditionCheckFailure: "ALL_OLD"
        }
    });

    collaboratorIds.forEach(collaboratorId => {
        transactItems.push({
            Put: {
                TableName: playlistsTable,
                Item: {
                    PK: `cp#${playlistId}`,
                    SK: `collaborator#${collaboratorId}`,
                    GSI1PK: `collaborator#${collaboratorId}`,
                    addedBy: cognitoUserId,
                    createdAt: timestamp,
                },
                ConditionExpression: "attribute_not_exists(PK) AND attribute_not_exists(SK)",
            }
        });
    });

    await ddbDocClient.send(new TransactWriteCommand({ TransactItems: transactItems }));
}

async function validateCollaborators(collaboratorIds) {
    const keysToGet = collaboratorIds.map(id => ({ cognito_user_id: id }));
    const params = {
        RequestItems: {
            [usersTable]: {
                Keys: keysToGet
            }
        }
    };

    try {
        const { Responses } = await ddbDocClient.send(new BatchGetCommand(params));
        const foundIds = Responses[usersTable].map(item => item.cognito_user_id);
        
        return collaboratorIds.every(id => foundIds.includes(id));
    } catch (err) {
        console.error('Error in BatchGetCommand:', err);
        
        return false;
    }
}
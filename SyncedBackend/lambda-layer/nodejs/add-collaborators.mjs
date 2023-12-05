import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, TransactWriteCommand, BatchGetCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const MAX_COLLABORATORS = 10;

export async function addCollaborators(playlistId, collaboratorIds, cognitoUserId, playlistsTable, usersTable) {
    const timestamp = new Date().toISOString();

    if (!await areValidCollaborators(collaboratorIds, usersTable)) {
        throw new Error('Collaborator(s) not found');
    }

    const transactItems = buildTransactItems(playlistId, collaboratorIds, cognitoUserId, playlistsTable, timestamp);

    try {
        await ddbDocClient.send(new TransactWriteCommand({ TransactItems: transactItems }));
    } catch (err) {
        console.error('Error in transaction:', err);
        throw new err;
    }
}

function buildTransactItems(playlistId, collaboratorIds, cognitoUserId, playlistsTable, timestamp) {
    const transactItems = [];

    // Increment the counter and add new collaborators atomically
    transactItems.push({
        Update: {
            TableName: playlistsTable,
            Key: { PK: `cp#${playlistId}`, SK: 'metadata' },
            UpdateExpression: 'ADD #collaboratorCount :incr',
            ConditionExpression: '#collaboratorCount < :maxCollaborators',
            ExpressionAttributeNames: {
                '#collaboratorCount': 'collaboratorCount'
            },
            ExpressionAttributeValues: {
                ':incr': collaboratorIds.length,
                ':maxCollaborators': MAX_COLLABORATORS - collaboratorIds.length
            },
            ReturnValuesOnConditionCheckFailure: 'ALL_OLD'
        }
    });

    for (let collaboratorId of collaboratorIds) {
        transactItems.push({
            Put: {
                TableName: playlistsTable,
                Item: {
                    PK: `cp#${playlistId}`,
                    SK: `collaborator#${collaboratorId}`,
                    GSI1PK: `collaborator#${collaboratorId}`,
                    addedBy: cognitoUserId,
                    createdAt: timestamp
                },
                ConditionExpression: 'attribute_not_exists(PK) AND attribute_not_exists(SK)'
            }
        });
    }

    return transactItems;
}

async function areValidCollaborators(collaboratorIds, usersTable) {
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
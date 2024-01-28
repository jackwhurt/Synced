import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, TransactWriteCommand, BatchGetCommand } from '@aws-sdk/lib-dynamodb';
import { v4 as uuidv4 } from 'uuid';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const MAX_COLLABORATORS = 10;

export async function addCollaborators(playlistId, collaboratorIds, cognitoUserId, playlistsTable, activitiesTable, usersTable) {
    const timestamp = new Date().toISOString();
    const usernames = await getCollaboratorsUsername(collaboratorIds, usersTable);
    const transactItems = buildTransactItems(playlistId, collaboratorIds, cognitoUserId, playlistsTable, activitiesTable, usernames, timestamp);

    try {
        await ddbDocClient.send(new TransactWriteCommand({ TransactItems: transactItems }));
    } catch (err) {
        console.error('Error in transaction:', err);
        throw new err;
    }
}

function buildTransactItems(playlistId, collaboratorIds, cognitoUserId, playlistsTable, activitiesTable, usernames, timestamp) {
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
                    requestStatus: 'pending',
                    createdAt: timestamp,
                    updatedAt: timestamp
                },
                ConditionExpression: 'attribute_not_exists(PK) AND attribute_not_exists(SK)'
            }
        });

        if (collaboratorId != cognitoUserId) {
            const username = usernames[cognitoUserId] || 'Unknown';
            transactItems.push({
                Put: {
                    TableName: activitiesTable,
                    Item: {
                        PK: collaboratorId,
                        SK: `requestPlaylist#${uuidv4()}`,
                        playlistId: playlistId,
                        createdByUsername: username,
                        createdBy: cognitoUserId,
                        createdAt: timestamp
                    }
                }
            });
        }
    }

    return transactItems;
}

async function getCollaboratorsUsername(collaboratorIds, usersTable) {
    const keysToGet = collaboratorIds.map(id => ({ userId: id }));
    const params = {
        RequestItems: {
            [usersTable]: {
                Keys: keysToGet
            }
        }
    };

    try {
        const { Responses } = await ddbDocClient.send(new BatchGetCommand(params));
        const usernames = Responses[usersTable].reduce((acc, item) => {
            acc[item.userId] = item.attributeValue;
            return acc;
        }, {});
        const isValid = collaboratorIds.every(id => usernames[id] !== undefined);
        if (!isValid) throw new Error('Collaborator(s) not found');

        return usernames;
    } catch (err) {
        console.error('Error retrieving collaborators usernames:', err);
        throw err;
    }
}

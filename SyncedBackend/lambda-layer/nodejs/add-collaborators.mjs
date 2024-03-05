import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, TransactWriteCommand, BatchGetCommand } from '@aws-sdk/lib-dynamodb';
import { sendApnsNotifications } from '/opt/nodejs/send-apns-notifications.mjs';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const MAX_COLLABORATORS = 10;

export async function addCollaborators(playlistId, playlistTitle, collaboratorIds, cognitoUserId, isNewPlaylist, playlistsTable, activitiesTable, usersTable, isDevEnvironment) {
    const timestamp = new Date().toISOString();
    const usernames = await getUsernames(collaboratorIds, usersTable);
    const transactItems = buildTransactItems(playlistId, collaboratorIds, cognitoUserId, usernames, timestamp, isNewPlaylist, playlistsTable, activitiesTable);
    const message = `@${usernames[cognitoUserId]} has requested you to join ${playlistTitle}!` 
    const userIdsWithoutCreator = collaboratorIds.filter(id => id != cognitoUserId);

    try {
        await ddbDocClient.send(new TransactWriteCommand({ TransactItems: transactItems }));
        await sendApnsNotifications(userIdsWithoutCreator, message, usersTable, isDevEnvironment);
    } catch (err) {
        console.error('Error in transaction:', err);
        throw err;
    }
}

function buildTransactItems(playlistId, collaboratorIds, cognitoUserId, usernames, timestamp, isNewPlaylist, playlistsTable, activitiesTable) {
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

    const username = usernames[cognitoUserId] || 'Unknown';
    for (let collaboratorId of collaboratorIds) {
        if (collaboratorId != cognitoUserId) {
            transactItems.push({
                Put: {
                    TableName: activitiesTable,
                    Item: {
                        PK: collaboratorId,
                        SK: `requestPlaylist#${playlistId}`,
                        playlistId: playlistId,
                        createdByUsername: username,
                        createdBy: cognitoUserId,
                        createdAt: timestamp
                    }
                }
            });
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
        } else if (isNewPlaylist) {
            transactItems.push({
                Put: {
                    TableName: playlistsTable,
                    Item: {
                        PK: `cp#${playlistId}`,
                        SK: `collaborator#${collaboratorId}`,
                        GSI1PK: `collaborator#${collaboratorId}`,
                        addedBy: cognitoUserId,
                        requestStatus: 'accepted',
                        createdAt: timestamp,
                        updatedAt: timestamp
                    },
                    ConditionExpression: 'attribute_not_exists(PK) AND attribute_not_exists(SK)'
                }
            });
        }
    }

    return transactItems;
}

async function getUsernames(collaboratorIds, usersTable) {
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

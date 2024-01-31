import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, TransactWriteCommand, GetCommand } from '@aws-sdk/lib-dynamodb';
import { v4 as uuidv4 } from 'uuid';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

export async function createNotifications(userIds, notificationMessage, createdByUserId, playlistId, activitiesTable, usersTable, playlistsTable) {
    const createdByUsername = await getUsername(createdByUserId, usersTable);
    const playlistTitle = await getPlaylistTitle(playlistId, playlistsTable);
    const notificationMessageWithUsernameAndTitle = notificationMessage.replace('{playlist}', playlistTitle).replace('{user}', createdByUsername);
    const transactItems = buildNotificationTransactItems(userIds, notificationMessageWithUsernameAndTitle, createdByUserId, playlistId, activitiesTable);

    try {
        await ddbDocClient.send(new TransactWriteCommand({ TransactItems: transactItems }));
        console.info('Successfully added notifications for: ', userIds);
    } catch (err) {
        console.error('Error writing notifications to db: ', err);
    }
}

async function getUsername(userId, usersTable) {
    const params = {
        TableName: usersTable,
        Key: { userId: userId }
    };

    try {
        const { Item } = await ddbDocClient.send(new GetCommand(params));
        const username = Item?.attributeValue || 'Unknown';
        return username;
    } catch (err) {
        console.error('Error retrieving username:', err);
        return 'User';
    }
}

async function getPlaylistTitle(playlistId, playlistsTable) {
    const params = {
        TableName: playlistsTable,
        Key: { PK: `cp#${playlistId}`, SK: 'metadata' }
    };

    try {
        const { Item } = await ddbDocClient.send(new GetCommand(params));
        const playlistTitle = Item?.title || 'Unknown Playlist';
        return playlistTitle;
    } catch (err) {
        console.error('Error retrieving playlist title:', err);
        return 'Playlist';
    }
}

function buildNotificationTransactItems(userIds, notificationMessageWithUsernameAndTitle, createdBy, playlistId, activitiesTable) {
    const transactItems = [];
    const timestamp = new Date().toISOString();

    for (let userId of userIds) {
        if (userId === createdBy) continue;
        transactItems.push({
            Put: {
                TableName: activitiesTable,
                Item: {
                    PK: userId,
                    SK: `notification#${uuidv4()}`,
                    message: notificationMessageWithUsernameAndTitle,
                    createdBy: createdBy,
                    createdAt: timestamp,
                    playlistId: playlistId
                }
            }
        });
    }

    return transactItems;
}

import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, TransactWriteCommand, GetCommand } from '@aws-sdk/lib-dynamodb';
import { sendApnsNotifications } from '/opt/nodejs/send-apns-notifications.mjs';
import { v4 as uuidv4 } from 'uuid';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

export async function createNotifications(userIdsToSendNotifs, notificationMessage, userId,
    playlistId, activitiesTable, usersTable, playlistsTable, isDevEnvironment) {
    if (notificationMessage.includes('{user}')) {
        const createdByUsername = await getUsername(userId, usersTable);
        notificationMessage = notificationMessage.replace('{user}', createdByUsername);
    }
    if (notificationMessage.includes('{playlist}')) {
        const playlistTitle = await getPlaylistTitle(playlistId, playlistsTable);
        notificationMessage = notificationMessage.replace('{playlist}', playlistTitle)
    }
    const transactItems = buildNotificationTransactItems(userIdsToSendNotifs, notificationMessage, userId, playlistId, activitiesTable);

    try {
        await ddbDocClient.send(new TransactWriteCommand({ TransactItems: transactItems }));
        await sendApnsNotifications(userIdsToSendNotifs, notificationMessage, usersTable, isDevEnvironment);
        console.info('Successfully added notifications for: ', userIdsToSendNotifs);
    } catch (err) {
        console.error('Error creating notifications: ', err);
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

function buildNotificationTransactItems(userIds, notificationMessage, createdBy, playlistId, activitiesTable) {
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
                    message: notificationMessage,
                    createdBy: createdBy,
                    createdAt: timestamp,
                    playlistId: playlistId
                }
            }
        });
    }

    return transactItems;
}

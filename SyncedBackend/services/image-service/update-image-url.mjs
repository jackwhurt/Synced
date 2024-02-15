import { DynamoDBDocumentClient, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { SQSClient, SendMessageCommand } from '@aws-sdk/client-sqs';

const sqsClient = new SQSClient({});
const ddbClient = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(ddbClient);

const playlistsTable = process.env.PLAYLISTS_TABLE;
const usersTable = process.env.USERS_TABLE;
const deleteQueueUrl = process.env.DELETE_QUEUE_URL;

// TODO: Send failed updates to the queue also
export const updateImageUrlHandler = async (event) => {
    console.info('Received S3 event:', event);

    try {
        const { entityId, entityType, photoUrl } = extractInfoFromEvent(event);
        const updateResult = await updateDatabase(entityId, entityType, photoUrl);

        if (updateResult.oldPhotoUrl) {
            await sendImageUrlToQueue(currentImageUrl);
        }

        console.info('Update result:', updateResult);

        return createResponse(200, { message: 'Successfully updated database', ...updateResult });
    } catch (error) {
        console.error('Error:', error);
        return createResponse(error.statusCode || 500, { error: error.message || 'An unknown error occurred' });
    }
};

function extractInfoFromEvent(event) {
    const bucketName = event.detail.bucket.name;
    const objectKey = decodeURIComponent(event.detail.object.key.replace(/\+/g, ' '));
    const photoUrl = `https://${bucketName}.s3.amazonaws.com/${objectKey}`;
    const keyParts = objectKey.split('/');
    const entityType = keyParts[1]; // 'user' or 'playlist'
    const imageName = keyParts[2]
    const entityId = imageName.split('.')[0];

    return { entityId, entityType, photoUrl };
}

async function sendImageUrlToQueue(imageUrl) {
    const params = {
        QueueUrl: deleteQueueUrl, 
        MessageBody: JSON.stringify({
            imageUrl: imageUrl,
        }),
    };

    try {
        const result = await sqsClient.send(new SendMessageCommand(params));
        console.info('Successfully sent message to SQS:', result);
    } catch (error) {
        console.error('Failed to send message to SQS:', error);
    }
}

async function updateDatabase(entityId, entityType, photoUrl) {
    let params;
    let oldPhotoUrl;

    if (entityType === 'user') {
        params = {
            TableName: usersTable,
            Key: { userId: entityId },
            UpdateExpression: 'SET photoUrl = :newPhotoUrl, updatedAt = :updatedAt',
            ExpressionAttributeValues: {
                ':newPhotoUrl': photoUrl,
                ':updatedAt': new Date().toISOString(),
            },
            ReturnValues: "UPDATED_OLD" 
        };
    } else if (entityType === 'playlist') {
        params = {
            TableName: playlistsTable,
            Key: { 
                PK: `cp#${entityId}`, 
                SK: 'metadata',
            },
            UpdateExpression: 'SET coverImageUrl = :newCoverImageUrl, updatedAt = :updatedAt',
            ExpressionAttributeValues: {
                ':newCoverImageUrl': photoUrl,
                ':updatedAt': new Date().toISOString(),
            },
            ReturnValues: "UPDATED_OLD"
        };
    }

    try {
        const response = await ddbDocClient.send(new UpdateCommand(params));
        oldPhotoUrl = entityType === 'user' ? response.Attributes.photoUrl : response.Attributes.coverImageUrl;
    } catch (error) {
        console.error(`Error updating database for ${entityType} with ID ${entityId}:`, error);
        throw error; 
    }
    return { entityId, entityType, newPhotoUrl: photoUrl, oldPhotoUrl };
}


function createResponse(statusCode, body) {
    return {
        statusCode: statusCode,
        body: JSON.stringify(body),
    };
}

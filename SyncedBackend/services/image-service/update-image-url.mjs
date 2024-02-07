import { DynamoDBDocumentClient, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';

const ddbClient = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(ddbClient);

const playlistsTable = process.env.PLAYLISTS_TABLE;
const usersTable = process.env.USERS_TABLE;

export const updateImageUrlHandler = async (event) => {
    console.info('Received S3 event:', event);

    try {
        const { entityId, entityType, photoUrl } = extractInfoFromEvent(event);
        
        const updateResult = await updateDatabase(entityId, entityType, photoUrl);
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


async function updateDatabase(entityId, entityType, photoUrl) {
    let params;
    if (entityType === 'user') {
        params = {
            TableName: usersTable,
            Key: { userId: entityId }, 
            UpdateExpression: 'SET photoUrl = :photoUrl, updatedAt = :updatedAt',
            ExpressionAttributeValues: {
                ':photoUrl': photoUrl,
                ':updatedAt': new Date().toISOString(),
            },
        };
    } else if (entityType === 'playlist') {
        params = {
            TableName: playlistsTable,
            Key: { 
                PK: `cp#${entityId}`, 
                SK: 'metadata',
            },
            UpdateExpression: 'SET coverImageUrl = :coverImageUrl, updatedAt = :updatedAt',
            ExpressionAttributeValues: {
                ':coverImageUrl': photoUrl,
                ':updatedAt': new Date().toISOString(),
            },
        };
    } else {
        throw new Error(`Unrecognized entity type: ${entityType}`);
    }

    await ddbDocClient.send(new UpdateCommand(params));

    return { entityId, entityType, photoUrl };
}


function createResponse(statusCode, body) {
    return {
        statusCode: statusCode,
        body: JSON.stringify(body),
    };
}

import { DynamoDBDocumentClient, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';

const ddbClient = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(ddbClient);

const playlistsTable = process.env.PLAYLISTS_TABLE;
const usersTable = process.env.USERS_TABLE;

export const s3TriggeredUpdateHandler = async (event) => {
    console.info('Received S3 event:', event);

    try {
        const { entityId, entityType, photoURL } = extractInfoFromEvent(event);
        
        const updateResult = await updateDatabase(entityId, entityType, photoURL);
        console.info('Update result:', updateResult);

        return createResponse(200, { message: 'Successfully updated database', ...updateResult });
    } catch (error) {
        console.error('Error:', error);
        return createResponse(error.statusCode || 500, { error: error.message || 'An unknown error occurred' });
    }
};

function extractInfoFromEvent(event) {
    const record = event.Records[0].s3;
    const objectKey = decodeURIComponent(record.object.key.replace(/\+/g, ' '));
    const bucketName = record.bucket.name;
    const photoURL = `https://${bucketName}.s3.amazonaws.com/${objectKey}`;

    const keyParts = objectKey.split('/');
    const entityType = keyParts[1]; // 'user' or 'playlist'
    const entityId = keyParts[2];

    return { entityId, entityType, photoURL };
}

async function updateDatabase(entityId, entityType, photoURL) {
    let params;
    if (entityType === 'user') {
        params = {
            TableName: usersTable,
            Key: { userId: entityId }, 
            UpdateExpression: 'SET photoURL = :photoURL, updatedAt = :updatedAt',
            ExpressionAttributeValues: {
                ':photoURL': photoURL,
                ':updatedAt': new Date().toISOString(),
            },
        };
    } else if (entityType === 'playlist') {
        params = {
            TableName: playlistsTable,
            Key: { 
                PK: `playlist#${entityId}`, 
                SK: 'metadata',
            },
            UpdateExpression: 'SET photoURL = :photoURL, updatedAt = :updatedAt',
            ExpressionAttributeValues: {
                ':photoURL': photoURL,
                ':updatedAt': new Date().toISOString(),
            },
        };
    } else {
        throw new Error(`Unrecognized entity type: ${entityType}`);
    }

    await ddbDocClient.send(new UpdateCommand(params));
    
    return { entityId, entityType, photoURL };
}


function createResponse(statusCode, body) {
    return {
        statusCode: statusCode,
        body: JSON.stringify(body),
    };
}

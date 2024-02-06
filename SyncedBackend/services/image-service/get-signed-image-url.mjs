import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { DynamoDBClient, GetItemCommand } from "@aws-sdk/client-dynamodb";
import { v4 as uuidv4 } from 'uuid';

const s3Client = new S3Client({});
const ddbClient = new DynamoDBClient({});
const bucketName = process.env.BUCKET_NAME;
const playlistsTable = process.env.PLAYLISTS_TABLE;
const usersTable = process.env.USERS_TABLE;

export const getSignedImageUrlHandler = async (event) => {
    console.info('received:', event);

    const { userId, playlistId, fileType } = JSON.parse(event.body);
    if (!fileType) return createErrorResponse({ statusCode: 400, message: 'Missing required fileType' });

    if (userId && !(await checkIfExists(usersTable, { userId: { S: userId } }))) {
        return createErrorResponse({ statusCode: 404, message: 'User does not exist' });
    }

    if (playlistId && !(await checkIfExists(playlistsTable, { PK: { S: `cp#${playlistId}` }, SK: { S: 'metadata' } }))) {
        return createErrorResponse({ statusCode: 404, message: 'Playlist does not exist' });
    }

    const fileExtension = fileType.toLowerCase();
    const objectKey = generateObjectKey(userId, playlistId, fileExtension);
    const contentType = getContentType(fileType);

    try {
        const url = await generateSignedUrl(bucketName, objectKey, contentType);
        return createSuccessResponse(200, { uploadUrl: url, objectKey });
    } catch (error) {
        return createErrorResponse(error);
    }
};

async function checkIfExists(tableName, key) {
    try {
        const { Item } = await ddbClient.send(new GetItemCommand({ TableName: tableName, Key: key }));
        return !!Item;
    } catch (error) {
        console.error(`Error checking existence in ${tableName}:`, error);
        return false;
    }
}

function generateObjectKey(userId, playlistId, fileExtension) {
    const uuid = uuidv4();
    if (userId) return `images/user/${userId}/${uuid}.${fileExtension}`;
    if (playlistId) return `images/playlist/${playlistId}/${uuid}.${fileExtension}`;
}

async function generateSignedUrl(bucket, key, contentType) {
    const command = new PutObjectCommand({
        Bucket: bucket,
        Key: key,
        ContentType: contentType,
    });
    return getSignedUrl(s3Client, command, { expiresIn: 300 });
}

function getContentType(fileType) {
    const contentTypeMap = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'gif': 'image/gif',
        'heic': 'image/heic',
    };
    return contentTypeMap[fileType.toLowerCase()] || 'application/octet-stream';
}

function createSuccessResponse(statusCode, body) {
    console.info('returned: ', body);

    return {
        statusCode,
        body: JSON.stringify(body),
    };
}

function createErrorResponse(error) {
    console.error('Error generating pre-signed URL:', error);

    return {
        statusCode: error.statusCode || 500,
        body: JSON.stringify({
            error: error.message || 'An unknown error occurred',
        }),
    };
}

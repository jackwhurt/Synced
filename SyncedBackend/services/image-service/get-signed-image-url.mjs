import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { v4 as uuidv4 } from 'uuid';

const s3Client = new S3Client({});
const bucketArn = process.env.BUCKET_ARN;

export const getSignedImageUrlHandler = async (event) => {
    console.info('received:', event);

    const { userId, playlistId, fileType } = JSON.parse(event.body);

    const bucketName = getBucketNameFromArn(bucketArn);
    const fileExtension = fileType.toLowerCase();
    let objectKey;

    if (playlistId) {
        objectKey = `images/playlist/${playlistId}/${uuidv4()}.${fileExtension}`;
    } else if (userId) {
        objectKey = `images/user/${userId}/${uuidv4()}.${fileExtension}`;
    } else {
        return createErrorResponse({ statusCode: 400, message: 'Missing required userId or playlistId' });
    }

    const contentType = getContentType(fileType);

    try {
        const command = new PutObjectCommand({
            Bucket: bucketName,
            Key: objectKey,
            ContentType: contentType,
        });

        const url = await getSignedUrl(s3Client, command, { expiresIn: 300 });

        return createSuccessResponse(200, { uploadUrl: url, objectKey });
    } catch (error) {
        console.error('Error generating pre-signed URL:', error);
        return createErrorResponse(error);
    }
};

function getBucketNameFromArn() {
    const parts = bucketArn.split(':');
    return parts[5].split('/')[1];
}

function getContentType(fileType) {
    const contentTypeMap = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'gif': 'image/gif',
        'heic': 'image/heic', 
    };
    
    return contentTypeMap[fileType.toLowerCase()] || 'application/octet-stream'; // Fallback MIME type
}

function createSuccessResponse(statusCode, body) {
    return {
        statusCode,
        body: JSON.stringify(body),
    };
}

function createErrorResponse(error) {
    return {
        statusCode: error.statusCode || 500,
        body: JSON.stringify({
            error: error.message || 'An unknown error occurred',
        }),
    };
}

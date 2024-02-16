import { S3Client, DeleteObjectCommand } from "@aws-sdk/client-s3";

const s3Client = new S3Client({});

export async function deleteS3ObjectByUrl(imageUrl) {
    const { bucketName, imageKey } = parseImageUrl(imageUrl);
    const command = new DeleteObjectCommand({
        Bucket: bucketName,
        Key: imageKey,
    });
    await s3Client.send(command);
    console.info(`Image deleted: ${bucketName}/${imageKey}`);
}

export function parseImageUrl(imageUrl) {
    const myURL = new URL(imageUrl);
    const bucketName = myURL.hostname.split('.')[0];
    const imageKey = myURL.pathname.substring(1);
    return { bucketName, imageKey };
}
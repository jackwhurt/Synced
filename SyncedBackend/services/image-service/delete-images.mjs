import { SQSClient, ReceiveMessageCommand, DeleteMessageCommand } from "@aws-sdk/client-sqs";
import { S3Client, DeleteObjectCommand } from "@aws-sdk/client-s3";

const s3Client = new S3Client({});
const sqsClient = new SQSClient({});

const deleteQueueUrl = process.env.DELETE_QUEUE_URL;

export const deleteImagesHandler = async () => {
    let count = 0;

    try {
        let continueProcessing = true;

        while (continueProcessing) {
            const messages = await receiveMessagesFromQueue();
            console.info('received:', messages);
            count += messages.length;
            if (messages.length === 0) {
                continueProcessing = false;
            } else {
                for (const message of messages) {
                    await processAndDeleteMessage(message);
                }
            }
        }
    } catch (error) {
        console.error('Failed to delete images', error);
        return createErrorResponse({ statusCode: 500, message: 'Failed to process delete image requests' });
    }

    console.info(`Finished deleting ${count} images`);
};

async function receiveMessagesFromQueue() {
    const command = new ReceiveMessageCommand({
        QueueUrl: deleteQueueUrl,
        MaxNumberOfMessages: 10,
        WaitTimeSeconds: 10,
    });
    const { Messages } = await sqsClient.send(command);
    return Messages || [];
}

async function processAndDeleteMessage(message) {
    try {
        const body = JSON.parse(message.Body);
        const { imageUrl } = body;
        const { bucketName, imageKey } = parseImageUrl(imageUrl);
        await deleteImage(bucketName, imageKey);
        console.info(`Deleted image for url ${imageUrl}`);
        await deleteMessageFromQueue(deleteQueueUrl, message.ReceiptHandle);
    } catch (error) {
        console.error(`Error processing message: ${message.MessageId}`, error);
    }
}

function parseImageUrl(imageUrl) {
    const myURL = new URL(imageUrl);
    const bucketName = myURL.hostname.split('.')[0];
    const imageKey = myURL.pathname.substring(1);
    return { bucketName, imageKey };
}

async function deleteImage(bucketName, imageKey) {
    const command = new DeleteObjectCommand({
        Bucket: bucketName,
        Key: imageKey,
    });
    await s3Client.send(command);
    console.info(`Image deleted: ${imageKey}`);
}

async function deleteMessageFromQueue(queueUrl, receiptHandle) {
    const command = new DeleteMessageCommand({
        QueueUrl: queueUrl,
        ReceiptHandle: receiptHandle,
    });
    await sqsClient.send(command);
}

function createErrorResponse(error) {
    console.error('Error:', error);
    return {
        statusCode: error.statusCode || 500,
        body: JSON.stringify({
            error: error.message || 'An unknown error occurred',
        }),
    };
}
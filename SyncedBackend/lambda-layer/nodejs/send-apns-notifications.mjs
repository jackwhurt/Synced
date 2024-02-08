import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, BatchGetCommand } from '@aws-sdk/lib-dynamodb';
import { SNSClient, PublishCommand } from '@aws-sdk/client-sns';

const dynamoDBClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const snsClient = new SNSClient({});

export async function sendApnsNotifications(userIds, notificationMessage, usersTable, isDevEnvironment) {
  const endpointArns = await getEndpointArns(userIds, usersTable, isDevEnvironment);

  for (const arn of endpointArns) {
    try {
      await sendApnsMessage(arn, notificationMessage, isDevEnvironment);
    } catch (err) {
      console.error(`Error sending APNS message to device token ${arn}:`, err);
    }
  }

  console.info('Successfully sent notifications to ', userIds);
}

async function getEndpointArns(userIds, usersTable, isDevEnvironment) {
  if (userIds.length == 0) return [];
  const attributeName = isDevEnvironment ? 'endpointArnDev' : 'endpointArn';

  const keys = userIds.map(id => ({ userId: id }));
  const batchGetParams = {
    RequestItems: {
      [usersTable]: {
        Keys: keys,
        ProjectionExpression: attributeName,
      },
    },
  };
  const { Responses } = await dynamoDBClient.send(new BatchGetCommand(batchGetParams));

  return Responses[usersTable].filter(item => item[attributeName]).map(item => item[attributeName]);
}

async function sendApnsMessage(endpointArn, message, isDevEnvironment) {
  const environment = isDevEnvironment ? 'APNS_SANDBOX' : 'APNS';

  const publishParams = {
    Message: JSON.stringify({
      default: message, 
      [environment]: JSON.stringify({
        aps: {
          alert: message,
          sound: 'default'
        }
      })
    }),
    MessageStructure: 'json',
    TargetArn: endpointArn,
  };
  
  await snsClient.send(new PublishCommand(publishParams));
}

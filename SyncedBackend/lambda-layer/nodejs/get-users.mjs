import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, BatchGetCommand } from '@aws-sdk/lib-dynamodb';

const ddbDocClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));

export async function getUsers(userIds, usersTable) {
    if (userIds.length === 0) return [];

    const params = {
        RequestItems: {
            [usersTable]: {
                Keys: userIds.map(userId => ({ userId }))
            }
        }
    };

    try {
        const usersData = await ddbDocClient.send(new BatchGetCommand(params));
        const transformedUsersData = usersData.Responses[usersTable].map(user => ({
            ...user,
            username: user.attributeValue,
        })).map(({userAttribute, attributeValue, ...rest}) => rest);

        return transformedUsersData || [];
    } catch (err) {
        console.error('Failed to get users data', err);
        throw new Error('Failed to fetch user data');
    }
}
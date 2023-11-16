// import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
// import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb';

// // Create a DocumentClient that represents the query to put an item
// const client = new DynamoDBClient({});
// const ddbDocClient = DynamoDBDocumentClient.from(client);

// // Get the DynamoDB table name from environment variables
// const tableName = process.env.COLLABORATIVE_PLAYLISTS_TABLE;

// export const handler = async (event) => {
//     console.info('received:', event);

//     const { cognitoUserId, playlistName, description, collaborators, songs } = JSON.parse(event.body);
//     const timestamp = new Date().toISOString(); // ISO 8601 format timestamp

//     // Generate a unique playlist ID
//     const playlistId = uuidv4();

//     // Start building the transaction
//     const transactItems = [];

//     // Add the playlist item with a timestamp
//     transactItems.push({
//         Put: {
//             TableName: tableName,
//             Item: {
//                 PK: `cp#${playlistId}`,
//                 SK: `metadata`,
//                 cognitoUserId,
//                 playlistName,
//                 description,
//                 playlistId,
//                 createdAt: timestamp,
//                 updatedAt: timestamp,
//                 // ... other playlist metadata attributes
//             }
//         }
//     });

//     // Add each song item with a timestamp
//     songs.forEach((song) => {
//         const songId = uuidv4();
//         transactItems.push({
//             Put: {
//                 TableName: tableName,
//                 Item: {
//                     PK: `cp#${playlistId}`,
//                     SK: `song#${songId}`,
//                     ...song, // Spread the song object assuming it has the necessary attributes
//                     createdAt: timestamp,
//                     updatedAt: timestamp,
//                 }
//             }
//         });
//     });

//     // Add each collaborator item with a timestamp
//     collaborators.forEach((collaboratorUserId) => {
//         transactItems.push({
//             Put: {
//                 TableName: tableName,
//                 Item: {
//                     PK: `cp#${playlistId}`,
//                     SK: `collaborator#${collaboratorUserId}`,
//                     addedBy: cognitoUserId,
//                     cognito_user_id:
//                     createdAt: timestamp,
//                     updatedAt: timestamp,
//                     // ... other collaborator attributes
//                 }
//             }
//         });
//     });

//     // Execute the transaction
//     try {
//         await ddbDocClient.send(new TransactWriteCommand({ TransactItems: transactItems }));
//         return {
//             statusCode: 200,
//             body: JSON.stringify({ playlistId, playlistName, description, collaborators, songs, createdAt: timestamp, updatedAt: timestamp })
//         };
//     } catch (err) {
//         console.error("Error", err);
//         return {
//             statusCode: 500,
//             body: JSON.stringify({ message: 'Error creating the collaborative playlist with songs and collaborators' })
//         };
//     }
// };

# Synced: An Integrated Platform for Cross-Platform Music Streaming Service Functionality

Synced is an iOS application that facilitates music sharing and collaboration among Apple Music and Spotify users, whilst also being accessible to those without them. It is built upon a scalable, cost efficient and secure infrastructure, with the objective of supporting a substantial user base.

## Getting Started

The front-end of Synced provides all the things needed in order to use the existing Development and Production environment, so deploying the back-end is not necessary. Here's a step-by-step guide to help you through the process. If you have any issues, please don't hesitate to contact me.

### Prerequisites

- macOS Catalina or later
- Xcode installed
- Cocoapods installed

### Setup

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/jackwhurt/Synced.git
   cd Synced
   ```

2. **Install Frontend Dependencies:**
   ```bash
   cd SyncedFrontend
   pod install
   ```

3. **Open in Xcode:**
   Open the SyncedFrontend.xcworkspace file in Xcode

4. **Run:**
   Build and run the app in Xcode:
    - Select a target device or simulator.
    - Click the "Run" button or press Cmd + R.

### Backend Prerequisites (Optional)

- An AWS account
- AWS CLI installed and configured
- Appropriate IAM permissions to create CloudFormation stacks and the infrastructure included (API Gateway, Cognito, DynamoDB, EventBridge, Lambda, S3, SNS, SQS)

### Backend Setup (Optional)

1. **Navigate to the Backend Directory:**
    From the root folder,
   ```bash
   cd SyncedBackend
   ```

2. **Deploy the Cloudformation Stack:**
   ```bash
   aws cloudformation deploy --template-file template-export.yml --stack-name synced-dev --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND
   ```

3. **Clean Up:**
   ```bash
   aws cloudformation delete-stack --stack-name synced-dev
   ```

### Post-Deployment Configuration
After deploying your CloudFormation stack, you'll need to manually set several variables in the AWS Systems Manager Parameter Store. These variables are crucial for the operation of your backend and include credentials and identifiers for various services:

- apnsPlatformArn: The ARN for the APNs platform application.
- apnsPlatformArnDev: The ARN for the APNs platform application in the development environment.
- appleMusicKeyId: The key ID for Apple Music API.
- appleMusicPrivateKey: The private key for Apple Music API.
- appleMusicTeamId: The team ID for Apple Music API.
- emailAddress: The email address used for sending notifications or communications.
- spotifyClientId: The client ID for Spotify API.
- spotifyClientSecret: The client secret for Spotify API.

To integrate the backend setup with the front-end application, update the environment variables in the Debug.xcconfig file located within Synced/SyncedFrontend/SyncedFrontend/ to match your backend configurations.

**Important**: Ensure you store these values securely and only provide access to them as necessary to maintain the security of your backend infrastructure.

**Note:** The APNs infrastructure setup is not included in the CloudFormation template. You will need to follow additional steps to configure APNs for your application.

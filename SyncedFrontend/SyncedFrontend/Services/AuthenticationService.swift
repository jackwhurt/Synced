import AWSCognitoIdentityProvider

class AuthenticationService {
    private var userPool: AWSCognitoIdentityUserPool?

    init() {
        // Initialize the AWS service configuration and user pool configuration
        let serviceConfiguration = AWSServiceConfiguration(region: .EUWest2, credentialsProvider: nil)
        let userPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: ProcessInfo.processInfo.environment["COGNITO_CLIENT_ID"] ?? "", clientSecret: nil, poolId: ProcessInfo.processInfo.environment["COGNITO_POOL_ID"] ?? "")
        
        AWSCognitoIdentityUserPool.register(with: serviceConfiguration, userPoolConfiguration: userPoolConfiguration, forKey: "UserPool")
        
        // Then, retrieve the user pool with the key used during registration
        self.userPool = AWSCognitoIdentityUserPool(forKey: "UserPool")
    }

    func loginUser(username: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Ensure that userPool is initialized
        guard let userPool = userPool else {
            completion(.failure(NSError(domain: "UserPoolError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User pool is not initialized"])))
            return
        }

        let user = userPool.getUser(username)
        user.getSession(username, password: password, validationData: nil).continueWith { task -> Any? in
            DispatchQueue.main.async {
                if let error = task.error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
            return nil
        }
    }

    func signUpUser(email: String, password: String, completion: @escaping (Result<AWSCognitoIdentityUserPoolSignUpResponse, Error>) -> Void) {
        // Ensure that userPool is initialized
        guard let userPool = userPool else {
            completion(.failure(NSError(domain: "UserPoolError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User pool is not initialized"])))
            return
        }

        var attributes = [AWSCognitoIdentityUserAttributeType]()

        // Add email attribute
        let emailAttribute = AWSCognitoIdentityUserAttributeType()
        emailAttribute?.name = "email"
        emailAttribute?.value = email
        attributes.append(emailAttribute!)

        // Perform the signup operation using email as the username
        userPool.signUp(email, password: password, userAttributes: attributes, validationData: nil).continueWith { task -> Any? in
            DispatchQueue.main.async {
                if let error = task.error {
                    completion(.failure(error))
                } else if let result = task.result {
                    completion(.success(result))
                }
            }
            return nil
        }
    }
}

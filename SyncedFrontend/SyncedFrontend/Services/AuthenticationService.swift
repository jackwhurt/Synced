import AWSCognitoIdentityProvider

class AuthenticationService {
    private let userPool: AWSCognitoIdentityUserPool

    init?() {
        // Configuration setup
        guard let clientId = ProcessInfo.processInfo.environment["COGNITO_CLIENT_ID"],
              let poolId = ProcessInfo.processInfo.environment["COGNITO_POOL_ID"] else {
            print("Environment variables for Cognito not set")
            return nil
        }

        let serviceConfiguration = AWSServiceConfiguration(region: .EUWest2, credentialsProvider: nil)
        let userPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: clientId, clientSecret: nil, poolId: poolId)

        AWSCognitoIdentityUserPool.register(with: serviceConfiguration, userPoolConfiguration: userPoolConfiguration, forKey: "UserPool")

        guard let userPool = AWSCognitoIdentityUserPool(forKey: "UserPool") else {
            print("Failed to initialize user pool")
            return nil
        }

        self.userPool = userPool
    }

    func loginUser(username: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let user = userPool.getUser(username)
        user.getSession(username, password: password, validationData: nil).continueWith { [weak self] task -> Any? in
            guard self != nil else { return nil }
            DispatchQueue.main.async {
                if let error = task.error {
                    completion(.failure(error))
                } else if let result = task.result {
                    // Extracting token strings from the session object
                    if let accessToken = result.accessToken?.tokenString,
                    let refreshToken = result.refreshToken?.tokenString {
                        self?.saveTokens(accessToken: accessToken, refreshToken: refreshToken)
                        completion(.success(()))
                    } else {
                        completion(.failure(NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve tokens"])))
                    }
                }
            }
            return nil
        }
    }
    
    func logoutUser(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = userPool.currentUser() else {
            completion(.failure(NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user found"])))
            return
        }

        user.signOut()

        // Clear tokens from Keychain
        let accessTokenDeleted = KeychainService.shared.delete(key: "accessToken")
        let refreshTokenDeleted = KeychainService.shared.delete(key: "refreshToken")

        if accessTokenDeleted && refreshTokenDeleted {
            completion(.success(()))
        } else {
            completion(.failure(NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to clear tokens"])))
        }
    }

    func signUpUser(email: String, password: String, completion: @escaping (Result<AWSCognitoIdentityUserPoolSignUpResponse, Error>) -> Void) {
        let emailAttribute = AWSCognitoIdentityUserAttributeType(name: "email", value: email)
        userPool.signUp(email, password: password, userAttributes: [emailAttribute], validationData: nil).continueWith { [weak self] task -> Any? in
            guard self != nil else { return nil }
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
    
    func saveTokens(accessToken: String, refreshToken: String) {
        if let accessTokenData = accessToken.data(using: .utf8),
           let refreshTokenData = refreshToken.data(using: .utf8) {
            let _ = KeychainService.shared.save(key: "accessToken", data: accessTokenData)
            let _ = KeychainService.shared.save(key: "refreshToken", data: refreshTokenData)
        }
    }
    
    func loadRefreshToken() -> String? {
        if let refreshTokenData = KeychainService.shared.load(key: "refreshToken") {
            return String(data: refreshTokenData, encoding: .utf8)
        }
        return nil
    }
    
    func refreshToken(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let refreshToken = loadRefreshToken(),
              let user = userPool.currentUser() else {
            completion(.failure(NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user or refresh token found"])))
            return
        }

        user.getSession().continueWith { [weak self] (task: AWSTask<AWSCognitoIdentityUserSession>) -> Any? in
            DispatchQueue.main.async {
                if let error = task.error {
                    completion(.failure(error))
                } else if let result = task.result {
                    if let newAccessToken = result.accessToken?.tokenString,
                       let newRefreshToken = result.refreshToken?.tokenString {
                        self?.saveTokens(accessToken: newAccessToken, refreshToken: newRefreshToken)
                        completion(.success(()))
                    } else {
                        completion(.failure(NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve new tokens"])))
                    }
                }
            }
            return nil
        }
    }
    
    func checkSession(completion: @escaping (Bool) -> Void) {
        refreshToken { result in
            switch result {
            case .success:
                completion(true)
            case .failure:
                completion(false)
            }
        }
    }
}

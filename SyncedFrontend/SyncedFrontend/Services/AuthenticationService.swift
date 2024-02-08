import AWSCognitoIdentityProvider

class AuthenticationService: AuthenticationServiceProtocol {
    private let userPool: AWSCognitoIdentityUserPool
    private let keychainService: KeychainService

    init(keychainService: KeychainService) throws {
        self.keychainService = keychainService

        guard let clientId = Bundle.main.object(forInfoDictionaryKey: "COGNITO_CLIENT_ID") as? String,
              let poolId = Bundle.main.object(forInfoDictionaryKey: "COGNITO_POOL_ID") as? String else {
            throw AuthenticationServiceError.cognitoIdsNotSet
        }

        let serviceConfiguration = AWSServiceConfiguration(region: .EUWest2, credentialsProvider: nil)
        let userPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: clientId, clientSecret: nil, poolId: poolId)

        AWSCognitoIdentityUserPool.register(with: serviceConfiguration, userPoolConfiguration: userPoolConfiguration, forKey: "UserPool")

        guard let userPool = AWSCognitoIdentityUserPool(forKey: "UserPool") else {
            throw AuthenticationServiceError.cognitoUserPoolFailedToInitialise
        }

        self.userPool = userPool
    }

    func loginUser(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let user = userPool.getUser(email)
        user.getSession(email, password: password, validationData: nil).continueWith { [weak self] task -> Any? in
            guard let self = self else { return nil }
            DispatchQueue.main.async {
                if let error = task.error {
                    completion(.failure(error))
                } else if let result = task.result {
                    do {
                        // Extracting token strings from the session object
                        if let accessToken = result.accessToken?.tokenString,
                           let idToken = result.idToken?.tokenString,
                           let refreshToken = result.refreshToken?.tokenString {
                            try self.saveTokens(accessToken: accessToken, idToken: idToken, refreshToken: refreshToken)
                            completion(.success(()))
                        } else {
                            completion(.failure(AuthenticationServiceError.failedToLogin))
                        }
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
            return nil
        }
    }

    func logoutUser(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = userPool.currentUser() else {
            completion(.failure(AuthenticationServiceError.noCurrentUserFound))
            return
        }

        user.signOut()

        let accessTokenDeleted = keychainService.delete(key: "accessToken")
        let idTokenDeleted = keychainService.delete(key: "idToken")
        let refreshTokenDeleted = keychainService.delete(key: "refreshToken")

        if accessTokenDeleted && idTokenDeleted && refreshTokenDeleted {
            completion(.success(()))
        } else {
            completion(.failure(AuthenticationServiceError.failedToClearTokens))
        }
    }

    func signUpUser(email: String, password: String, username: String, completion: @escaping (Result<AWSCognitoIdentityUserPoolSignUpResponse, Error>) -> Void) {
        let emailAttribute = AWSCognitoIdentityUserAttributeType(name: "email", value: email)
        let usernameAttribute = AWSCognitoIdentityUserAttributeType(name: "custom:username", value: username)
        userPool.signUp(email, password: password, userAttributes: [emailAttribute, usernameAttribute], validationData: nil).continueWith { [weak self] task -> Any? in
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

    func refreshToken(completion: @escaping (Result<Void, Error>) -> Void) {
        guard loadRefreshToken() != nil else {
            completion(.failure(AuthenticationServiceError.noRefreshTokenFound))
            return
        }
        
        guard let user = userPool.currentUser() else {
            completion(.failure(AuthenticationServiceError.noCurrentUserFound))
            return
        }

        user.getSession().continueWith { [weak self] (task: AWSTask<AWSCognitoIdentityUserSession>) -> Any? in
            DispatchQueue.main.async {
                if let error = task.error {
                    completion(.failure(error))
                } else if let result = task.result {
                    do {
                        if let newAccessToken = result.accessToken?.tokenString,
                           let newIdToken = result.idToken?.tokenString,
                           let newRefreshToken = result.refreshToken?.tokenString {
                            try self?.saveTokens(accessToken: newAccessToken, idToken: newIdToken, refreshToken: newRefreshToken)
                            completion(.success(()))
                        } else {
                            completion(.failure(AuthenticationServiceError.failedToRefreshTokens))
                        }
                    } catch {
                        completion(.failure(error))
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
    
    func getUserId() -> String? {
        return userPool.currentUser()?.username
    }
    
    private func saveTokens(accessToken: String, idToken: String, refreshToken: String) throws {
        if let accessTokenData = accessToken.data(using: .utf8),
           let idTokenData = idToken.data(using: .utf8),
           let refreshTokenData = refreshToken.data(using: .utf8) {
            _ = keychainService.save(key: "accessToken", data: accessTokenData)
            _ = keychainService.save(key: "idToken", data: idTokenData)
            _ = keychainService.save(key: "refreshToken", data: refreshTokenData)
        } else {
            throw AuthenticationServiceError.failedToSaveTokens
        }
    }
    
    private func loadRefreshToken() -> String? {
        guard let refreshTokenData = keychainService.load(key: "refreshToken") else { return nil }
        return String(data: refreshTokenData, encoding: .utf8)
    }
    
}

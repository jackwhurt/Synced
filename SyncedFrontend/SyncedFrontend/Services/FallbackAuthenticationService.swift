import AWSCognitoIdentityProvider

class FallbackAuthenticationService: AuthenticationServiceProtocol {
    func loginUser(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.failure(FallbackAuthenticationError.loginNotAvailable))
    }
    
    func logoutUser(completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.failure(FallbackAuthenticationError.logoutNotAvailable))
    }
    
    func signUpUser(email: String, password: String, username: String, completion: @escaping (Result<AWSCognitoIdentityUserPoolSignUpResponse, Error>) -> Void) {
        completion(.failure(FallbackAuthenticationError.signupNotAvailable))
    }
    
    func refreshTokenIfNeeded(completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.failure(FallbackAuthenticationError.tokenRefreshNotAvailable))
    }
    
    func checkSession(completion: @escaping (Bool) -> Void) {
        completion(false)
    }
    
    func getUserId() -> String? {
        ""
    }
}

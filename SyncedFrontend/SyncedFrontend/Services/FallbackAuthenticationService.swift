import AWSCognitoIdentityProvider

class FallbackAuthenticationService: AuthenticationServiceProtocol {
    func loginUser(username: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        <#code#>
    }
    
    func logoutUser(completion: @escaping (Result<Void, Error>) -> Void) {
        <#code#>
    }
    
    func signUpUser(email: String, password: String, completion: @escaping (Result<AWSCognitoIdentityUserPoolSignUpResponse, Error>) -> Void) {
        <#code#>
    }
    
    func refreshToken(completion: @escaping (Result<Void, Error>) -> Void) {
        <#code#>
    }
    
    func checkSession(completion: @escaping (Bool) -> Void) {
        <#code#>
    }
}

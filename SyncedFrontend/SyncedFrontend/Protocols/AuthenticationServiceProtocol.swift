import AWSCognitoIdentityProvider

protocol AuthenticationServiceProtocol {
    func loginUser(username: String, password: String, completion: @escaping (Result<Void, Error>) -> Void)
    func logoutUser(completion: @escaping (Result<Void, Error>) -> Void)
    func signUpUser(email: String, password: String, completion: @escaping (Result<AWSCognitoIdentityUserPoolSignUpResponse, Error>) -> Void)
    func refreshToken(completion: @escaping (Result<Void, Error>) -> Void)
    func checkSession(completion: @escaping (Bool) -> Void)
}

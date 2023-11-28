//
//  SignUpViewModel.swift
//  SyncedFrontend
//
//  Created by Jack Hurt on 28/11/2023.
//

import SwiftUI

class SignUpViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var showingSignUpError = false
    @Published var signUpErrorMessage: String = ""
    @Published var isSignedUp = false

    private let authService: AuthenticationService

    init(authService: AuthenticationService = AuthenticationService()) {
        self.authService = authService
    }

    func signUpUser() {
        authService.signUpUser(username: username, password: password, email: email) { [weak self] result in
            switch result {
            case .success(let signUpResponse):
                print("Sign up successful")
                DispatchQueue.main.async {
                    // You may want to handle email verification or other post-sign-up steps here
                    self?.isSignedUp = true
                }
            case .failure(let error):
                print("Sign up error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.signUpErrorMessage = error.localizedDescription
                    self?.showingSignUpError = true
                }
            }
        }
    }
}

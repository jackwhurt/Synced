//
//  SignUpViewModel.swift
//  SyncedFrontend
//
//  Created by Jack Hurt on 28/11/2023.
//

import SwiftUI

class SignUpViewModel: ObservableObject {
    @Published var email: String = ""
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
        authService.signUpUser(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Sign up successful")
                    self?.isSignedUp = true
                    // Additional logic for post-sign-up can be added here

                case .failure(let error):
                    print("Sign up error: \(error.localizedDescription)")
                    self?.signUpErrorMessage = error.localizedDescription
                    self?.showingSignUpError = true
                }
            }
        }
    }
}

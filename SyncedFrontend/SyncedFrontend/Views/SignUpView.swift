import SwiftUI

struct SignUpView: View {
    @State private var email: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    var body: some View {
        VStack(spacing: 20) {
            // Placeholder for the logo
            Image("logoPlaceholder")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 100)

            Text("SYNCED")
                .font(.largeTitle)
                .bold()

            TextField("Email Address", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button("Sign Up") {
                // Handle sign up action
            }
//            .buttonStyle(FilledButtonStyle())

            Spacer()

            NavigationLink("Already a member? Login", destination: LoginView())
                .foregroundColor(.blue)
        }
        .padding()
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}

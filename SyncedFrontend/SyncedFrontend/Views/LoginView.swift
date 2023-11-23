import SwiftUI

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""

    let textFieldBackgroundColor = Color.gray.opacity(0.3)
    let textFieldTextColor = Color.gray
    let buttonBackgroundColor = Color("Primary")
    let buttonForegroundColor = Color.white

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: geometry.size.height * 0.04) { // Dynamic spacing based on device height
                Spacer()
                    .frame(height: geometry.size.height * 0.1)
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 150)
                
                Spacer()
                    .frame(height: geometry.size.height * 0.01)
                
                // Text fields
                LongInputField(placeholder: "Username", text: $username)
    
                LongSecureInputField(placeholder: "Password", text: $password)

                RoundButton(
                    title: "Log In"
                )
                 {
                    // Handle login action
                }

                // Navigation to sign up and forgot password links
                HStack {
                    Button("Forgot Password?") {
                        // Handle forgot password action
                    }
                    .foregroundColor(.gray)

                    Spacer()

                    NavigationLink("Sign Up Here", destination: SignUpView())
                        .foregroundColor(Color("Primary"))
                }
                .padding(.horizontal, geometry.size.width * 0.05) // Dynamic horizontal padding

                Spacer() // Pushes all content to the top
            }
        }
        .padding()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

import SwiftUI

struct TestView: View {
    @StateObject private var cpViewModel: TestViewModel
    
    init(isLoggedIn: Binding<Bool>) {
        _cpViewModel = StateObject(wrappedValue: TestViewModel(
            authenticationService: DIContainer.shared.provideAuthenticationService(),
            appleMusicService: DIContainer.shared.provideAppleMusicService(),
            musicKitService: DIContainer.shared.provideMusicKitService(),
            collaborativePlaylistService: DIContainer.shared.provideCollaborativePlaylistService()
            )
        )
    }
    
    var body: some View {
        VStack {
            if cpViewModel.isLoggedIn {
                Text("Logged in. Hello, World!")
                Button("Logout") {
                    cpViewModel.logout()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
                Button("Connect Apple Music") {
                    Task {
                        await cpViewModel.connectAppleMusic()
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
            } else {
                Text("Not logged in.")
            }
        }
    }
}

// For preview
struct CollaborativePlaylistsView_Previews: PreviewProvider {
    static var previews: some View {
        TestView(isLoggedIn: .constant(false))
    }
}

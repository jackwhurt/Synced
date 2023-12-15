import SwiftUI

struct ContentView: View {
    @StateObject private var contentViewModel: ContentViewModel
        
    init() {
        _contentViewModel = StateObject(wrappedValue: ContentViewModel(
            authenticationService: DIContainer.shared.provideAuthenticationService(),
            collaborativePlaylistService: DIContainer.shared.provideCollaborativePlaylistService())
        )
    }
    
    var body: some View {
        ZStack {
            Color("SyncedBackground")
                .ignoresSafeArea()
            if (contentViewModel.isLoading) {
//                TODO: LoadingView()
            } else if contentViewModel.isLoggedIn {
                HomeView(isLoggedIn: $contentViewModel.isLoggedIn)
            } else {
                LoginView(isLoggedIn: $contentViewModel.isLoggedIn)
            }
        }
        .onAppear {
            Task {
                await contentViewModel.onOpen()
            }
        }
    }
}

// For preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

import SwiftUI

struct RequestView: View {
    @State private var selectedTab: Tab = .users
    @StateObject private var requestViewModel: RequestViewModel
    
    init() {
        let activityService = DIContainer.shared.provideActivityService()
        _requestViewModel = StateObject(wrappedValue: RequestViewModel(activityService: activityService))
    }
    
    var body: some View {
        VStack {
            Picker("Requests", selection: $selectedTab) {
                Text("Users").tag(Tab.users)
                Text("Playlists").tag(Tab.playlists)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            if selectedTab == .users {
                UserRequestListView(userRequests: requestViewModel.userRequests)
            } else {
                PlaylistRequestListView(playlistRequests: requestViewModel.playlistRequests)
            }
        }
        .navigationBarTitle("Requests", displayMode: .inline)
        .alert(isPresented: Binding<Bool>(
            get: { requestViewModel.errorMessage != nil },
            set: { _ in requestViewModel.errorMessage = nil }
        )) {
            Alert(title: Text("Error"), message: Text(requestViewModel.errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
        }
    }
}

struct UserRequestListView: View {
    var userRequests: [UserRequest]

    var body: some View {
        RequestListView(
            requests: userRequests,
            requestText: { "\($0.createdByUsername) wants to be your friend! Accept?" },
            onAccept: { request in
                print("Accepted request from \(request.createdByUsername)")
                // Implement accept logic
            },
            onReject: { request in
                print("Rejected request from \(request.createdByUsername)")
                // Implement reject logic
            }
        )
        .navigationBarTitle("Users")
    }
}

struct PlaylistRequestListView: View {
    var playlistRequests: [PlaylistRequest]

    var body: some View {
        RequestListView(
            requests: playlistRequests,
            requestText: { "\($0.createdByUsername) invited you to \($0.playlistTitle), will you join?" },
            onAccept: { request in
                print("Accepted playlist invitation from \(request.createdByUsername)")
                // Implement accept logic
            },
            onReject: { request in
                print("Rejected playlist invitation from \(request.createdByUsername)")
                // Implement reject logic
            }
        )
        .navigationBarTitle("Playlists")
    }
}

struct RequestListView<Request>: View where Request: Hashable {
    var requests: [Request]
    var requestText: (Request) -> String
    var onAccept: (Request) -> Void
    var onReject: (Request) -> Void

    var body: some View {
        List(requests, id: \.self) { request in
            HStack {
                Text(requestText(request))
                Spacer()
                Button(action: { onAccept(request) }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(BorderlessButtonStyle())

                Button(action: { onReject(request) }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.syncedErrorRed)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }
}


enum Tab {
    case users, playlists
}

struct RequestView_Previews: PreviewProvider {
    static var previews: some View {
        RequestView()
    }
}

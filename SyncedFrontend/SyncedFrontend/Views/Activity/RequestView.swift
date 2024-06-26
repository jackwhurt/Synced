import SwiftUI

struct RequestView: View {
    @State private var selectedTab: Tab = .users
    @State private var isAccepting = false
    @State private var isDeclining = (false, -1)
    @StateObject private var requestViewModel: RequestViewModel
    
    init(userRequests: [UserRequest], playlistRequests: [PlaylistRequest]) {
        let activityService = DIContainer.shared.provideActivityService()
        _requestViewModel = StateObject(wrappedValue: RequestViewModel(activityService: activityService, userRequests: userRequests, playlistRequests: playlistRequests))
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            VStack {
                // TODO: reimplement after demo
                //            Picker("Requests", selection: $selectedTab) {
                //                Text("Users").tag(Tab.users)
                //                Text("Playlists").tag(Tab.playlists)
                //            }
                //            .pickerStyle(SegmentedPickerStyle())
                //            .padding()
                //
                //            if selectedTab == .users {
                //                UserRequestListView(userRequests: requestViewModel.userRequests)
                //            } else {
                //                PlaylistRequestListView(requestViewModel: requestViewModel, playlistRequests: requestViewModel.playlistRequests)
                //            }
                
                PlaylistRequestListView(requestViewModel: requestViewModel, isAccepting: $isAccepting, isDeclining: $isDeclining).padding()
            }
            
            .navigationBarTitle("Requests", displayMode: .inline)
            .onAppear(perform: requestViewModel.loadRequests)
            .background(Color(UIColor.systemGroupedBackground))
            .alert(isPresented: Binding<Bool>(
                get: { requestViewModel.errorMessage != nil },
                set: { _ in requestViewModel.errorMessage = nil }
            )) {
                Alert(title: Text("Error"), message: Text(requestViewModel.errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
        }
    }
}

// TODO: reimplement after demo
//struct UserRequestListView: View {
//    var userRequests: [UserRequest]
//
//    var body: some View {
//        if userRequests.isEmpty {
//            Text("No friend requests found")
//                .foregroundColor(.syncedDarkGrey)
//                .padding()
//            Spacer()
//        } else {
//            RequestListView(
//                requests: userRequests,
//                requestText: { "\($0.createdByUsername) wants to be your friend! Accept?" },
//                onAccept: { request in
//                    print("Accepted request from \(request.createdByUsername)")
//                    // Implement accept logic
//                },
//                onReject: { request in
//                    print("Rejected request from \(request.createdByUsername)")
//                    // Implement reject logic
//                }
//            ).navigationBarTitle("Users")
//        }
//    }
//}

struct PlaylistRequestListView: View {
    @StateObject var requestViewModel: RequestViewModel
    @Binding var isAccepting: Bool
    @Binding var isDeclining: (Bool, Int)
    
    @State private var showingPlaylistOptions = false
    @State private var selectedRequest: PlaylistRequest?

    var body: some View {
        if requestViewModel.playlistRequests.isEmpty {
            Text("No playlist requests found")
                .foregroundColor(.syncedDarkGrey)
                .padding()
            Spacer()
        } else {
            RequestListView(
                isDeclining: $isDeclining,
                requests: requestViewModel.playlistRequests,
                requestText: { "\($0.createdByUsername) invited you to \($0.playlistTitle), will you join?" },
                onAccept: { request in
                    selectedRequest = request
                    showingPlaylistOptions = true
                },
                onReject: { request in
                    print("Rejected playlist invitation from \(request.createdByUsername)")
                    Task {
                        isDeclining = (true, request.hashValue)
                        await requestViewModel.resolveRequest(request: request, result: false, spotifyPlaylist: false, appleMusicPlaylist: false)
                    }
                }
            )
            .navigationBarTitle("Playlists")
            .sheet(isPresented: $showingPlaylistOptions) {
                PlaylistOptionsView(isAccepting: $isAccepting, onOptionSelected: { spotifyPlaylist, appleMusicPlaylist in
                    guard let request = selectedRequest else { return }
                    print("Accepted playlist invitation from \(request.createdByUsername)")
                    Task {
                        isAccepting = true
                        await requestViewModel.resolveRequest(request: request, result: true, spotifyPlaylist: spotifyPlaylist, appleMusicPlaylist: appleMusicPlaylist)
                        showingPlaylistOptions = false
                        isAccepting = false
                    }
                })
                .presentationDetents([.fraction(0.375)])
            }
        }
    }
}

struct RequestListView<Request>: View where Request: Hashable {
    @Binding var isDeclining: (Bool, Int)
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
                
                if isDeclining.0 && isDeclining.1 == request.hashValue {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(width: 44, height: 44)
                } else {
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
}

struct PlaylistOptionsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Binding var isAccepting: Bool
    var onOptionSelected: (Bool, Bool) -> Void
    
    @State private var spotifyPlaylist = false
    @State private var appleMusicPlaylist = false

    var body: some View {
        VStack {
            Text("Choose your playlist options")
                .font(.headline)
                .padding()
            
            StreamingServiceToggles(isOnAppleMusic: $appleMusicPlaylist, isOnSpotify:  $spotifyPlaylist)
                .padding()
                
            if isAccepting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Button("Confirm") {
                    onOptionSelected(spotifyPlaylist, appleMusicPlaylist)
                }
                .padding()
                .accentColor(.syncedBlue)
            }
        }
    }
}

enum Tab {
    case users, playlists
}

struct RequestView_Previews: PreviewProvider {
    static var previews: some View {
        RequestView(userRequests: [], playlistRequests: [])
    }
}

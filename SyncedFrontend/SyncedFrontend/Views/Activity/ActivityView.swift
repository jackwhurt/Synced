import SwiftUI

struct ActivityView: View {
    @StateObject private var activityViewModel: ActivityViewModel
    
    init() {
        _activityViewModel = StateObject(wrappedValue: ActivityViewModel(activityService: DIContainer.shared.provideActivityService()))
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        TextLink(title: "View Requests", destination: RequestView(userRequests:
                        Binding(get: {
                            self.activityViewModel.userRequests
                        }, set: {
                            self.activityViewModel.userRequests = $0
                        }), playlistRequests: Binding(get: {
                            self.activityViewModel.playlistRequests
                        }, set: {
                            self.activityViewModel.playlistRequests = $0
                        })))
                        let requestCount = activityViewModel.playlistRequests.count + activityViewModel.userRequests.count
                        if requestCount > 0 {
                            Text("(\(requestCount))")
                                .foregroundColor(.syncedBlue)
                            Spacer()
                        }
                    }
                }
                
                Section(header: Text("Notifications")) {
                    if activityViewModel.notifications.isEmpty {
                        Text("No notifications found")
                            .foregroundColor(.syncedDarkGrey)
                    } else {
                        ForEach(activityViewModel.notifications, id: \.self) { notification in
                            HStack {
                                Text(notification.message)
                                    .padding(.vertical, 0.5)
                                Spacer()
                                Text(activityViewModel.convertTimestamp(notification.createdAt))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Activities")
            .onAppear(perform: activityViewModel.loadActivities)
            .alert("Error", isPresented: Binding<Bool>(
                get: { self.activityViewModel.errorMessage != nil },
                set: { _ in self.activityViewModel.errorMessage = nil }
            ), presenting: activityViewModel.errorMessage) { errorMessage in
                Button("OK", role: .cancel) { }
            } message: { errorMessage in
                Text(errorMessage)
            }
        }
    }
}

struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView()
    }
}

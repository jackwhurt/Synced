import SwiftUI

struct EditCollaboratorsView: View {
    @Binding var showSheet: Bool
    
    @StateObject private var editCollaboratorsViewModel: EditCollaboratorsViewModel
    
    init(showSheet: Binding<Bool>, playlistId: String) {
        _showSheet = showSheet
        _editCollaboratorsViewModel = StateObject(wrappedValue: EditCollaboratorsViewModel(playlistId: playlistId, collaborativePlaylistService: DIContainer.shared.provideCollaborativePlaylistService()))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if editCollaboratorsViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                }
                List {
                    CollaboratorsListView(collaborators: editCollaboratorsViewModel.collaborators)
                    
                    AddCollaboratorButtonView {
                        
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: editCollaboratorsViewModel.isLoading)
            .transition(.slide)
            .navigationBarTitle("Edit Collaborators", displayMode: .inline)
            .toolbar { toolbarContent() }
            .alert("Error", isPresented: Binding<Bool>(
                get: { self.editCollaboratorsViewModel.errorMessage != nil },
                set: { _ in self.editCollaboratorsViewModel.errorMessage = nil }
            ), presenting: editCollaboratorsViewModel.errorMessage) { errorMessage in
                Button("OK", role: .cancel) {
                    showSheet = false
                }
            } message: { errorMessage in
                Text(errorMessage)
            }
            .accentColor(Color("SyncedBlue"))
            .onAppear(perform: editCollaboratorsViewModel.loadCollaborators)
        }
    }
    
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Done", action: {
                showSheet = false
            })
        }
    }
}

struct CollaboratorsListView: View {
    var collaborators: [UserMetadata]

    var body: some View {
        Section {
            ForEach(collaborators, id: \.self) { collaborator in
                HStack {
                    ProfileAsyncImageLoader(urlString: collaborator.photoUrl, width: 50, height: 50)
                    
                    Text("@\(collaborator.username)")
                        .fontWeight(.medium)
                    if let isOwner = collaborator.isPlaylistOwner, isOwner {
                        Spacer()
                        Text("creator")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else if let status = collaborator.requestStatus {
                        Spacer()
                        Text(status)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.leading, 8)
            }
        }
    }
}


struct AddCollaboratorButtonView: View {
    var addAction: () -> Void

    var body: some View {
        Section {
            Button(action: addAction) {
                HStack {
                    Image(systemName: "plus")
                        .foregroundColor(.syncedBlue)
                    Text("Add Collaborator")
                        .foregroundColor(.syncedBlue)
                }
                .cornerRadius(8)
            }
            .padding()
            .listRowInsets(EdgeInsets())
        }
    }
}


import SwiftUI

struct EditCollaboratorsView: View {
    @Binding var showSheet: Bool
    @Binding var isOwner: Bool
    
    @StateObject private var editCollaboratorsViewModel: EditCollaboratorsViewModel
    
    init(showSheet: Binding<Bool>, isOwner: Binding<Bool>, playlistId: String) {
        _showSheet = showSheet
        _isOwner = isOwner
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
                    NavigationLink(destination: AddCollaboratorsView(playlistId: editCollaboratorsViewModel.playlistId, currentCollaborators: editCollaboratorsViewModel.collaborators)) {
                        AddCollaboratorButtonView()
                    }
                    .disabled(editCollaboratorsViewModel.isLoading)
                    
                    CollaboratorsListView(isOwner: $isOwner, collaborators: editCollaboratorsViewModel.collaborators) { indices in
                        editCollaboratorsViewModel.deleteCollaboratorInList(at: indices)
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
    @Binding var isOwner: Bool
    var collaborators: [UserMetadata]
    var onDelete: (IndexSet) -> Void

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
                .deleteDisabled(collaborator.isPlaylistOwner ?? true)
            }
            .onDelete(perform: isOwner ? onDelete : nil)
        }
    }
}

struct AddCollaboratorButtonView: View {
    var body: some View {
        Section {
            HStack {
                Image(systemName: "plus")
                    .foregroundColor(.syncedBlue)
                Text("Add Collaborators")
                    .foregroundColor(.syncedBlue)
            }
            .cornerRadius(8)
        }
    }
}

struct EditCollaboratorsView_Previews: PreviewProvider {    
    static var previews: some View {
        EditCollaboratorsView(showSheet: .constant(true), isOwner: .constant(true), playlistId: "")
    }
}

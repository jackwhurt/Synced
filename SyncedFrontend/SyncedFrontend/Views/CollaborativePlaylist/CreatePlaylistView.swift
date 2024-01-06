import SwiftUI

struct CreatePlaylistView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var createPlaylistViewModel: CreatePlaylistViewModel
    @State private var showErrorAlert = false

    init() {
        _createPlaylistViewModel = StateObject(wrappedValue: CreatePlaylistViewModel())
    }

    var body: some View {
        NavigationView {
            Form {
                TitleSection(title: $createPlaylistViewModel.title)
                DescriptionSection(description: $createPlaylistViewModel.description)
                CollaboratorsSection(collaborators: $createPlaylistViewModel.collaborators, newCollaborator: $createPlaylistViewModel.newCollaborator, addCollaborator: createPlaylistViewModel.addNewCollaborator, deleteCollaborator: createPlaylistViewModel.deleteCollaborator)
            }
            .navigationBarTitle("New Playlist", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel", action: { dismiss() }), trailing: Button("Save", action: {
                Task {
                    await createPlaylistViewModel.save()
                    if let errorMessage = createPlaylistViewModel.errorMessage {
                        showErrorAlert = true
                    } else {
                        dismiss()
                    }
                }
            }))
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Error"), message: Text(createPlaylistViewModel.errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
        }.accentColor(Color("SyncedBlue"))
    }
}

struct TitleSection: View {
    @Binding var title: String

    var body: some View {
        Section(header: Text("Title")) {
            TextField("Title", text: $title)
        }
    }
}

struct DescriptionSection: View {
    @Binding var description: String

    var body: some View {
        Section(header: Text("Description")) {
            TextField("Description", text: $description)
        }
    }
}

struct CollaboratorsSection: View {
    @Binding var collaborators: [String]
    @Binding var newCollaborator: String
    var addCollaborator: () -> Void
    var deleteCollaborator: (IndexSet) -> Void

    var body: some View {
        Section(header: Text("Collaborators")) {
            ForEach(collaborators, id: \.self) { collaborator in
                Text(collaborator)
            }
            .onDelete(perform: deleteCollaborator)
            TextField("New Collaborator", text: $newCollaborator)
            Button("Add Collaborator", action: addCollaborator)
        }
    }
}

struct CreatePlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePlaylistView()
    }
}

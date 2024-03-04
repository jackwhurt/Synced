import SwiftUI

enum TextInputType {
    case email
    case password
    case newPassword
    case confirmPassword
    case other
}

struct LongInputFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.vertical, 10)
            .padding(.horizontal)
            .autocapitalization(.none)
            .background(Color("SyncedInputGrey"))
            .cornerRadius(10)
    }
}

struct LongSecureInputField: View {
    let placeholder: String
    @Binding var text: String
    var inputType: TextInputType

    var body: some View {
        SecureField(placeholder, text: $text)
            .textFieldStyle(LongInputFieldStyle())
            .frame(width: 300, height: 50)
    }
}

struct LongInputField: View {
    let placeholder: String
    @Binding var text: String
    var inputType: TextInputType

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(LongInputFieldStyle())
            .textContentType(inputType == .email ? .emailAddress : .none)
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .frame(width: 300, height: 50)
    }
}

struct Previews: PreviewProvider {
    static var previews: some View {
        LongSecureInputField(
            placeholder: "Password",
            text: .constant(""),
            inputType: .newPassword
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}

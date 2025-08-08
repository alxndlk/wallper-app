import SwiftUI

struct CustomPublishModal: View {
    let fileName: String
    @Binding var selectedCategory: String
    @Binding var selectedAge: String
    @Binding var selectedAuthorName: String
    var onPublish: () -> Void
    var onCancel: () -> Void

    @State private var isPublishing = false

    private let categories = [
        "", "Animals", "Anime", "Cars", "Games", "Graphics",
        "Minimalist", "Movies", "Nature", "Other", "People",
        "Pixel Art", "Space", "Winter"
    ]

    private let ageRatings = ["", "0+", "6+", "12+", "16+", "18+"]

    private var isReady: Bool {
        !selectedCategory.isEmpty && !selectedAge.isEmpty && !selectedAuthorName.isEmpty && !isPublishing
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Publish \(fileName)?")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)

            Text("Please review the information before publishing. You can change it later from your library.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
            
            TextField("Author Name", text: $selectedAuthorName)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .foregroundColor(.white)
                .font(.system(size: 12))
                .frame(maxWidth: 280)

            HStack(spacing: 8) {
                capsuleMenu(title: "Category", selection: $selectedCategory, options: categories)
                capsuleMenu(title: "Age Rating", selection: $selectedAge, options: ageRatings)
            }
            .padding(.top, 8)
            .padding(.bottom, 8)

            HStack(spacing: 12) {
                Button(action: {
                    if !isPublishing {
                        onCancel()
                    }
                }) {
                    Text("Cancel")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(minWidth: 50)
                        .foregroundColor(.white.opacity(0.9))
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isPublishing)

                Button(action: {
                    isPublishing = true
                    onPublish()
                }) {
                    Group {
                        if isPublishing {
                            MiniSpinner()
                                .frame(width: 16, height: 16)
                        } else {
                            Text("Publish")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(minWidth: 50)
                    .foregroundColor(.white)
                    .background(isReady ? Color.blue : Color.gray.opacity(0.4))
                    .clipShape(Capsule())
                }
                .disabled(!isReady)
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 8)
        }
        .padding(24)
        .fixedSize()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding()
    }

    private func capsuleMenu(title: String, selection: Binding<String>, options: [String]) -> some View {
        ZStack {
            Capsule()
                .fill(selection.wrappedValue.isEmpty ? Color.white.opacity(0.1) : Color.blue)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)

            Menu {
                ForEach(options.dropFirst(), id: \.self) { option in
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        Label(option, systemImage: selection.wrappedValue == option ? "checkmark" : "")
                    }
                }
            } label: {
                Text(selection.wrappedValue.isEmpty ? title : selection.wrappedValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .frame(minWidth: 40)
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal, 2)
    }
}

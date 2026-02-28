import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("userName") private var userName = ""

    @State private var isEditingName = false
    @State private var editingText = ""
    @State private var selectedFilter = "All Time"
    @State private var stampImage: UIImage?

    // Stamps will be populated in a future update
    private let stamps: [String] = []

    private var filterOptions: [String] {
        let options = ["All Time"]
        // Years from collected stamps will be appended here
        return options
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            filterBar
            if stamps.isEmpty {
                emptyState
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.regularMaterial)
        .alert("Your Name", isPresented: $isEditingName) {
            TextField("Enter your name", text: $editingText)
            Button("Save") { saveName() }
            Button("Cancel", role: .cancel) { editingText = userName }
        }
        .onAppear { loadStampImage() }
        .onChange(of: colorScheme) { _, _ in loadStampImage() }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 3) {
                Button {
                    editingText = userName
                    isEditingName = true
                } label: {
                    Text(userName.isEmpty ? "Add your name" : userName)
                        .font(.headline)
                        .foregroundStyle(userName.isEmpty ? .tertiary : .primary)
                }
                .buttonStyle(.plain)

                Text("My Stamp Book")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .fontWeight(.semibold)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filterOptions, id: \.self) { option in
                    Button {
                        selectedFilter = option
                    } label: {
                        Text(option)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                selectedFilter == option
                                    ? Color.secondary.opacity(0.28)
                                    : Color.secondary.opacity(0.12)
                            )
                            .foregroundStyle(.primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            if let img = stampImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            VStack(spacing: 8) {
                Text("Start Your Journey")
                    .font(.headline)

                Text("When you visit new towns, cities, or attractions, you'll collect stamps to remember every adventure.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func saveName() {
        userName = editingText.trimmingCharacters(in: .whitespaces)
    }

    private func loadStampImage() {
        let pngName = colorScheme == .dark ? "StampSplashDark" : "StampSplash"
        stampImage = UIImage(named: pngName)
    }
}

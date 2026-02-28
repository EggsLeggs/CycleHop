import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var stampStore: StampStore
    @AppStorage("userName") private var userName = ""
    @AppStorage("showUnownedStamps") private var showUnownedStamps = false

    @State private var isEditingName = false
    @State private var editingText = ""
    @State private var selectedFilter = "All Time"
    @State private var showSettings = false
    @State private var stampImage: UIImage?

    private var filterOptions: [String] {
        let years = stampStore.claimedStamps
            .map { Calendar.current.component(.year, from: $0.dateClaimed) }
        let sortedYears = Array(Set(years)).sorted()
        return ["All Time"] + sortedYears.map { String($0) }
    }

    private var filteredClaimedStamps: [ClaimedStamp] {
        if selectedFilter == "All Time" {
            return stampStore.claimedStamps
        }
        guard let year = Int(selectedFilter) else { return stampStore.claimedStamps }
        return stampStore.claimedStamps.filter {
            Calendar.current.component(.year, from: $0.dateClaimed) == year
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            filterBar
            if showUnownedStamps {
                if stampStore.allDefinitions.isEmpty { emptyState } else { stampSections }
            } else {
                if filteredClaimedStamps.isEmpty { emptyState } else { stampSections }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.regularMaterial)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
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
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

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

    private func sectionHasContent(_ definitions: [StampDefinition]) -> Bool {
        if showUnownedStamps { return !definitions.isEmpty }
        return definitions.contains { def in filteredClaimedStamps.contains { $0.id == def.id } }
    }

    private var stampSections: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                let cityDefs = stampStore.allDefinitions.filter { $0.type == .city }
                let attractionDefs = stampStore.allDefinitions.filter { $0.type == .attraction }

                if sectionHasContent(cityDefs) {
                    stampSection(title: "Cities", definitions: cityDefs)
                }
                if sectionHasContent(attractionDefs) {
                    stampSection(title: "Attractions", definitions: attractionDefs)
                }
            }
            .padding(16)
        }
    }

    private func stampSection(title: String, definitions: [StampDefinition]) -> some View {
        let claimedCount = definitions.filter { stampStore.isAlreadyClaimed($0) }.count
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                if showUnownedStamps {
                    Text("\(claimedCount)/\(definitions.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Capsule())
                }
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(definitions) { definition in
                    if let claimed = filteredClaimedStamps.first(where: { $0.id == definition.id }) {
                        stampCell(definition: definition, claimed: claimed)
                    } else if showUnownedStamps && !stampStore.isAlreadyClaimed(definition) {
                        teaserCell(definition: definition)
                    }
                }
            }
        }
    }

    private func stampCell(definition: StampDefinition, claimed: ClaimedStamp) -> some View {
        VStack(spacing: 8) {
            StampImageView(stampPNGBaseName: definition.stampPNGBaseName, size: 100)
            Text(definition.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            Text(claimed.dateClaimed, style: .date)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func teaserCell(definition: StampDefinition) -> some View {
        VStack(spacing: 8) {
            ZStack {
                if let baseName = definition.cityArtPNGBaseName,
                   let img = UIImage(named: "\(baseName)\(colorScheme == .dark ? "Dark" : "Light")") {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.12))
                        .frame(width: 100, height: 100)
                }

                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 100, height: 100)

            Text(definition.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Text("Visit to collect")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func saveName() {
        userName = editingText.trimmingCharacters(in: .whitespaces)
    }

    private func loadStampImage() {
        let pngName = colorScheme == .dark ? "StampSplashDark" : "StampSplash"
        stampImage = UIImage(named: pngName)
    }
}

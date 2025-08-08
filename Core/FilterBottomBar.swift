import SwiftUI

struct FilterBottomBar: View {
    @EnvironmentObject var filterStore: VideoFilterStore
    @State private var selectedFilters: [String: String] = [:]
    @State private var hoveredLabel: String? = nil
    @Namespace private var animation
    

    var hasActiveFilters: Bool {
        !selectedFilters.isEmpty || !filterStore.searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        HStack(spacing: 16) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white)
                    .font(.system(size: 10, weight: .medium))
                TextField("Search...", text: $filterStore.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .regular))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            )
            .clipShape(Capsule())
            .frame(width: 180)

            if filterStore.dynamicFilters.isEmpty {
                MiniSpinner()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(filterStore.dynamicFilters, id: \.label) { filter in
                            Menu {
                                ForEach(filter.options, id: \.self) { option in
                                    Button(action: {
                                        withAnimation(.easeInOut) {
                                            selectedFilters[filter.label] = option
                                        }
                                    }) {
                                        Label(option, systemImage: selectedFilters[filter.label] == option ? "checkmark" : "")
                                    }
                                }
                            } label: {
                                Image(systemName: filter.icon)
                                    .foregroundColor(.white)
                                    .font(.system(size: 10, weight: .medium))
                                    .frame(width: 28, height: 28)
                                    .background(
                                        Circle()
                                            .fill(
                                                selectedFilters[filter.label] != nil || hoveredLabel == filter.label
                                                ? Color.blue
                                                : Color.white.opacity(0.1)
                                            )
                                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                    )
                            }
                            .onHover { hovering in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    hoveredLabel = hovering ? filter.label : nil
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .fixedSize()
                    .padding(.trailing, 10)
                }
            }

            Spacer()

            HStack(spacing: 6) {
                if hasActiveFilters {
                    Button {
                        withAnimation(.spring()) {
                            filterStore.resetFilters()
                            selectedFilters.removeAll()
                        }
                    } label: {
                        Text("Reset")
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(minWidth: 50)
                            .foregroundColor(.white.opacity(0.9))
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .animation(.easeOut(duration: 0.3), value: filterStore.selectedFilters)
                }

                Button {
                    withAnimation(.easeInOut) {
                        filterStore.selectedFilters = selectedFilters
                    }
                } label: {
                    Text("Apply")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(minWidth: 50)
                        .foregroundColor(.white)
                        .background(hasActiveFilters ? Color.blue : Color.gray.opacity(0.4))
                }
                .clipShape(Capsule())
                .disabled(!hasActiveFilters)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .animation(.easeOut(duration: 0.25), value: hasActiveFilters)
    }
}

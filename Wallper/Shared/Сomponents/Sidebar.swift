import SwiftUI

struct SidebarItem: View {
    var icon: String
    var text: String
    var isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color.primary.opacity(0.8))
                .frame(width: 16)

            Text(text)
                .foregroundColor(isSelected ? Color.primary.opacity(1) : Color.primary.opacity(0.45))
                .font(.system(size: 12, weight: .regular))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.primary.opacity(0.1) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.25), value: isSelected)
        .contentShape(Rectangle())
    }
}

struct SidebarLicenseActive: View {
    var icon: String
    var text: String
    var isSelected: Bool
    @EnvironmentObject var licenseManager: LicenseManager

    @State private var isHovering = false
    @State private var didCopy = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: didCopy ? "document.on.clipboard.fill" : (isHovering ? "doc.on.doc" : icon))
                .foregroundColor(Color.primary.opacity(0.8))
                .frame(width: 16)

            Text(didCopy ? "Copied" : (isHovering ? (licenseManager.licenseKey ?? "••••••••••") : text))
                .foregroundColor(Color.primary.opacity(0.8))
                .font(.system(size: 12, weight: .regular))

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 32)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.1))
                .animation(.easeInOut(duration: 0.25), value: isHovering)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.25)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            if let key = licenseManager.licenseKey, !key.isEmpty {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(key, forType: .string)

                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    didCopy = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        didCopy = false
                    }
                }
            }
        }
    }
}



struct SidebarSettingsRow: View {
    let title: String
    @Binding var isOn: Bool
    var icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 16)

            Text(title)
                .foregroundColor(.primary)
                .font(.system(size: 13, weight: .regular))

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .scaleEffect(0.7)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
        .padding(.vertical, 8)
        .padding(.leading, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.clear)
        )
        .contentShape(Rectangle())
    }
}

struct SidebarButton: View {
    let item: NavigationItem
    let icon: String
    let text: String
    @Binding var selection: Set<NavigationItem>

    var isSelected: Bool {
        selection.contains(item)
    }

    var body: some View {
        Button(action: {
            withAnimation {
                selection = [item]
            }
        }) {
            SidebarItem(icon: icon, text: text, isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }
}

struct Sidebar: View {
    @Binding var selection: Set<NavigationItem>
    @State private var glowPhase: Double = 0
    @State private var showLicenseButton = false
    @EnvironmentObject var licenseManager: LicenseManager
    
    @State private var launchAtLogin = false
    @State private var randomVideo = false


    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 10) {
                            Text("Wallper")
                                .font(.custom("TrebuchetMS", size: 18).weight(.semibold))
                                .overlay(
                                    LinearGradient(
                                        colors: [Color.primary.opacity(1.0), Color.primary.opacity(0.4)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .mask(
                                        Text("Wallper")
                                            .font(.custom("TrebuchetMS", size: 18).weight(.semibold))
                                    )
                                )
                            if licenseManager.hasLicense && licenseManager.isChecked {
                                ZStack(alignment: .topTrailing) {
                                    Text("Pro")
                                        .font(.system(size: 10, weight: .regular))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.black.opacity(0.3))
                                                .overlay(
                                                    Capsule()
                                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                )
                                        )

                                    Image(systemName: "sparkle")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white)
                                        .offset(x: 2, y: -2)
                                        .shadow(color: .primary.opacity(0.6), radius: 2)
                                }
                            }

                        }.padding(.horizontal, 8)


                        SidebarButton(item: .wallpers, icon: "sparkles", text: "Wallpapers", selection: $selection)
                            .padding(.top, 20)
                        SidebarButton(item: .userCreated, icon: "square.on.square.badge.person.crop.fill", text: "Community", selection: $selection)
                        SidebarButton(item: .devices, icon: "macbook", text: "My devices", selection: $selection)
//                    }

//                    Group {
//                        Text("Library")
//                            .foregroundColor(.gray)
//                            .font(.footnote)
//                            .padding(.top, 32)
//                            .padding(.bottom, 4)
//                            .padding(.horizontal, 12)
                        
                        SidebarButton(item: .myMedia, icon: "photo.on.rectangle.angled", text: "My media", selection: $selection)
                        SidebarButton(item: .likes, icon: "heart", text: "Likes", selection: $selection)
                        SidebarButton(item: .uploads, icon: "square.and.arrow.up", text: "Upload", selection: $selection)
//                    }
//                        Group {
//                            Text("Options")
//                                .foregroundColor(.gray)
//                                .font(.footnote)
//                                .padding(.top, 16)
//                                .padding(.bottom, 4)
//                                .padding(.horizontal, 12)
                            
                        
                                SidebarButton(item: .settings, icon: "gear", text: "Settings", selection: $selection)
                            }
                }
                .padding(.top, 48)
                .padding(.horizontal, 24)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                if showLicenseButton {
                    LicenseButton()
                        .padding(.horizontal, 28)
                        .padding(.bottom, 8)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    SidebarLicenseActive(icon: "shield.lefthalf.filled.badge.checkmark", text: "Pro version", isSelected: true)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 8)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Text("© 2025 Wallper App")
                    .font(.footnote)
                    .foregroundColor(.primary.opacity(0.8))
                    .padding(.horizontal, 28)
                    .padding(.bottom, 16)
            }
        }
        .frame(width: 235)
        .background(Color.clear)
        .onAppear {
            let hwid = HWIDProvider.getHWID()
            licenseManager.checkLicense(for: hwid)
            updateLicenseButtonVisibility()
        }
        .onChange(of: licenseManager.isChecked) { _ in
            updateLicenseButtonVisibility()
        }
        .onChange(of: licenseManager.hasLicense) { _ in
            updateLicenseButtonVisibility()
        }
        .animation(.easeOut(duration: 0.4), value: showLicenseButton)
    }

    private func updateLicenseButtonVisibility() {
        withAnimation {
            showLicenseButton = licenseManager.isChecked && !licenseManager.hasLicense
        }
    }
}

struct LicenseButton: View {
    @EnvironmentObject var licenseManager: LicenseManager
    @State private var isHovering = false
    var body: some View {
        Button(action: {
            LicenseWindowController.show(licenseManager: licenseManager)
        }) {
            HStack(spacing: 12) {
                Image(systemName: "key.fill")
                    .foregroundColor(Color.primary.opacity(0.8))
                    .frame(width: 16)
                Text("Enter License")
                    .foregroundColor(Color.primary)
                    .font(.system(size: 12, weight: .regular))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(isHovering ? 0.12 : 0.08))
                    .animation(.easeInOut(duration: 0.25), value: isHovering)
            )
            .shadow(color: .primary.opacity(0.06), radius: 5)
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.25)) {
                    isHovering = hovering
                }
            }

        }
        .buttonStyle(.plain)
    }
}

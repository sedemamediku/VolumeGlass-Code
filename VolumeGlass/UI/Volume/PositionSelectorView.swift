import SwiftUI

struct PositionSelectorView: View {
    @ObservedObject var setupState: SetupState
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Change Position")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            Divider()
            
            // Position options
            VStack(spacing: 8) {
                ForEach(VolumeBarPosition.allCases, id: \.self) { position in
                    Button(action: {
                        setupState.selectedPosition = position
                        // Save immediately
                        UserDefaults.standard.set(position.displayName, forKey: "volumeBarPosition")
                    }) {
                        HStack {
                            Image(systemName: iconForPosition(position))
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 24)
                            
                            Text(position.displayName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if setupState.selectedPosition == position {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(setupState.selectedPosition == position ? Color.primary.opacity(0.15) : Color.primary.opacity(0.05))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            
            Divider()
            
            // Warning
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text("Position change requires app restart")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(width: 280)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
    
    private func iconForPosition(_ position: VolumeBarPosition) -> String {
        switch position {
        case .leftMiddleVertical: return "sidebar.left"
        case .bottomVertical: return "rectangle.portrait.bottomhalf.filled"
        case .rightVertical: return "sidebar.right"
        case .topHorizontal: return "rectangle.topthird.inset.filled"
        case .bottomHorizontal: return "rectangle.bottomthird.inset.filled"
        case .custom: return "hand.draw"
        }
    }
}


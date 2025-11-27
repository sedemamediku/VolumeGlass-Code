import SwiftUI

struct VolumePresetEditor: View {
    @ObservedObject var settings: VolumeControlSettings
    @Binding var isPresented: Bool
    @State private var editingPresets: [Float]
    @Environment(\.colorScheme) var colorScheme
    
    init(settings: VolumeControlSettings, isPresented: Binding<Bool>) {
        self.settings = settings
        self._isPresented = isPresented
        self._editingPresets = State(initialValue: settings.customPresets)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Edit Presets")
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
            
            // Preset editors
            VStack(spacing: 12) {
                ForEach(0..<editingPresets.count, id: \.self) { index in
                    HStack(spacing: 12) {
                        Text("Preset \(index + 1)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 70, alignment: .leading)
                        
                        Slider(
                            value: Binding(
                                get: { Double(editingPresets[index]) },
                                set: { editingPresets[index] = Float($0) }
                            ),
                            in: 0...1
                        )
                        
                        Text("\(Int(editingPresets[index] * 100))%")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 45, alignment: .trailing)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 8)
            
            Divider()
            
            // Actions
            HStack(spacing: 12) {
                Button("Reset") {
                    editingPresets = [0.25, 0.5, 0.75, 1.0]
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Button("Save") {
                    settings.customPresets = editingPresets
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(width: 320)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}


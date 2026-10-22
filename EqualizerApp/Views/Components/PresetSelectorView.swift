import SwiftUI

/// Preset selection sheet showing Factory & Custom user presets with mini curve badges.
public struct PresetSelectorView: View {
    @ObservedObject var viewModel: EqualizerViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedTab: Int = 0 // 0: Factory, 1: Custom
    @State private var newPresetName: String = ""
    @State private var showingSaveAlert: Bool = false
    
    public init(viewModel: EqualizerViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.08).ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Segmented Selector
                    Picker("Preset Type", selection: $selectedTab) {
                        Text("Factory Presets (\(viewModel.systemPresets.count))").tag(0)
                        Text("Custom (\(viewModel.customPresets.count))").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 16)
                    
                    if selectedTab == 0 {
                        // Factory presets list
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(viewModel.systemPresets) { preset in
                                    presetRow(preset: preset, isCustom: false)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        }
                    } else {
                        // Custom presets list
                        VStack(spacing: 12) {
                            // "Save Current EQ as Preset" card
                            Button(action: {
                                showingSaveAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.cyan)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Save Current EQ as New Preset")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("Store current 10-band slider gains")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.cyan.opacity(0.12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .padding(.horizontal, 16)
                            
                            if viewModel.customPresets.isEmpty {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "slider.vertical.3")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    Text("No Custom Presets Yet")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Text("Adjust the sliders and tap 'Save Current EQ' to create one.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                                Spacer()
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 10) {
                                        ForEach(viewModel.customPresets) { preset in
                                            presetRow(preset: preset, isCustom: true)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 20)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 12)
            }
            .navigationTitle("Equalizer Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
            .alert("Save Custom Preset", isPresented: $showingSaveAlert) {
                TextField("Preset Name", text: $newPresetName)
                Button("Save") {
                    viewModel.saveCustomPreset(name: newPresetName)
                    newPresetName = ""
                }
                Button("Cancel", role: .cancel) {
                    newPresetName = ""
                }
            } message: {
                Text("Enter a unique name for your custom EQ curve.")
            }
        }
    }
    
    private func presetRow(preset: EQPreset, isCustom: Bool) -> some View {
        let isSelected = viewModel.activePreset.name == preset.name
        
        return Button(action: {
            viewModel.applyPreset(preset)
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack(spacing: 12) {
                // Preset Icon
                Image(systemName: preset.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .black : .cyan)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle().fill(isSelected ? Color.cyan : Color.cyan.opacity(0.15))
                    )
                
                // Name & Category
                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name)
                        .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(preset.category.rawValue)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Mini graphical curve preview
                MiniCurvePreview(gains: preset.gains)
                    .frame(width: 50, height: 22)
                
                if isCustom {
                    Button(action: {
                        viewModel.deleteCustomPreset(preset)
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(6)
                    }
                }
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.cyan)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.cyan.opacity(0.6) : Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }
}

/// Compact mini preview of the preset's EQ curve.
private struct MiniCurvePreview: View {
    let gains: [Float]
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let count = max(1, gains.count)
            let step = w / CGFloat(count - 1)
            
            Path { path in
                for (i, gain) in gains.enumerated() {
                    let x = step * CGFloat(i)
                    let y = (h / 2) - CGFloat(gain / 12.0) * (h / 2.5)
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.cyan.opacity(0.8), lineWidth: 1.5)
        }
    }
}

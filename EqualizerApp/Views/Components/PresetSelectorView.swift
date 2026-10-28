import SwiftUI

/// Preset selection sheet showing Factory & Custom user presets with mini curve badges,
/// fluid spring transitions, and Apple HIG aesthetics.
public struct PresetSelectorView: View {
    @ObservedObject var viewModel: EqualizerViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedTab: Int = 0 // 0: Factory, 1: Custom
    @State private var newPresetName: String = ""
    @State private var isShowingCreateField: Bool = false
    
    public init(viewModel: EqualizerViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                EqualizerTheme.Colors.backgroundBase.ignoresSafeArea()
                
                VStack(spacing: 14) {
                    // Custom Fluid Segmented Control
                    HStack(spacing: 4) {
                        tabButton(title: "Factory Presets (\(viewModel.systemPresets.count))", index: 0)
                        tabButton(title: "Custom (\(viewModel.customPresets.count))", index: 1)
                    }
                    .padding(3.5)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(EqualizerTheme.Colors.surfaceTray)
                    )
                    .padding(.horizontal, 16)
                    
                    if selectedTab == 0 {
                        // Factory presets list
                        ScrollView {
                            LazyVStack(spacing: 9) {
                                ForEach(viewModel.systemPresets) { preset in
                                    presetRow(preset: preset, isCustom: false)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                        }
                    } else {
                        // Custom presets list
                        VStack(spacing: 12) {
                            // "Save Current EQ as Preset" card
                            if isShowingCreateField {
                                HStack(spacing: 8) {
                                    TextField("New Preset Name", text: $newPresetName)
                                        .font(.system(size: 13, weight: .medium))
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(EqualizerTheme.Colors.backgroundBase)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(EqualizerTheme.Colors.borderHairline, lineWidth: 1)
                                                )
                                        )
                                        .foregroundColor(.white)
                                    
                                    Button("Save") {
                                        viewModel.saveCustomPreset(name: newPresetName)
                                        newPresetName = ""
                                        withAnimation(EqualizerTheme.AnimationSprings.tactile) {
                                            isShowingCreateField = false
                                        }
                                        EqualizerTheme.Haptics.success()
                                    }
                                    .font(.system(size: 12.5, weight: .bold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 9)
                                    .background(Capsule().fill(EqualizerTheme.Colors.cyanAccent))
                                    .foregroundColor(.black)
                                    
                                    Button("Cancel") {
                                        withAnimation(EqualizerTheme.AnimationSprings.tactile) {
                                            isShowingCreateField = false
                                        }
                                    }
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(EqualizerTheme.Colors.surfaceTray)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(EqualizerTheme.Colors.borderHairline, lineWidth: 1)
                                        )
                                )
                                .padding(.horizontal, 16)
                            } else {
                                Button(action: {
                                    withAnimation(EqualizerTheme.AnimationSprings.tactile) {
                                        isShowingCreateField = true
                                    }
                                    EqualizerTheme.Haptics.impactLight()
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(EqualizerTheme.Colors.cyanAccent)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Save Current EQ as New Preset")
                                                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white)
                                            Text("Store current 10-band slider gains")
                                                .font(.system(size: 10.5))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(EqualizerTheme.Colors.cyanAccent.opacity(0.12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(EqualizerTheme.Colors.cyanAccent.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                                .pressable()
                                .padding(.horizontal, 16)
                            }
                            
                            if viewModel.customPresets.isEmpty {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "slider.vertical.3")
                                        .font(.system(size: 38))
                                        .foregroundColor(.secondary.opacity(0.6))
                                    Text("No Custom Presets Yet")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(.secondary)
                                    Text("Adjust the sliders and tap 'Save Current EQ' to create one.")
                                        .font(.system(size: 11.5))
                                        .foregroundColor(.secondary.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 36)
                                }
                                Spacer()
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 9) {
                                        ForEach(viewModel.customPresets) { preset in
                                            presetRow(preset: preset, isCustom: true)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 24)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 10)
            }
            .navigationTitle("Equalizer Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(EqualizerTheme.Colors.cyanAccent)
                }
            }
        }
    }
    
    private func tabButton(title: String, index: Int) -> some View {
        let isSelected = selectedTab == index
        return Button(action: {
            withAnimation(EqualizerTheme.AnimationSprings.tactile) {
                selectedTab = index
            }
            EqualizerTheme.Haptics.selection()
        }) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 7.5)
                        .fill(isSelected ? EqualizerTheme.Colors.surfaceElevated : Color.clear)
                        .shadow(color: isSelected ? Color.black.opacity(0.3) : Color.clear, radius: 3)
                )
        }
    }
    
    private func presetRow(preset: EQPreset, isCustom: Bool) -> some View {
        let isSelected = viewModel.activePreset.name == preset.name
        
        return Button(action: {
            withAnimation(EqualizerTheme.AnimationSprings.tactile) {
                viewModel.applyPreset(preset)
            }
            EqualizerTheme.Haptics.success()
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack(spacing: 12) {
                // Preset Icon Circle
                Image(systemName: preset.iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isSelected ? .black : EqualizerTheme.Colors.cyanAccent)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle().fill(isSelected ? EqualizerTheme.Colors.cyanAccent : EqualizerTheme.Colors.cyanAccent.opacity(0.14))
                    )
                
                // Name & Category
                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name)
                        .font(.system(size: 13.5, weight: isSelected ? .bold : .medium, design: .rounded))
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(preset.category.rawValue)
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Mini graphical curve preview
                MiniCurvePreview(gains: preset.gains)
                    .frame(width: 52, height: 22)
                
                if isCustom {
                    Button(action: {
                        withAnimation(EqualizerTheme.AnimationSprings.tactile) {
                            viewModel.deleteCustomPreset(preset)
                        }
                        EqualizerTheme.Haptics.impactMedium()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.85))
                            .padding(6)
                    }
                }
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundColor(EqualizerTheme.Colors.cyanAccent)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? EqualizerTheme.Colors.surfaceElevated : EqualizerTheme.Colors.surfaceTray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? EqualizerTheme.Colors.cyanAccent.opacity(0.6) : EqualizerTheme.Colors.borderHairline, lineWidth: 1)
                    )
            )
        }
        .pressable()
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
            .stroke(EqualizerTheme.Colors.cyanAccent.opacity(0.85), lineWidth: 1.5)
        }
    }
}

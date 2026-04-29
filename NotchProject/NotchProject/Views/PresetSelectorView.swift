import SwiftUI

struct PresetSelectorView: View {
    @Binding var selectedPreset: PresetType?
    var onPresetSelected: (PresetType) -> Void = { _ in }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PresetType.allCases) { preset in
                    let isSelected = selectedPreset == preset

                    Button {
                        withAnimation(.snappy(duration: 0.2)) {
                            selectedPreset = preset
                        }
                        onPresetSelected(preset)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: preset.defaultIcon)
                                .font(.title3)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(isSelected
                                              ? Color(hex: preset.defaultColor)
                                              : Color(hex: preset.defaultColor).opacity(0.15))
                                )
                                .foregroundStyle(isSelected ? .white : Color(hex: preset.defaultColor))

                            Text(preset.defaultName)
                                .font(.caption2)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .foregroundStyle(isSelected ? .primary : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

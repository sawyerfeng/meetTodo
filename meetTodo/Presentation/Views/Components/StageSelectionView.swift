import SwiftUI

struct StageSelectionView: View {
    let selectedStage: InterviewStage?
    let availableStages: [InterviewStage]
    let onSelect: (InterviewStage) -> Void
    
    var body: some View {
        List(availableStages, id: \.self) { stage in
            Button {
                onSelect(stage)
            } label: {
                HStack {
                    Image(systemName: stage.icon)
                        .foregroundColor(stage.color)
                        .frame(width: 30)
                    
                    Text(stage.rawValue)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if stage == selectedStage {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

#Preview {
    StageSelectionView(
        selectedStage: .interview,
        availableStages: InterviewStage.allCases,
        onSelect: { _ in }
    )
} 
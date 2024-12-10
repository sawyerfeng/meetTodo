import SwiftUI

enum StageRowAction {
    case setStatus(StageStatus)
    case editNote
    case update(InterviewStage, Date, StageLocation?)
    case delete
}

struct StageRow: View {
    let item: InterviewStageItem
    let previousStage: InterviewStageItem?
    let availableStages: [InterviewStage]
    let onAction: (StageRowAction) -> Void
    
    private var displayName: String {
        if item.stage == .interview, let round = item.interviewRound {
            return "第\(round)面"
        }
        return item.stage.rawValue
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: item.stage.icon)
                    .font(.title2)
                    .foregroundColor(item.stage.color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.headline)
                    
                    Text(item.date.formatted(.dateTime.month().day().hour().minute()))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !item.note.isEmpty {
                    Button {
                        onAction(.editNote)
                    } label: {
                        Image(systemName: "note.text")
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.vertical, 12)
            
            if let previousStage = previousStage {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 2, height: 20)
                    .padding(.leading, 19)
            }
        }
    }
}

#Preview {
    StageRow(
        item: InterviewStageItem(
            stage: .interview,
            interviewRound: 1,
            date: Date(),
            note: "这是一个测试笔记"
        ),
        previousStage: InterviewStageItem(
            stage: .resume,
            date: Date().addingTimeInterval(-86400)
        ),
        availableStages: InterviewStage.allCases,
        onAction: { _ in }
    )
    .padding()
} 
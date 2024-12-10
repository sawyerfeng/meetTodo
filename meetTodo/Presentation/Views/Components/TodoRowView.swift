import SwiftUI

struct TodoRowView: View {
    let item: Item
    let stageData: InterviewStageData
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: stageData.date)
    }
    
    var stageName: String {
        if stageData.stage == InterviewStage.interview.rawValue,
           let round = stageData.interviewRound {
            return "第\(round)面"
        }
        return InterviewStage(rawValue: stageData.stage)?.rawValue ?? stageData.stage
    }
    
    var stageIcon: String {
        if let stage = InterviewStage(rawValue: stageData.stage) {
            return stage.icon
        }
        return "questionmark.circle"
    }
    
    var stageColor: Color {
        if let stage = InterviewStage(rawValue: stageData.stage) {
            return stage.color
        }
        return .gray
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: stageIcon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(stageColor)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.companyName)
                    .font(.headline)
                Text(stageName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(timeString)
                .font(.title3.bold())
                .foregroundColor(stageColor)
                .frame(minWidth: 60)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    TodoRowView(
        item: Item(
            companyName: "阿里巴巴",
            companyIcon: "building.2.fill"
        ),
        stageData: InterviewStageData(
            stage: InterviewStage.interview.rawValue,
            interviewRound: 1,
            date: Date()
        )
    )
    .padding()
} 
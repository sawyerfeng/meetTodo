import SwiftUI
import SwiftData

struct TodoView: View {
    @Query(sort: [
        SortDescriptor<Item>(\.timestamp, order: .reverse)
    ]) private var items: [Item]
    
    var todayTodos: [(Item, InterviewStageData)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return items.flatMap { item in
            item.stages.filter { stageData in
                let stageDate = calendar.startOfDay(for: stageData.date)
                return stageDate >= today && stageDate < tomorrow &&
                       (stageData.stage == InterviewStage.interview.rawValue ||
                        stageData.stage == InterviewStage.written.rawValue ||
                        stageData.stage == InterviewStage.hrInterview.rawValue) &&
                       stageData.status == StageStatus.pending.rawValue
            }.map { (item, $0) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if todayTodos.isEmpty {
                    ContentUnavailableView("今日无待办", 
                        systemImage: "checkmark.circle",
                        description: Text("暂时没有面试或笔试安排")
                    )
                } else {
                    ForEach(todayTodos, id: \.1.id) { item, stageData in
                        NavigationLink(destination: CompanyDetailView(item: item)) {
                            TodoRowView(item: item, stageData: stageData)
                        }
                    }
                }
            }
            .navigationTitle("今日待办")
        }
    }
}

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
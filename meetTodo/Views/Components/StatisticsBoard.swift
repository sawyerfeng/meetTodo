import SwiftUI

struct StatisticsBoard: View {
    let applicationCount: Int
    let writtenCount: Int
    let interviewCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            StatisticCard(title: "投递公司", count: applicationCount, color: .red)
            StatisticCard(title: "笔试", count: writtenCount, color: .orange)
            StatisticCard(title: "面试", count: interviewCount, color: .blue)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

private struct StatisticCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.subheadline)
            Text("\(count)")
                .font(.title.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(12)
    }
} 
import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var sessions: [Session]

    private var totalSessions: Int {
        sessions.count
    }

    // 将积分转换为人民币
    private func pointsToYuan(_ points: Double, session: Session) -> Double {
        guard session.pointsPerHundredBB > 0, session.bigBlind > 0 else { return 0 }
        // 积分 → BB
        let bb = points / (session.pointsPerHundredBB / 100.0)
        // BB → 人民币
        return bb * session.bigBlind
    }

    private var totalBuyInYuan: Double {
        sessions.reduce(0) { total, session in
            total + pointsToYuan(session.buyIn, session: session)
        }
    }

    private var totalCashOutYuan: Double {
        sessions.reduce(0) { total, session in
            total + pointsToYuan(session.cashOut, session: session)
        }
    }

    private var totalProfitYuan: Double {
        sessions.reduce(0) { total, session in
            total + pointsToYuan(session.profit, session: session)
        }
    }

    private var winRate: Double {
        guard totalSessions > 0 else { return 0 }
        let winningSessions = sessions.filter { $0.profit > 0 }.count
        return Double(winningSessions) / Double(totalSessions) * 100
    }

    var body: some View {
        NavigationStack {
            List {
                Section("总体统计") {
                    StatRow(title: "总场次", value: "\(totalSessions)")
                    StatRow(title: "总买入", value: String(format: "%.2f 元", totalBuyInYuan))
                    StatRow(title: "总退筹", value: String(format: "%.2f 元", totalCashOutYuan))

                    HStack {
                        Text("总盈利")
                            .foregroundColor(.primary)
                        Spacer()
                        HStack(spacing: 4) {
                            Text(totalProfitYuan >= 0 ? "+\(totalProfitYuan, specifier: "%.2f")" : "\(totalProfitYuan, specifier: "%.2f")")
                                .fontWeight(.semibold)
                                .foregroundColor(totalProfitYuan >= 0 ? .green : .red)
                            Text("元")
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                    }

                    StatRow(title: "胜率", value: String(format: "%.1f%%", winRate))
                }

                if !sessions.isEmpty {
                    Section("最近记录") {
                        ForEach(sessions.prefix(5)) { session in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    if !session.sessionName.isEmpty {
                                        Text(session.sessionName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    if !session.location.isEmpty {
                                        Text(session.location)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text(session.playedAt, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                let profitYuan = pointsToYuan(session.profit, session: session)
                                HStack(spacing: 4) {
                                    Text(profitYuan >= 0 ? "+\(profitYuan, specifier: "%.2f")" : "\(profitYuan, specifier: "%.2f")")
                                        .font(.subheadline)
                                        .foregroundColor(profitYuan >= 0 ? .green : .red)
                                    Text("元")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("统计")
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
    }
}

import SwiftUI
import SwiftData

struct EndSessionView: View {
    @Environment(\.dismiss) private var dismiss
    let session: Session

    @State private var buyInAmount: String = ""
    @State private var cashOutAmount: String = ""
    @State private var useBBUnit = false  // true: 输入为BB, false: 输入为积分

    // 存到 Session 中的值，统一视为“积分”
    private var buyInPoints: Double {
        let amount = Double(buyInAmount) ?? 0
        if useBBUnit {
            return bbToPoints(amount)
        } else {
            return amount
        }
    }

    private var cashOutPoints: Double {
        let amount = Double(cashOutAmount) ?? 0
        if useBBUnit {
            return bbToPoints(amount)
        } else {
            return amount
        }
    }

    private var profit: Double {
        cashOutPoints - buyInPoints
    }

    private var profitBB: Double {
        pointsToBB(profit)
    }

    private var profitYuan: Double {
        profitBB * session.bigBlind
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("使用大盲(BB)为输入单位", isOn: $useBBUnit)
                        .tint(.blue)

                    if useBBUnit && session.pointsPerHundredBB <= 0 {
                        Text("⚠️ 未设置BB换算比例，将无法正确换算")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Section("买入") {
                    HStack {
                        TextField(useBBUnit ? "买入（BB）" : "买入（积分）", text: $buyInAmount)
                            .keyboardType(.decimalPad)
                        Text(useBBUnit ? "BB" : "分")
                            .foregroundColor(.secondary)
                    }

                    if !buyInAmount.isEmpty {
                        HStack {
                            Text("折算结果")
                                .foregroundColor(.secondary)
                            Spacer()
                            if useBBUnit {
                                // 已输入 BB，展示对应积分
                                Text("\(buyInPoints, specifier: "%.0f") 分")
                                    .foregroundColor(.secondary)
                            } else {
                                // 已输入积分，展示对应 BB
                                let points = Double(buyInAmount) ?? 0
                                Text("\(pointsToBB(points), specifier: "%.1f") BB")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .font(.caption)
                    }
                }

                Section("退筹") {
                    HStack {
                        TextField(useBBUnit ? "退筹（BB）" : "退筹（积分）", text: $cashOutAmount)
                            .keyboardType(.decimalPad)
                        Text(useBBUnit ? "BB" : "分")
                            .foregroundColor(.secondary)
                    }

                    if !cashOutAmount.isEmpty {
                        HStack {
                            Text("折算结果")
                                .foregroundColor(.secondary)
                            Spacer()
                            if useBBUnit {
                                Text("\(cashOutPoints, specifier: "%.0f") 分")
                                    .foregroundColor(.secondary)
                            } else {
                                let points = Double(cashOutAmount) ?? 0
                                Text("\(pointsToBB(points), specifier: "%.1f") BB")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .font(.caption)
                    }
                }

                Section("盈亏") {
                    HStack {
                        Text("本场盈亏")
                            .font(.headline)
                        Spacer()
                        Text(profitYuan >= 0 ? "+\(profitYuan, specifier: "%.2f")" : "\(profitYuan, specifier: "%.2f")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(profitYuan >= 0 ? .green : .red)
                        Text("元")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }

                    if session.pointsPerHundredBB > 0 {
                        HStack {
                            Text("积分")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(profit >= 0 ? "+\(profit, specifier: "%.0f") 分" : "\(profit, specifier: "%.0f") 分")
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)

                        HStack {
                            Text("大盲")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(profitBB >= 0 ? "+\(profitBB, specifier: "%.1f") BB" : "\(profitBB, specifier: "%.1f") BB")
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                    }
                }
            }
            .navigationTitle("结束牌局")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        endSession()
                    }
                    .fontWeight(.semibold)
                    .disabled(useBBUnit && session.pointsPerHundredBB <= 0)
                }
            }
        }
    }

    private func endSession() {
        session.buyIn = buyInPoints
        session.cashOut = cashOutPoints
        session.endTime = Date()  // 记录结束时间
        session.isActive = false
        dismiss()
    }

    private func bbToPoints(_ bb: Double) -> Double {
        guard session.pointsPerHundredBB > 0 else { return 0 }
        return bb / 100.0 * session.pointsPerHundredBB
    }

    private func pointsToBB(_ points: Double) -> Double {
        guard session.pointsPerHundredBB > 0 else { return 0 }
        return points / session.pointsPerHundredBB * 100.0
    }
}

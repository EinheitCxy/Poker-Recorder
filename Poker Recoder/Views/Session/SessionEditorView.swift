import SwiftUI
import SwiftData

struct SessionEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let session: Session?

    @State private var sessionName: String
    @State private var playedAt: Date
    @State private var blindLevel: String
    @State private var pointsPerHundredBBText: String
    @State private var playerCount: Double = 6
    @State private var hasStraddle: Bool = false
    @State private var note: String

    init(session: Session? = nil) {
        self.session = session
        _sessionName = State(initialValue: session?.sessionName ?? "")
        _playedAt = State(initialValue: session?.playedAt ?? Date())
        _blindLevel = State(initialValue: session?.blindLevel ?? "")
        if let value = session?.pointsPerHundredBB, value > 0 {
            _pointsPerHundredBBText = State(initialValue: String(format: "%.0f", value))
        } else {
            _pointsPerHundredBBText = State(initialValue: "")
        }
        _note = State(initialValue: session?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("牌局名称", text: $sessionName)
                    DatePicker("牌谱日期", selection: $playedAt, displayedComponents: [.date])

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("人数")
                            Spacer()
                            Text("\(Int(playerCount))")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $playerCount, in: 2...10, step: 1)
                            .tint(.red)
                    }

                    TextField("盲注级别 (例如: 2/4)", text: $blindLevel)
                        .keyboardType(.numbersAndPunctuation)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            TextField("每 100BB 对应积分", text: $pointsPerHundredBBText)
                                .keyboardType(.numberPad)
                            Text("分")
                                .foregroundColor(.secondary)
                        }
                        Text("例如: 盲注1/2元，100BB=200元=1000积分，则输入1000")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Toggle("Straddle", isOn: $hasStraddle)
                }

                Section("备注") {
                    TextEditor(text: $note)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(session == nil ? "开始新牌局" : "编辑牌局")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("开始") {
                        saveSession()
                    }
                }
            }
        }
    }

    private func saveSession() {
        let bigBlindValue = parseBigBlind(from: blindLevel)
        let pointsPerHundredBBValue = Double(pointsPerHundredBBText) ?? 0

        if let session = session {
            // 编辑现有Session
            session.sessionName = sessionName
            session.playedAt = playedAt
            session.blindLevel = blindLevel
            session.bigBlind = bigBlindValue
            session.pointsPerHundredBB = pointsPerHundredBBValue
            session.note = note
        } else {
            // 创建新Session（进行中状态）
            let newSession = Session(
                playedAt: playedAt,
                sessionName: sessionName,
                blindLevel: blindLevel,
                bigBlind: bigBlindValue,
                pointsPerHundredBB: pointsPerHundredBBValue,
                note: note,
                isActive: true
            )
            modelContext.insert(newSession)

            // 根据人数自动初始化玩家
            let totalPlayers = Int(playerCount)
            for i in 0..<totalPlayers {
                let playerName: String
                if i == 0 {
                    playerName = "我"
                } else {
                    playerName = "玩家\(i + 1)"
                }

                let player = Player(
                    name: playerName,
                    seatNumber: i,
                    style: "TAG",
                    level: "Reg"
                )
                player.session = newSession
                modelContext.insert(player)
            }
        }
        dismiss()
    }

    private func parseBigBlind(from blindLevel: String) -> Double {
        let components = blindLevel.split(separator: "/")
        if components.count == 2, let bigBlind = Double(components[1].trimmingCharacters(in: .whitespaces)) {
            return bigBlind
        }
        return 0
    }
}

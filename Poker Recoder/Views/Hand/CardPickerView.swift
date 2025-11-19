import SwiftUI

struct CardPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCards: String
    let maxCards: Int // 2 for hole cards, 3 for flop, 1 for turn/river

    @State private var selected: [Card] = []
    @State private var selectedSuit: String = "s"

    private let ranks = ["A", "K", "Q", "J", "T", "9", "8", "7", "6", "5", "4", "3", "2"]
    private let suits: [(String, Color)] = [
        ("s", .gray),    // 黑桃
        ("h", .red),     // 红桃
        ("d", .blue),    // 方块
        ("c", .green)    // 梅花
    ]
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    init(selectedCards: Binding<String>, maxCards: Int) {
        self._selectedCards = selectedCards
        self.maxCards = maxCards

        // 解析已有的牌
        var cards: [Card] = []
        let cardString = selectedCards.wrappedValue
        var i = 0
        while i < cardString.count - 1 {
            let start = cardString.index(cardString.startIndex, offsetBy: i)
            let rank = String(cardString[start])
            let suit = String(cardString[cardString.index(after: start)])
            cards.append(Card(rank: rank, suit: suit))
            i += 2
        }
        _selected = State(initialValue: cards)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // 已选择的牌区域
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(maxCards == 2 ? "已选手牌" : "已选公共牌")
                            .font(.headline)
                        Spacer()
                        Text("已选 \(selected.count)/\(maxCards)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 10) {
                        ForEach(selected) { card in
                            CardView(card: card, size: 60)
                                .onTapGesture {
                                    selected.removeAll { $0.id == card.id }
                                }
                        }

                        let remainingSlots = max(0, maxCards - selected.count)
                        ForEach(0..<remainingSlots, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                .foregroundColor(.gray.opacity(0.4))
                                .frame(width: 60, height: 84)
                        }
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .glassCard()
                .padding(.horizontal)

                // 花色选择器
                HStack(spacing: 12) {
                    ForEach(suits, id: \.0) { suit, _ in
                        Button {
                            selectedSuit = suit
                        } label: {
                            Text(Card(rank: "A", suit: suit).suitSymbol)
                                .font(.system(size: 32))
                                .foregroundColor(Card(rank: "A", suit: suit).isRed ? .red : .black)
                                .frame(width: 60, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedSuit == suit ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedSuit == suit ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        }
                    }
                }
                .padding(.horizontal)

                // 所有牌选择区：网格布局
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(ranks, id: \.self) { rank in
                            let card = Card(rank: rank, suit: selectedSuit)
                            let isSelected = selected.contains { $0.rank == rank && $0.suit == selectedSuit }
                            let isFull = selected.count >= maxCards

                            CardView(card: card, size: 44)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                                )
                                .opacity(isFull && !isSelected ? 0.4 : 1.0)
                                .onTapGesture {
                                    if isSelected {
                                        selected.removeAll { $0.rank == rank && $0.suit == selectedSuit }
                                    } else if !isFull {
                                        selected.append(card)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                // 底部操作栏
                HStack(spacing: 12) {
                    Button("全部清除") {
                        selected.removeAll()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)

                    Spacer()

                    Button("取消") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)

                    Button("确认") {
                        selectedCards = selected.map { "\($0.rank)\($0.suit)" }.joined()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selected.isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .padding(.top, 12)
            .navigationTitle(maxCards == 2 ? "选择手牌" : "选择公共牌")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct Card: Identifiable {
    let id = UUID()
    let rank: String
    let suit: String
}

struct CardView: View {
    let card: Card
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(card.rank)
                    .font(.system(size: size * 0.55, weight: .bold))
                    .foregroundColor(card.isRed ? .red : .black)

                Text(card.suitSymbol)
                    .font(.system(size: size * 0.4))
                    .foregroundColor(card.isRed ? .red : .black)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(6)
        }
        .frame(width: size, height: size * 1.4)
    }
}

extension Card {
    var suitSymbol: String {
        switch suit {
        case "s": return "♠︎"
        case "h": return "♥︎"
        case "d": return "♦︎"
        case "c": return "♣︎"
        default:  return "?"
        }
    }

    var isRed: Bool {
        suit == "h" || suit == "d"
    }
}

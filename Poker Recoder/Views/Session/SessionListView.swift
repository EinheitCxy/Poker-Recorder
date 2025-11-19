import SwiftUI
import SwiftData

struct SessionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Session.playedAt, order: .reverse) private var sessions: [Session]
    @State private var showingEditor = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(sessions) { session in
                    NavigationLink(destination: SessionDetailView(session: session)) {
                        SessionRowView(session: session)
                    }
                }
                .onDelete(perform: deleteSessions)
            }
            .navigationTitle("牌局记录")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                SessionEditorView()
            }
        }
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sessions[index])
        }
    }
}

struct SessionRowView: View {
    let session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                let title = session.sessionName
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                Text(title.isEmpty ? session.location : title)
                    .font(.headline)
                    .foregroundColor(.primary)

                if session.isActive {
                    Text("进行中")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }

                Spacer()

                if !session.isActive {
                    Text(session.profit >= 0 ? "+\(session.profit, specifier: "%.0f")" : "\(session.profit, specifier: "%.0f")")
                        .font(.headline)
                        .foregroundColor(session.profit >= 0 ? .green : .red)
                } else {
                    Text("\(session.hands.count)手")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Text(session.playedAt, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("•")
                    .foregroundColor(.secondary)
                Text(session.blindLevel)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

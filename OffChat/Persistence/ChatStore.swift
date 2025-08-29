import Foundation

final class ChatStore {
    static let shared = ChatStore()
    private let threadsKey = "offchat_threads_v1"
    private let queue = DispatchQueue(label: "ChatStore.queue", qos: .userInitiated)

    private init() {}

    func loadThreads() -> [ChatThread] {
        guard let data = UserDefaults.standard.data(forKey: threadsKey) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([ChatThread].self, from: data)) ?? []
    }

    func save(threads: [ChatThread]) {
        queue.async { [threads] in
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(threads) {
                UserDefaults.standard.set(data, forKey: self.threadsKey)
            }
        }
    }
    
    func deleteThread(_ threadId: UUID) {
        var savedThreads = loadThreads()
        savedThreads.removeAll { $0.id == threadId }
        
        do {
            let data = try JSONEncoder().encode(savedThreads)
            UserDefaults.standard.set(data, forKey: threadsKey)
        } catch {
            print("Failed to delete thread: \(error)")
        }
    }
    
    func getThread(for peerID: String) -> ChatThread? {
        let threads = loadThreads()
        return threads.first { $0.peerID == peerID }
    }
    
    func saveMessage(_ message: ChatMessage, to threadId: UUID) {
        var savedThreads = loadThreads()
        
        if let index = savedThreads.firstIndex(where: { $0.id == threadId }) {
            savedThreads[index].addMessage(message)
            
            do {
                let data = try JSONEncoder().encode(savedThreads)
                UserDefaults.standard.set(data, forKey: threadsKey)
            } catch {
                print("Failed to save message: \(error)")
            }
        }
    }
}
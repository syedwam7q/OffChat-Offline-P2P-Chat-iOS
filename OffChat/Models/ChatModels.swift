import Foundation
import UIKit

enum MessageType: String, Codable {
    case text
    case image
    case video
    case audio
    case file
    case location
    case contact
}

enum MessageStatus: String, Codable {
    case sending
    case sent
    case delivered
    case read
    case failed
}

struct MediaAttachment: Codable, Equatable {
    let filename: String
    let mimeType: String
    let data: Data
    let thumbnailData: Data?
    
    init(filename: String, mimeType: String, data: Data, thumbnailData: Data? = nil) {
        self.filename = filename
        self.mimeType = mimeType
        self.data = data
        self.thumbnailData = thumbnailData
    }
}

struct ChatMessage: Codable, Equatable {
    let id: UUID
    let sender: String
    let text: String
    let timestamp: Date
    let messageType: MessageType
    let attachment: MediaAttachment?
    let status: MessageStatus
    let replyToMessageID: UUID?

    init(id: UUID = UUID(), sender: String, text: String, timestamp: Date = Date(), messageType: MessageType = .text, attachment: MediaAttachment? = nil, status: MessageStatus = .sending, replyToMessageID: UUID? = nil) {
        self.id = id
        self.sender = sender
        self.text = text
        self.timestamp = timestamp
        self.messageType = messageType
        self.attachment = attachment
        self.status = status
        self.replyToMessageID = replyToMessageID
    }
    
    // Helper computed properties
    var isMediaMessage: Bool {
        return messageType == .image || messageType == .file
    }
    
    var hasAttachment: Bool {
        return attachment != nil
    }
    
    var displayText: String {
        switch messageType {
        case .text:
            return text
        case .image:
            return text.isEmpty ? "📷 Photo" : text
        case .file:
            return text.isEmpty ? "📎 \(attachment?.filename ?? "File")" : text
        case .location:
            return text.isEmpty ? "📍 Location" : text
        case .contact:
            return text.isEmpty ? "👤 Contact" : text
        case .video, .audio:
            return text // Placeholder for future implementation
        }
    }
}

struct ChatThread: Codable, Equatable {
    let id: UUID
    let peerID: String
    var title: String
    var messages: [ChatMessage]

    init(id: UUID = UUID(), peerID: String, title: String, messages: [ChatMessage] = []) {
        self.id = id
        self.peerID = peerID
        self.title = title
        self.messages = messages
    }
    
    mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
    }
}
# OffChat Architecture and Design

This document outlines the architecture, design patterns, and technical decisions behind the OffChat application.

## System Architecture

OffChat follows the Model-View-Controller (MVC) architectural pattern, with clear separation of concerns between data models, user interface components, and business logic.

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        OffChat App                           │
└───────────────┬─────────────────────────────┬───────────────┘
                │                             │
┌───────────────▼─────────────┐   ┌──────────▼───────────────┐
│      UI Layer (Views)       │   │  Controller Layer         │
│                             │   │                           │
│  - MessageCell              │   │  - ChatListViewController │
│  - ThreadCell               │   │  - ChatViewController     │
│  - Input Views              │◄──┼──► - Other ViewControllers│
│  - Navigation Components    │   │                           │
└─────────────┬───────────────┘   └──────────┬───────────────┘
              │                               │
              │                               │
┌─────────────▼───────────────┐   ┌──────────▼───────────────┐
│    Model Layer              │   │  Manager Layer            │
│                             │   │                           │
│  - ChatMessage              │   │  - PeerManager            │
│  - ChatThread               │◄──┼──► - ChatStore            │
│  - User/Profile             │   │                           │
└─────────────────────────────┘   └───────────────────────────┘
              ▲                               ▲
              │                               │
              │                               │
┌─────────────▼───────────────────────────────▼───────────────┐
│                  System Frameworks                           │
│                                                             │
│  - MultipeerConnectivity (P2P networking)                   │
│  - UserDefaults (Persistence)                               │
│  - UIKit (User Interface)                                   │
└─────────────────────────────────────────────────────────────┘
```

## Core Components

### Models

The data layer consists of the following key models:

#### ChatMessage
```swift
struct ChatMessage: Codable {
    let id: UUID
    let text: String
    let senderID: String
    let timestamp: Date
    let isFromMe: Bool
}
```

#### ChatThread
```swift
struct ChatThread: Codable {
    let id: UUID
    let peerID: String
    let displayName: String
    var messages: [ChatMessage]
    var lastUpdated: Date
}
```

### Views

The presentation layer includes custom UI components:

#### MessageCell
- Displays individual chat messages
- Handles different message alignments (left/right)
- Shows timestamp and delivery status

#### ThreadCell
- Displays chat thread summary in the list
- Shows peer name and last message preview
- Indicates connection status

### Controllers

The controller layer manages user interactions and coordinates between models and views:

#### ChatListViewController
- Displays the list of available peers and active chat threads
- Handles peer discovery and initial connections
- Provides navigation to individual chat threads

#### ChatViewController
- Manages the chat interface for a specific peer
- Handles sending and receiving messages
- Updates the UI when new messages arrive

### Managers

The business logic layer contains service classes that handle core functionality:

#### PeerManager
- Manages the MultipeerConnectivity session
- Handles device advertising and browsing
- Provides methods for sending and receiving data
- Maintains connection state

#### ChatStore
- Handles persistence of chat threads and messages
- Provides methods for saving and retrieving chat data
- Uses UserDefaults with JSON serialization

## Key Design Patterns

### Delegate Pattern
Used extensively for communication between components:
- PeerManagerDelegate: Notifies controllers about peer discovery and message events
- ChatViewControllerDelegate: Handles user interactions in the chat interface

### Singleton Pattern
Applied selectively for global access to key managers:
- PeerManager: Single instance manages all peer connections
- ChatStore: Single instance handles all persistence operations

### Observer Pattern
Implemented through NotificationCenter for system-wide events:
- Connection state changes
- New message notifications
- Background/foreground transitions

## Data Flow

### Message Sending Process
1. User enters text in ChatViewController
2. ChatViewController creates a ChatMessage object
3. ChatViewController calls PeerManager.send(message:to:)
4. PeerManager serializes the message to Data
5. PeerManager uses MCSession to send data to the peer
6. ChatViewController adds the message to the local thread
7. ChatStore saves the updated thread

### Message Receiving Process
1. PeerManager receives data via MCSessionDelegate
2. PeerManager deserializes the data to a ChatMessage
3. PeerManager notifies delegates of the new message
4. ChatViewController updates the UI with the new message
5. ChatStore saves the updated thread

## Networking Architecture

OffChat uses Apple's MultipeerConnectivity framework for peer-to-peer communication:

### Service Advertisement
- Uses MCNearbyServiceAdvertiser to broadcast device availability
- Custom service type identifier: "offchat-service"
- Includes minimal discovery info (device name)

### Peer Discovery
- Uses MCNearbyServiceBrowser to find nearby devices
- Automatically invites discovered peers to connect
- Handles invitation acceptance/rejection

### Session Management
- Uses MCSession for reliable data transfer
- Monitors connection state changes
- Supports both reliable and unreliable message delivery modes

## Persistence Strategy

OffChat uses a lightweight persistence approach:

### UserDefaults Storage
- Chat threads and messages are serialized to JSON
- Stored in UserDefaults under unique keys
- Loaded on app launch

### Data Structure
```
UserDefaults
└── "chat_threads" (Array of ChatThread objects)
    ├── Thread 1
    │   ├── id
    │   ├── peerID
    │   ├── displayName
    │   ├── lastUpdated
    │   └── messages (Array of ChatMessage objects)
    │       ├── Message 1
    │       ├── Message 2
    │       └── ...
    ├── Thread 2
    └── ...
```

## UI Architecture

### Navigation Flow
```
AppDelegate/SceneDelegate
        │
        ▼
ChatListViewController (Root)
        │
        ├─────► ChatViewController
        │
        └─────► [Future: SettingsViewController]
```

### UI Implementation
- Programmatic UI using Auto Layout
- No Interface Builder or Storyboards
- Custom UI components for consistent styling

## Security Considerations

### Data Privacy
- All communication happens directly between devices
- No data is sent to external servers
- Messages are stored only on the local device

### Connection Security
- MultipeerConnectivity provides encryption for all data transfers
- Invitation-based connection model requires user approval
- Service type is unique to prevent cross-app communication

## Performance Optimizations

### Battery Usage
- Peer discovery is optimized to balance discovery speed and power consumption
- Connection monitoring adapts based on app state

### Memory Management
- Message history is loaded incrementally
- Large chat threads are paginated to minimize memory usage

## Future Architecture Considerations

As outlined in the roadmap, future enhancements will require architectural changes:

### Core Data Migration
- Replace UserDefaults with Core Data for more robust persistence
- Enable more complex querying and relationship modeling
- Support for larger message history

### Media Sharing
- Add support for binary data transfers (images, files)
- Implement progress tracking for large transfers
- Add media caching and management

### Group Chat Support
- Extend PeerManager to handle multiple simultaneous connections
- Modify the data model to support multi-participant threads
- Implement message broadcasting to multiple peers

## Technical Debt and Limitations

Current known limitations in the architecture:

1. **UserDefaults Scalability**: Not suitable for large message histories
2. **Background Mode**: Limited functionality when app is in background
3. **Connection Reliability**: Reconnection handling needs improvement
4. **Error Handling**: More robust error recovery mechanisms needed
5. **Testing Coverage**: Lack of comprehensive unit and UI tests

## Appendix: Key Classes and Methods

### PeerManager
```swift
class PeerManager: NSObject {
    static let shared = PeerManager()
    
    // Core functionality
    func startAdvertising()
    func startBrowsing()
    func send(message: ChatMessage, to peerID: String) -> Bool
    
    // Delegate methods
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID)
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?)
}
```

### ChatStore
```swift
class ChatStore {
    static let shared = ChatStore()
    
    // Core functionality
    func saveThread(_ thread: ChatThread)
    func getThread(for peerID: String) -> ChatThread?
    func getAllThreads() -> [ChatThread]
    func addMessage(_ message: ChatMessage, to threadID: UUID)
}
```
# OffChat (Offline P2P Chat)

A simple iOS chat app that works without Internet using MultipeerConnectivity over Bluetooth / local Wi‑Fi. Built with UIKit and Swift.

## Features
- Peer discovery and secure connections (Bluetooth / Wi‑Fi / P2P)
- Text messaging (send/receive)
- Local chat history (UserDefaults JSON)
- Basic thread list and chat UI

## Requirements
- Xcode 15+
- iOS 12.0+
- Two or more physical iOS devices for real P2P testing (Simulator won’t discover peers)

## Build with XcodeGen (recommended)
1. Install XcodeGen (if not installed):
   - `brew install xcodegen`
2. Generate the Xcode project:
   - `cd OffChat`
   - `xcodegen generate`
3. Open the project:
   - `open OffChat.xcodeproj`
4. Set your Development Team in the project settings (Signing & Capabilities) if needed.
5. Build and run on two devices. Keep the app in foreground to auto-discover peers.

## Notes
- MultipeerConnectivity uses both Bluetooth and infrastructure/peer-to-peer Wi‑Fi where available.
- App asks for Local Network permission (iOS 14+). Ensure both devices grant it.
- Start a chat from the thread list using the "New Chat" button once a peer is connected.

## Structure
- AppDelegate / SceneDelegate: App bootstrap
- Managers/PeerManager: Handles MultipeerConnectivity session, advertise, browse, send/receive
- Models: ChatMessage, ChatThread
- Persistence/ChatStore: JSON storage in UserDefaults
- Controllers: ChatList (threads) and Chat (messages)
- Views/MessageCell: simple chat bubble cell

## Future Enhancements
- Group chat by sending to multiple peers simultaneously
- Persistent Core Data storage
- Attachments (resources/streams)
- Presence/connection status UI
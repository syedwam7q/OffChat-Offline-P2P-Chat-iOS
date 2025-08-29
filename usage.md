# OffChat Usage Guide

This guide explains how to use the OffChat application for peer-to-peer messaging without internet connectivity.

## Getting Started

### App Launch and Initial Setup

1. Launch the OffChat app on your iOS device
2. The app will automatically start advertising your device to nearby peers
3. Simultaneously, it will begin searching for other devices running OffChat

### Permissions

When you first launch OffChat, you may be prompted for the following permissions:

- **Bluetooth**: Required for device discovery and communication
- **Local Network**: Required on iOS 14+ for Wi-Fi based peer-to-peer connectivity

> **Important**: For OffChat to function properly, you must grant these permissions on all devices that will communicate with each other.

## Discovering and Connecting to Peers

### Viewing Available Peers

1. Available peers will appear automatically in the main chat list screen
2. Each discovered peer will display with their device name (e.g., "John's iPhone")
3. The connection status will be indicated next to each peer

### Initiating a Chat

1. Tap on a peer's name in the list to open a chat thread with them
2. If this is your first time connecting to this peer, a connection invitation will be sent
3. The peer must accept the invitation on their device to establish the connection
4. Once connected, the chat interface will open

### Managing Connections

- Peers will remain in your chat list as long as they are within range
- If a peer moves out of range, they will be marked as disconnected
- When a previously connected peer comes back in range, OffChat will attempt to reconnect automatically

## Sending and Receiving Messages

### Text Messaging

1. In an active chat thread, type your message in the text field at the bottom of the screen
2. Tap the send button (arrow icon) to transmit the message
3. Sent messages appear on the right side of the screen in blue bubbles
4. Received messages appear on the left side in gray bubbles

### Message Status

Messages in OffChat can have the following statuses:

- **Sending**: Message is being transmitted to the peer
- **Sent**: Message has been successfully delivered to the peer's device
- **Failed**: Message could not be delivered (peer may be out of range)

> **Note**: Currently, OffChat only supports text messages. Media sharing capabilities will be added in future updates.

## Managing Chat History

### Viewing Past Conversations

1. All messages are stored locally on your device
2. To view past conversations, simply open the chat thread with the relevant peer
3. Scroll up to see older messages

### Chat Persistence

- Chat history is preserved even when you close and reopen the app
- Messages are stored using local device storage (UserDefaults)
- There is currently no option to delete individual messages or clear chat history

## Best Practices for Optimal Performance

### Maintaining Connectivity

- **Keep the app in foreground**: OffChat works best when the app is active and in the foreground on both devices
- **Stay within range**: Maintain a reasonable distance between devices (typically within 30 feet/10 meters for Bluetooth)
- **Avoid obstacles**: Physical barriers like walls can reduce the effective range

### Battery Considerations

- Continuous use of Bluetooth and Wi-Fi for peer discovery can impact battery life
- Consider closing the app when not actively messaging to conserve battery

### Privacy and Security

- All communication in OffChat happens directly between devices
- No data is sent to external servers or stored in the cloud
- Be mindful of who you connect with, as the app will display your device name to nearby users

## Troubleshooting

### Peer Discovery Issues

If you're having trouble discovering peers:

1. Ensure both devices have Bluetooth enabled
2. Verify that Local Network permission is granted
3. Make sure both devices are running the OffChat app in the foreground
4. Try toggling Bluetooth off and on again
5. Restart the app on both devices

### Connection Problems

If you can see a peer but can't connect:

1. Check that both devices have accepted any connection invitations
2. Ensure neither device has Bluetooth or Wi-Fi restrictions enabled
3. Move the devices closer together
4. Restart the connection process by selecting the peer again

### Message Delivery Failures

If messages aren't being delivered:

1. Verify that the peer is still connected (check the status indicator)
2. Ensure both devices are within range
3. Try reconnecting to the peer
4. Restart the app on both devices

## Advanced Features

### Using OffChat in Different Environments

- **Outdoor settings**: Works best with direct line of sight between devices
- **Indoor environments**: Effective within rooms, but walls and floors may reduce range
- **Crowded areas**: May experience reduced range due to interference from other devices

## Upcoming Features

Future versions of OffChat will include:

- Media sharing (photos, videos, files)
- Group chat capabilities
- Custom user profiles
- Enhanced message status indicators
- Background mode operation
- End-to-end encryption

For more information on planned features, see the [Project Roadmap](project_story.md#next-steps-and-future-enhancements).
import Foundation
import UIKit
import MultipeerConnectivity

protocol PeerManagerDelegate: AnyObject {
    func peerManager(_ manager: PeerManager, didReceive message: ChatMessage, from peerID: MCPeerID)
    func peerManager(_ manager: PeerManager, peerListChanged peers: [MCPeerID])
    func peerManager(_ manager: PeerManager, didReceive profile: UserProfile, from peerID: MCPeerID)
    func peerManager(_ manager: PeerManager, connectionStateChanged state: MCSessionState, for peer: MCPeerID)
}

enum PeerMessageType: String, Codable {
    case chatMessage = "chat"
    case profile = "profile"
    case profileRequest = "profile_request"
}

struct PeerMessage: Codable {
    let type: PeerMessageType
    let chatMessage: ChatMessage?
    let profile: UserProfile?
    let timestamp: Date
    
    init(chatMessage: ChatMessage) {
        self.type = .chatMessage
        self.chatMessage = chatMessage
        self.profile = nil
        self.timestamp = Date()
    }
    
    init(profile: UserProfile) {
        self.type = .profile
        self.chatMessage = nil
        self.profile = profile
        self.timestamp = Date()
    }
    
    init(profileRequest: Bool = true) {
        self.type = .profileRequest
        self.chatMessage = nil
        self.profile = nil
        self.timestamp = Date()
    }
}

final class PeerManager: NSObject {
    static let serviceType = "offchat-p2p"

    let myPeerID: MCPeerID
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser

    weak var delegate: PeerManagerDelegate?
    
    // Connection management
    private var reconnectionTimer: Timer?
    private var pendingConnections: Set<MCPeerID> = []
    private var connectionRetryCount: [String: Int] = [:]
    private let maxRetryAttempts = 5
    private var backoffMultiplier: [String: Double] = [:]
    private let baseBackoffInterval: TimeInterval = 2.0
    private var isInBackground = false
    private var networkQualityTimer: Timer?
    
    // Profile caching
    private var peerProfiles: [String: UserProfile] = [:]

    var connectedPeers: [MCPeerID] { session.connectedPeers }
    
    func getProfile(for peerID: MCPeerID) -> UserProfile? {
        return peerProfiles[peerID.displayName]
    }

    override init() {
        let displayName = ProfileManager.shared.currentProfile?.displayName ?? UIDevice.current.name
        self.myPeerID = MCPeerID(displayName: displayName)
        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: PeerManager.serviceType)
        self.browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: PeerManager.serviceType)
        super.init()
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
        setupBackgroundNotifications()
        startDiscovery()
        startNetworkQualityMonitoring()
    }
    
    private func setupBackgroundNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        isInBackground = true
        // Reduce reconnection frequency in background
        reconnectionTimer?.invalidate()
        reconnectionTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.attemptReconnections()
        }
    }
    
    @objc private func appWillEnterForeground() {
        isInBackground = false
        // Immediately attempt reconnections when coming back to foreground
        attemptReconnections()
        startReconnectionTimer()
    }
    
    private func startNetworkQualityMonitoring() {
        networkQualityTimer?.invalidate()
        networkQualityTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.checkNetworkQuality()
        }
    }
    
    private func checkNetworkQuality() {
        // Monitor connection health by checking connected peers
        let connectedCount = session.connectedPeers.count
        
        // If we have unstable connections, restart discovery
        if connectedCount < pendingConnections.count {
            print("🔄 Network quality check: restarting discovery due to connection issues")
            restartDiscovery()
        }
    }
    
    private func restartDiscovery() {
        browser.stopBrowsingForPeers()
        advertiser.stopAdvertisingPeer()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.advertiser.startAdvertisingPeer()
            self?.browser.startBrowsingForPeers()
        }
    }
    
    private func startDiscovery() {
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
        startReconnectionTimer()
    }
    
    private func startReconnectionTimer() {
        reconnectionTimer?.invalidate()
        reconnectionTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.attemptReconnections()
        }
    }
    
    private func attemptReconnections() {
        // Clear stale pending connections
        pendingConnections = pendingConnections.filter { peerID in
            session.connectedPeers.contains(peerID)
        }
        
        // Restart discovery if no peers are connected and there are no pending connections
        if connectedPeers.isEmpty && pendingConnections.isEmpty {
            print("🔄 Attempting reconnection - no active connections")
            restartDiscovery()
        }
        
        // Clean up retry counters for successful connections
        for peer in session.connectedPeers {
            connectionRetryCount.removeValue(forKey: peer.displayName)
            backoffMultiplier.removeValue(forKey: peer.displayName)
        }
    }
    
    // Update peer identity when profile changes
    func updatePeerIdentity() {
        // Stop current services
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
        
        // Create new peer ID with updated name
        let displayName = ProfileManager.shared.currentProfile?.displayName ?? UIDevice.current.name
        let newPeerID = MCPeerID(displayName: displayName)
        
        // This requires creating a new PeerManager instance since MCPeerID is immutable
        // For now, we'll restart services with current peer ID
        // In a production app, you'd want to handle this more gracefully
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    func send(message: ChatMessage, to peers: [MCPeerID]? = nil) {
        let peerMessage = PeerMessage(chatMessage: message)
        sendPeerMessage(peerMessage, to: peers)
    }
    
    func shareProfile(with peers: [MCPeerID]? = nil) {
        guard let profile = ProfileManager.shared.currentProfile else { return }
        let peerMessage = PeerMessage(profile: profile)
        sendPeerMessage(peerMessage, to: peers)
    }
    
    func requestProfile(from peer: MCPeerID) {
        let peerMessage = PeerMessage(profileRequest: true)
        sendPeerMessage(peerMessage, to: [peer])
    }
    
    private func sendPeerMessage(_ peerMessage: PeerMessage, to peers: [MCPeerID]? = nil, retryCount: Int = 0) {
        let targetPeers = peers ?? session.connectedPeers
        guard !targetPeers.isEmpty else { return }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(peerMessage)
            try session.send(data, toPeers: targetPeers, with: .reliable)
            print("✅ Message sent successfully to \(targetPeers.count) peer(s)")
        } catch {
            print("❌ Send error (attempt \(retryCount + 1)): \(error)")
            
            // Retry with exponential backoff
            if retryCount < maxRetryAttempts {
                let backoffDelay = pow(2.0, Double(retryCount)) * baseBackoffInterval
                DispatchQueue.main.asyncAfter(deadline: .now() + backoffDelay) { [weak self] in
                    self?.sendPeerMessage(peerMessage, to: peers, retryCount: retryCount + 1)
                }
            } else {
                print("❌ Max retry attempts reached, giving up on message send")
                // Could notify delegate about permanent send failure here
            }
        }
    }

    func disconnect() {
        reconnectionTimer?.invalidate()
        reconnectionTimer = nil
        networkQualityTimer?.invalidate()
        networkQualityTimer = nil
        pendingConnections.removeAll()
        connectionRetryCount.removeAll()
        backoffMultiplier.removeAll()
        peerProfiles.removeAll()
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        disconnect()
    }
}

extension PeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.pendingConnections.remove(peerID)
            
            switch state {
            case .connected:
                print("✅ Connected to: \(peerID.displayName)")
                self.connectionRetryCount.removeValue(forKey: peerID.displayName)
                self.backoffMultiplier.removeValue(forKey: peerID.displayName)
                
                // Automatically share profile and request peer's profile when connected
                // Add slight delay to ensure connection is stable
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.shareProfile(with: [peerID])
                    self.requestProfile(from: peerID)
                }
                
            case .connecting:
                print("🔄 Connecting to: \(peerID.displayName)")
                self.pendingConnections.insert(peerID)
                
            case .notConnected:
                print("❌ Disconnected from: \(peerID.displayName)")
                self.peerProfiles.removeValue(forKey: peerID.displayName)
                
            @unknown default:
                break
            }
            
            self.delegate?.peerManager(self, connectionStateChanged: state, for: peerID)
            self.delegate?.peerManager(self, peerListChanged: session.connectedPeers)
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let peerMessage = try decoder.decode(PeerMessage.self, from: data)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                switch peerMessage.type {
                case .chatMessage:
                    if let chatMessage = peerMessage.chatMessage {
                        self.delegate?.peerManager(self, didReceive: chatMessage, from: peerID)
                    }
                    
                case .profile:
                    if let profile = peerMessage.profile {
                        self.peerProfiles[peerID.displayName] = profile
                        self.delegate?.peerManager(self, didReceive: profile, from: peerID)
                    }
                    
                case .profileRequest:
                    // Send our profile back to the requesting peer
                    self.shareProfile(with: [peerID])
                }
            }
        } catch {
            // Fallback: try to decode as old ChatMessage format for backward compatibility
            if let message = try? JSONDecoder().decode(ChatMessage.self, from: data) {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.peerManager(self, didReceive: message, from: peerID)
                }
            } else {
                print("Failed to decode received data: \(error)")
            }
        }
    }

    // Unused but required
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension PeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Don't accept invitations from ourselves
        guard peerID != myPeerID else {
            invitationHandler(false, nil)
            return
        }
        
        print("📞 Received invitation from: \(peerID.displayName)")
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("❌ Advertiser failed to start: \(error.localizedDescription)")
        // Retry after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.advertiser.startAdvertisingPeer()
        }
    }
}

extension PeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // Don't try to connect to ourselves
        guard peerID != myPeerID else { return }
        
        // Check if already connected or connecting
        if session.connectedPeers.contains(peerID) || pendingConnections.contains(peerID) {
            return
        }
        
        // Check retry limits
        let retryCount = connectionRetryCount[peerID.displayName] ?? 0
        guard retryCount < maxRetryAttempts else {
            print("🚫 Max retry attempts reached for \(peerID.displayName)")
            return
        }
        
        print("🔍 Found peer: \(peerID.displayName) (attempt \(retryCount + 1))")
        pendingConnections.insert(peerID)
        connectionRetryCount[peerID.displayName] = retryCount + 1
        
        // Use longer timeout for better connection success
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("📡 Lost peer: \(peerID.displayName)")
        pendingConnections.remove(peerID)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.peerManager(self, peerListChanged: self.session.connectedPeers)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("❌ Browser failed to start: \(error.localizedDescription)")
        // Retry after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.browser.startBrowsingForPeers()
        }
    }
}
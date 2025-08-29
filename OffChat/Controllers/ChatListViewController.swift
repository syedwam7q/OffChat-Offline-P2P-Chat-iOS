import UIKit
import MultipeerConnectivity

final class ChatListViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .plain)

    private var threads: [ChatThread] = [] {
        didSet { ChatStore.shared.save(threads: threads) }
    }

    private let peerManager = PeerManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "OffChat"
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }

        setupNavigationBar()
        peerManager.delegate = self

        threads = ChatStore.shared.loadThreads()

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(ThreadCell.self, forCellReuseIdentifier: ThreadCell.reuseID)
        


        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        // Add navigation bar items
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(didTapSettings)
        )
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus.message"),
            style: .plain,
            target: self,
            action: #selector(didTapNewChat)
        )
    }

    @objc private func didTapNewChat() {
        // Present connected peers to start a chat
        let connected = peerManager.connectedPeers
        let ac = UIAlertController(title: "Start Chat", message: connected.isEmpty ? "No connected peers yet." : "Choose a peer", preferredStyle: .actionSheet)
        if connected.isEmpty == false {
            for p in connected {
                ac.addAction(UIAlertAction(title: p.displayName, style: .default, handler: { [weak self] _ in
                    self?.openThread(for: p)
                }))
            }
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    @objc private func didTapSettings() {
        let settingsVC = SettingsViewController()
        let nav = UINavigationController(rootViewController: settingsVC)
        present(nav, animated: true)
    }

    private func openThread(for peer: MCPeerID) {
        if let idx = threads.firstIndex(where: { $0.peerID == peer.displayName }) {
            let vc = ChatViewController(thread: threads[idx], peer: peer, peerManager: peerManager) { [weak self] updated in
                self?.threads[idx] = updated
                self?.tableView.reloadData()
            }
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let thread = ChatThread(peerID: peer.displayName, title: peer.displayName)
            threads.insert(thread, at: 0)
            tableView.reloadData()
            let vc = ChatViewController(thread: thread, peer: peer, peerManager: peerManager) { [weak self] updated in
                guard let self else { return }
                if let i = self.threads.firstIndex(where: { $0.id == updated.id }) {
                    self.threads[i] = updated
                }
                self.tableView.reloadData()
            }
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension ChatListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { threads.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ThreadCell.reuseID, for: indexPath) as! ThreadCell
        let t = threads[indexPath.row]
        cell.configure(with: t, peerManager: peerManager)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Attempt to map peer name back to a connected MCPeerID; if not found, just open thread for history.
        let t = threads[indexPath.row]
        let peer = peerManager.connectedPeers.first(where: { $0.displayName == t.peerID })
        let vc = ChatViewController(thread: t, peer: peer, peerManager: peerManager) { [weak self] updated in
            self?.threads[indexPath.row] = updated
            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension ChatListViewController: PeerManagerDelegate {
    func peerManager(_ manager: PeerManager, peerListChanged peers: [MCPeerID]) {
        // Could show a banner or update UI; no-op here
        print("📱 Peer list changed. Connected peers: \(peers.map { $0.displayName })")
    }

    func peerManager(_ manager: PeerManager, didReceive message: ChatMessage, from peerID: MCPeerID) {
        // If the visible top VC is a chat for this peer, forward directly so it updates live
        if let nav = navigationController, let top = nav.topViewController as? ChatViewController {
            top.receive(message, from: peerID)
        }
        // Also update the threads list model for badges/order
        if let idx = threads.firstIndex(where: { $0.peerID == peerID.displayName }) {
            threads[idx].messages.append(message)
            tableView.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .automatic)
        } else {
            let newThread = ChatThread(peerID: peerID.displayName, title: peerID.displayName, messages: [message])
            threads.insert(newThread, at: 0)
            tableView.reloadData()
        }
    }
    
    func peerManager(_ manager: PeerManager, didReceive profile: UserProfile, from peerID: MCPeerID) {
        print("👤 Received profile from \(peerID.displayName): \(profile.displayName)")
        
        // Update any existing threads with the new profile info
        if let idx = threads.firstIndex(where: { $0.peerID == peerID.displayName }) {
            // Update thread title with actual profile name if different
            threads[idx].title = profile.displayName
            tableView.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .automatic)
        }
        
        // The profile is already cached in PeerManager, so ThreadCell can access it via getProfile()
    }
    
    func peerManager(_ manager: PeerManager, connectionStateChanged state: MCSessionState, for peer: MCPeerID) {
        switch state {
        case .connected:
            print("✅ \(peer.displayName) connected")
        case .connecting:
            print("🔄 Connecting to \(peer.displayName)")
        case .notConnected:
            print("❌ \(peer.displayName) disconnected")
        @unknown default:
            break
        }
    }
}
import UIKit
import MultipeerConnectivity

final class ChatViewController: UIViewController {
    private var thread: ChatThread
    private var peer: MCPeerID?
    private let peerManager: PeerManager
    private let onUpdate: (ChatThread) -> Void

    // UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let enhancedInputView = EnhancedInputView()
    
    private var inputBottomConstraint: NSLayoutConstraint!
    
    // File handling
    private var filePickerManager: FilePickerManager?

    init(thread: ChatThread, peer: MCPeerID?, peerManager: PeerManager, onUpdate: @escaping (ChatThread) -> Void) {
        self.thread = thread
        self.peer = peer
        self.peerManager = peerManager
        self.onUpdate = onUpdate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // Expose receive for forwarding
    func receive(_ message: ChatMessage, from peerID: MCPeerID) {
        guard peerID.displayName == thread.peerID else { return }
        thread.messages.append(message)
        onUpdate(thread)
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.scrollToBottom(animated: true)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = thread.title
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }

        setupTable()
        setupEnhancedInputView()
        setupKeyboardNotifications()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollToBottom(animated: false)
    }



    // MARK: - Setup
    private func setupTable() {
        tableView.register(MessageCell.self, forCellReuseIdentifier: MessageCell.reuseID)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
        
        if #available(iOS 13.0, *) {
            tableView.backgroundColor = .systemBackground
        } else {
            tableView.backgroundColor = .white
        }

        view.addSubview(tableView)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: guide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: guide.trailingAnchor)
        ])
    }

    private func setupEnhancedInputView() {
        enhancedInputView.delegate = self
        enhancedInputView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(enhancedInputView)
        
        inputBottomConstraint = enhancedInputView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        
        NSLayoutConstraint.activate([
            enhancedInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            enhancedInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBottomConstraint,
            
            // Constrain table bottom to input view top
            tableView.bottomAnchor.constraint(equalTo: enhancedInputView.topAnchor)
        ])
    }

    // MARK: - Actions
    @objc private func tableViewTapped() {
        view.endEditing(true)
    }

    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        let keyboardHeight = keyboardFrame.height
        inputBottomConstraint.constant = -keyboardHeight
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        inputBottomConstraint.constant = 0
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    private func scrollToBottom(animated: Bool) {
        let count = thread.messages.count
        guard count > 0 else { return }
        let indexPath = IndexPath(row: count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }

    private func sendMessage(_ message: ChatMessage) {
        thread.messages.append(message)
        onUpdate(thread)
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.scrollToBottom(animated: true)
        }
        
        // Send via PeerManager
        if let peer = peer {
            peerManager.send(message: message, to: [peer])
        } else {
            peerManager.send(message: message)
        }
    }
}

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { thread.messages.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MessageCell.reuseID, for: indexPath) as! MessageCell
        let m = thread.messages[indexPath.row]
        let isOutgoing = (m.sender == peerManager.myPeerID.displayName)
        cell.configure(with: m, isFromCurrentUser: isOutgoing)
        return cell
    }
}

// MARK: - EnhancedInputViewDelegate
extension ChatViewController: EnhancedInputViewDelegate {
    func didTapSendMessage(text: String) {
        let myName = peerManager.myPeerID.displayName
        let message = ChatMessage(sender: myName, text: text)
        sendMessage(message)
    }
    
    func didTapAttachmentButton() {
        filePickerManager = FilePickerManager(presentingViewController: self)
        filePickerManager?.delegate = self
        filePickerManager?.presentAttachmentOptions()
    }
    
    func didTapSearchButton() {
        // Create a thread for current conversation for search
        let currentThread = ChatThread(peerID: thread.peerID, title: thread.title, messages: thread.messages)
        let searchViewController = MessageSearchViewController(threads: [currentThread])
        searchViewController.delegate = self
        
        let navController = UINavigationController(rootViewController: searchViewController)
        present(navController, animated: true)
    }
    
    private func presentPhotoSelection() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func presentFileSelection() {
        // For now, create a demo file message
        let demoText = "📄 Demo file attachment - this feature will be expanded in the next phase"
        let myName = peerManager.myPeerID.displayName
        let message = ChatMessage(sender: myName, text: demoText)
        sendMessage(message)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage {
            // For Phase 2, create an image message with the MediaManager
            if let attachment = MediaManager.shared.createMediaAttachment(from: image) {
                let myName = peerManager.myPeerID.displayName
                let message = ChatMessage(
                    sender: myName,
                    text: "📷 Photo",
                    messageType: .image,
                    attachment: attachment
                )
                sendMessage(message)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - FilePickerDelegate
extension ChatViewController: FilePickerDelegate {
    func filePicker(didSelectFile fileURL: URL) {
        if let attachment = MediaManager.shared.createMediaAttachment(from: fileURL) {
            let myName = peerManager.myPeerID.displayName
            
            // Determine message type based on MIME type
            let messageType: MessageType
            if attachment.mimeType.hasPrefix("image/") {
                messageType = .image
            } else if attachment.mimeType.hasPrefix("video/") {
                messageType = .video
            } else if attachment.mimeType.hasPrefix("audio/") {
                messageType = .audio
            } else {
                messageType = .file
            }
            
            let message = ChatMessage(
                sender: myName,
                text: attachment.filename,
                messageType: messageType,
                attachment: attachment
            )
            sendMessage(message)
        }
    }
    
    func filePickerDidCancel() {
        // Nothing to do
    }
}

// MARK: - MessageSearchDelegate
extension ChatViewController: MessageSearchDelegate {
    func searchDidSelectMessage(_ message: ChatMessage, in thread: ChatThread) {
        // Find the message in our table view and scroll to it
        if let index = self.thread.messages.firstIndex(where: { $0.id == message.id }) {
            let indexPath = IndexPath(row: index, section: 0)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                
                // Briefly highlight the cell
                if let cell = self.tableView.cellForRow(at: indexPath) {
                    let originalColor = cell.backgroundColor
                    UIView.animate(withDuration: 0.3, animations: {
                        cell.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.3)
                    }) { _ in
                        UIView.animate(withDuration: 0.3) {
                            cell.backgroundColor = originalColor
                        }
                    }
                }
            }
        }
    }
}
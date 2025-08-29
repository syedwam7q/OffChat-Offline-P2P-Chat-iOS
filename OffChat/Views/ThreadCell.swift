import UIKit

final class ThreadCell: UITableViewCell {
    static let reuseID = "ThreadCell"

    private let avatarView = UIView()
    private let avatarImageView = UIImageView()
    private let initialsLabel = UILabel()
    private let titleLabel = UILabel()
    private let lastMessageLabel = UILabel()
    private let timeLabel = UILabel()
    private let unreadBadge = UIView()
    private let unreadCountLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        selectionStyle = .default
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupViews() {
        // Avatar container
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.layer.cornerRadius = 28
        avatarView.layer.masksToBounds = true
        avatarView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)

        // Avatar image
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 28
        avatarImageView.layer.masksToBounds = true
        avatarImageView.isHidden = true

        // Initials label
        initialsLabel.translatesAutoresizingMaskIntoConstraints = false
        initialsLabel.font = UIFont.boldSystemFont(ofSize: 18)
        initialsLabel.textColor = .systemBlue
        initialsLabel.textAlignment = .center

        // Title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        if #available(iOS 13.0, *) {
            titleLabel.textColor = .label
        } else {
            titleLabel.textColor = .black
        }

        // Last message label
        lastMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        lastMessageLabel.font = UIFont.systemFont(ofSize: 15)
        if #available(iOS 13.0, *) {
            lastMessageLabel.textColor = .secondaryLabel
        } else {
            lastMessageLabel.textColor = .darkGray
        }
        lastMessageLabel.numberOfLines = 2

        // Time label
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = UIFont.systemFont(ofSize: 13)
        if #available(iOS 13.0, *) {
            timeLabel.textColor = .secondaryLabel
        } else {
            timeLabel.textColor = .lightGray
        }
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Unread badge
        unreadBadge.translatesAutoresizingMaskIntoConstraints = false
        unreadBadge.backgroundColor = .systemBlue
        unreadBadge.layer.cornerRadius = 10
        unreadBadge.isHidden = true

        unreadCountLabel.translatesAutoresizingMaskIntoConstraints = false
        unreadCountLabel.font = UIFont.boldSystemFont(ofSize: 12)
        unreadCountLabel.textColor = .white
        unreadCountLabel.textAlignment = .center

        // Add subviews
        contentView.addSubview(avatarView)
        avatarView.addSubview(avatarImageView)
        avatarView.addSubview(initialsLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(lastMessageLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(unreadBadge)
        unreadBadge.addSubview(unreadCountLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Avatar view
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 56),
            avatarView.heightAnchor.constraint(equalToConstant: 56),

            // Avatar image
            avatarImageView.topAnchor.constraint(equalTo: avatarView.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor),

            // Initials label
            initialsLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            // Title label
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),

            // Time label
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32), // Account for disclosure indicator

            // Last message label
            lastMessageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            lastMessageLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            lastMessageLabel.trailingAnchor.constraint(lessThanOrEqualTo: unreadBadge.leadingAnchor, constant: -8),
            lastMessageLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -14),

            // Unread badge
            unreadBadge.centerYAnchor.constraint(equalTo: lastMessageLabel.centerYAnchor),
            unreadBadge.trailingAnchor.constraint(equalTo: timeLabel.trailingAnchor),
            unreadBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            unreadBadge.heightAnchor.constraint(equalToConstant: 20),

            // Unread count label
            unreadCountLabel.centerXAnchor.constraint(equalTo: unreadBadge.centerXAnchor),
            unreadCountLabel.centerYAnchor.constraint(equalTo: unreadBadge.centerYAnchor),
            unreadCountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: unreadBadge.leadingAnchor, constant: 4),
            unreadCountLabel.trailingAnchor.constraint(lessThanOrEqualTo: unreadBadge.trailingAnchor, constant: -4)
        ])
    }

    func configure(with thread: ChatThread, peerManager: PeerManager? = nil) {
        titleLabel.text = thread.title
        
        // Configure avatar with profile photo if available
        if let peerManager = peerManager,
           let peerID = peerManager.connectedPeers.first(where: { $0.displayName == thread.peerID }),
           let profile = peerManager.getProfile(for: peerID) {
            
            // Use profile display name for title if available
            titleLabel.text = profile.displayName
            
            // Set avatar image or initials
            if let avatarImage = profile.avatarImage() {
                avatarImageView.image = avatarImage
                avatarImageView.isHidden = false
                initialsLabel.isHidden = true
            } else {
                initialsLabel.text = profile.initials()
                avatarImageView.isHidden = true
                initialsLabel.isHidden = false
            }
        } else {
            // Fallback to thread title and initials
            let initials = thread.title.components(separatedBy: " ")
                .compactMap { $0.first }
                .prefix(2)
            initialsLabel.text = String(initials).uppercased()
            avatarImageView.isHidden = true
            initialsLabel.isHidden = false
        }
        
        // Configure last message and time
        if let lastMessage = thread.messages.last {
            lastMessageLabel.text = lastMessage.text
            timeLabel.text = formatTime(lastMessage.timestamp)
            
            // For demo purposes, show unread count randomly (in real app, this would be tracked)
            let unreadCount = 0 // This would be calculated based on actual read status
            if unreadCount > 0 {
                unreadBadge.isHidden = false
                unreadCountLabel.text = unreadCount > 99 ? "99+" : "\(unreadCount)"
            } else {
                unreadBadge.isHidden = true
            }
        } else {
            lastMessageLabel.text = "No messages yet"
            timeLabel.text = ""
            unreadBadge.isHidden = true
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.isHidden = true
        unreadBadge.isHidden = true
    }
}
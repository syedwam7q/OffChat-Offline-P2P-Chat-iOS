import UIKit

final class MessageCell: UITableViewCell {
    static let reuseID = "MessageCell"

    private let bubble = UIView()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let statusIcon = UIImageView()

    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!

    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .short
        return df
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        if #available(iOS 13.0, *) {
            backgroundColor = .systemBackground
        } else {
            backgroundColor = .white
        }

        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupViews() {
        // Bubble setup
        bubble.layer.cornerRadius = 18
        bubble.layer.masksToBounds = true
        bubble.translatesAutoresizingMaskIntoConstraints = false

        // Message label setup
        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        // Time label setup
        timeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        timeLabel.adjustsFontForContentSizeCategory = true
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        // Status icon setup
        statusIcon.contentMode = .scaleAspectFit
        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        statusIcon.isHidden = true

        // Add subviews
        contentView.addSubview(bubble)
        bubble.addSubview(messageLabel)
        bubble.addSubview(timeLabel)
        bubble.addSubview(statusIcon)
    }
    
    private func setupConstraints() {
        // Create flexible constraints for bubble positioning
        leadingConstraint = bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        
        NSLayoutConstraint.activate([
            // Bubble constraints
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubble.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),

            // Message label constraints
            messageLabel.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -16),
            messageLabel.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 12),

            // Time and status container
            timeLabel.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 16),
            timeLabel.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -8),
            timeLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 8),

            statusIcon.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 4),
            statusIcon.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
            statusIcon.widthAnchor.constraint(equalToConstant: 16),
            statusIcon.heightAnchor.constraint(equalToConstant: 16),
            statusIcon.trailingAnchor.constraint(lessThanOrEqualTo: bubble.trailingAnchor, constant: -16)
        ])
    }

    func configure(with message: ChatMessage, isFromCurrentUser: Bool) {
        messageLabel.text = message.text
        timeLabel.text = Self.timeFormatter.string(from: message.timestamp)
        
        configureForAlignment(isFromCurrentUser: isFromCurrentUser)
        configureStatusIcon(for: message.status, isFromCurrentUser: isFromCurrentUser)
    }
    
    private func configureForAlignment(isFromCurrentUser: Bool) {
        if isFromCurrentUser {
            // Right-aligned (sent messages)
            leadingConstraint.isActive = false
            trailingConstraint.isActive = true
            
            if #available(iOS 13.0, *) {
                bubble.backgroundColor = .systemBlue
                messageLabel.textColor = .white
                timeLabel.textColor = UIColor.white.withAlphaComponent(0.85)
            } else {
                bubble.backgroundColor = .systemBlue
                messageLabel.textColor = .white
                timeLabel.textColor = UIColor.white.withAlphaComponent(0.85)
            }
        } else {
            // Left-aligned (received messages)
            trailingConstraint.isActive = false
            leadingConstraint.isActive = true
            
            if #available(iOS 13.0, *) {
                bubble.backgroundColor = .systemGray5
                messageLabel.textColor = .label
                timeLabel.textColor = .secondaryLabel
            } else {
                bubble.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
                messageLabel.textColor = .black
                timeLabel.textColor = .darkGray
            }
        }
    }
    
    private func configureStatusIcon(for status: MessageStatus, isFromCurrentUser: Bool) {
        guard isFromCurrentUser else {
            statusIcon.isHidden = true
            return
        }
        
        statusIcon.isHidden = false
        
        switch status {
        case .sending:
            statusIcon.image = UIImage(systemName: "clock")
            statusIcon.tintColor = UIColor.white.withAlphaComponent(0.85)
        case .sent:
            statusIcon.image = UIImage(systemName: "checkmark")
            statusIcon.tintColor = UIColor.white.withAlphaComponent(0.85)
        case .delivered:
            statusIcon.image = UIImage(systemName: "checkmark.circle")
            statusIcon.tintColor = UIColor.white.withAlphaComponent(0.85)
        case .read:
            statusIcon.image = UIImage(systemName: "checkmark.circle.fill")
            statusIcon.tintColor = UIColor.white.withAlphaComponent(0.85)
        case .failed:
            statusIcon.image = UIImage(systemName: "exclamationmark.circle")
            statusIcon.tintColor = UIColor.systemRed.withAlphaComponent(0.85)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
        timeLabel.text = nil
        statusIcon.isHidden = true
        statusIcon.image = nil
    }
}
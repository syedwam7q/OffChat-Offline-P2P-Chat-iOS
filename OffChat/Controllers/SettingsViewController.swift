import UIKit

final class SettingsViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var profile: UserProfile?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        profile = ProfileManager.shared.currentProfile
        setupUI()
        setupTableView()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissTapped))
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(ProfileHeaderCell.self, forCellReuseIdentifier: ProfileHeaderCell.reuseID)
    }
    
    @objc private func dismissTapped() {
        dismiss(animated: true)
    }
    
    @objc private func editProfile() {
        let editVC = EditProfileViewController()
        editVC.delegate = self
        let nav = UINavigationController(rootViewController: editVC)
        present(nav, animated: true)
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1 // Profile header
        case 1: return 3 // Profile options
        case 2: return 2 // App options
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: ProfileHeaderCell.reuseID, for: indexPath) as! ProfileHeaderCell
            if let profile = profile {
                cell.configure(with: profile)
            }
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Edit Profile"
                cell.accessoryType = .disclosureIndicator
            case 1:
                cell.textLabel?.text = "Status"
                cell.detailTextLabel?.text = profile?.status
                cell.accessoryType = .disclosureIndicator
            case 2:
                cell.textLabel?.text = "Privacy"
                cell.accessoryType = .disclosureIndicator
            default:
                break
            }
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Notifications"
                cell.accessoryType = .disclosureIndicator
            case 1:
                cell.textLabel?.text = "About"
                cell.accessoryType = .disclosureIndicator
            default:
                break
            }
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return "Profile"
        case 2: return "App Settings"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 1:
            switch indexPath.row {
            case 0: editProfile()
            case 1: editStatus()
            default: break
            }
        case 2:
            switch indexPath.row {
            case 0: showNotificationSettings()
            case 1: showAbout()
            default: break
            }
        default: break
        }
    }
    
    private func editStatus() {
        let alert = UIAlertController(title: "Edit Status", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = self.profile?.status
            textField.placeholder = "Enter your status"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let newStatus = alert.textFields?.first?.text, !newStatus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ProfileManager.shared.updateProfile(status: newStatus)
                self.profile = ProfileManager.shared.currentProfile
                self.tableView.reloadData()
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showNotificationSettings() {
        // Placeholder for notification settings
        let alert = UIAlertController(title: "Notifications", message: "Notification settings would be implemented here.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showAbout() {
        let message = """
        OffChat v1.0
        
        A peer-to-peer chat app that works without internet connectivity using MultipeerConnectivity.
        
        Made by:
        • Syed Wamiq
        • Navya Mudgal
        
        Features:
        • Offline messaging
        • Media sharing
        • Message delivery status
        • Profile customization
        • Message search
        """
        
        let alert = UIAlertController(title: "About OffChat", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension SettingsViewController: EditProfileDelegate {
    func profileDidUpdate() {
        profile = ProfileManager.shared.currentProfile
        tableView.reloadData()
    }
}

// MARK: - Profile Header Cell
final class ProfileHeaderCell: UITableViewCell {
    static let reuseID = "ProfileHeaderCell"
    
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupViews() {
        selectionStyle = .none
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.layer.cornerRadius = 40
        profileImageView.layer.masksToBounds = true
        profileImageView.backgroundColor = .systemBlue.withAlphaComponent(0.15)
        profileImageView.contentMode = .scaleAspectFill
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .boldSystemFont(ofSize: 22)
        nameLabel.textColor = .label
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .systemFont(ofSize: 16)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 2
        
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 80),
            profileImageView.heightAnchor.constraint(equalToConstant: 80),
            
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            
            statusLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            statusLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            statusLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    func configure(with profile: UserProfile) {
        nameLabel.text = profile.displayName
        statusLabel.text = profile.status
        
        if let avatarImage = profile.avatarImage() {
            profileImageView.image = avatarImage
        } else {
            // Show initials
            profileImageView.image = nil
            profileImageView.backgroundColor = .systemBlue.withAlphaComponent(0.15)
            
            // Create initials image
            let initials = profile.initials()
            let size = CGSize(width: 80, height: 80)
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            let context = UIGraphicsGetCurrentContext()!
            
            // Draw background
            context.setFillColor(UIColor.systemBlue.withAlphaComponent(0.15).cgColor)
            context.fill(CGRect(origin: .zero, size: size))
            
            // Draw initials
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 30),
                .foregroundColor: UIColor.systemBlue
            ]
            let attributedString = NSAttributedString(string: initials, attributes: attributes)
            let stringSize = attributedString.size()
            let stringRect = CGRect(
                x: (size.width - stringSize.width) / 2,
                y: (size.height - stringSize.height) / 2,
                width: stringSize.width,
                height: stringSize.height
            )
            attributedString.draw(in: stringRect)
            
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            profileImageView.image = image
        }
    }
}

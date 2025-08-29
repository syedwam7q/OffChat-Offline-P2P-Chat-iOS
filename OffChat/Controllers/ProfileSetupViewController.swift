import UIKit

protocol ProfileSetupDelegate: AnyObject {
    func profileSetupDidComplete()
}

final class ProfileSetupViewController: UIViewController {
    weak var delegate: ProfileSetupDelegate?
    
    // UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let avatarButton = UIButton(type: .system)
    private let avatarImageView = UIImageView()
    private let nameTextField = UITextField()
    private let statusTextField = UITextField()
    private let continueButton = UIButton(type: .system)
    
    private var selectedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        titleLabel.text = "Welcome to OffChat!"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Subtitle
        subtitleLabel.text = "Set up your profile to get started with offline messaging"
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Avatar button and image
        avatarButton.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        avatarButton.layer.cornerRadius = 60
        avatarButton.layer.borderWidth = 2
        avatarButton.layer.borderColor = UIColor.systemBlue.cgColor
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 56
        avatarImageView.layer.masksToBounds = true
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.isHidden = true
        
        let cameraIcon = UIImageView(image: UIImage(systemName: "camera.fill"))
        cameraIcon.tintColor = .systemBlue
        cameraIcon.translatesAutoresizingMaskIntoConstraints = false
        avatarButton.addSubview(cameraIcon)
        
        // Name text field
        nameTextField.placeholder = "Enter your name"
        nameTextField.font = .systemFont(ofSize: 17)
        nameTextField.borderStyle = .roundedRect
        nameTextField.backgroundColor = .secondarySystemBackground
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Status text field
        statusTextField.placeholder = "Enter your status (optional)"
        statusTextField.text = "Hey there! I'm using OffChat"
        statusTextField.font = .systemFont(ofSize: 17)
        statusTextField.borderStyle = .roundedRect
        statusTextField.backgroundColor = .secondarySystemBackground
        statusTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Continue button
        continueButton.setTitle("Continue", for: .normal)
        continueButton.backgroundColor = .systemBlue
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.layer.cornerRadius = 12
        continueButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.isEnabled = false
        continueButton.alpha = 0.5
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [titleLabel, subtitleLabel, avatarButton, avatarImageView, nameTextField, statusTextField, continueButton].forEach {
            contentView.addSubview($0)
        }
        
        // Camera icon constraint
        NSLayoutConstraint.activate([
            cameraIcon.centerXAnchor.constraint(equalTo: avatarButton.centerXAnchor),
            cameraIcon.centerYAnchor.constraint(equalTo: avatarButton.centerYAnchor),
            cameraIcon.widthAnchor.constraint(equalToConstant: 30),
            cameraIcon.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Avatar button
            avatarButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 50),
            avatarButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarButton.widthAnchor.constraint(equalToConstant: 120),
            avatarButton.heightAnchor.constraint(equalToConstant: 120),
            
            // Avatar image
            avatarImageView.topAnchor.constraint(equalTo: avatarButton.topAnchor, constant: 4),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarButton.leadingAnchor, constant: 4),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarButton.trailingAnchor, constant: -4),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarButton.bottomAnchor, constant: -4),
            
            // Name field
            nameTextField.topAnchor.constraint(equalTo: avatarButton.bottomAnchor, constant: 40),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            nameTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Status field
            statusTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 16),
            statusTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statusTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statusTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Continue button
            continueButton.topAnchor.constraint(equalTo: statusTextField.bottomAnchor, constant: 40),
            continueButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 50),
            continueButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    private func setupActions() {
        avatarButton.addTarget(self, action: #selector(avatarTapped), for: .touchUpInside)
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        nameTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
    }
    
    @objc private func textFieldChanged() {
        let hasName = !(nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        continueButton.isEnabled = hasName
        continueButton.alpha = hasName ? 1.0 : 0.5
    }
    
    @objc private func avatarTapped() {
        let alert = UIAlertController(title: "Select Photo", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
            self.presentImagePicker(sourceType: .camera)
        })
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
            self.presentImagePicker(sourceType: .photoLibrary)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else { return }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    @objc private func continueTapped() {
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else { return }
        
        // Disable button to prevent multiple taps
        continueButton.isEnabled = false
        continueButton.alpha = 0.5
        
        let status = statusTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false 
            ? statusTextField.text! 
            : "Hey there! I'm using OffChat"
        
        let profile = UserProfile(displayName: name, status: status, avatarData: selectedImage?.jpegData(compressionQuality: 0.7))
        
        // Save profile and wait for completion before transitioning
        ProfileManager.shared.saveProfile(profile) { [weak self] in
            DispatchQueue.main.async {
                self?.delegate?.profileSetupDidComplete()
            }
        }
    }
}

extension ProfileSetupViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
        selectedImage = image
        avatarImageView.image = image
        avatarImageView.isHidden = false
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
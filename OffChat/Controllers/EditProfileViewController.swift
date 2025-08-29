import UIKit

protocol EditProfileDelegate: AnyObject {
    func profileDidUpdate()
}

final class EditProfileViewController: UIViewController {
    weak var delegate: EditProfileDelegate?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let avatarButton = UIButton(type: .system)
    private let avatarImageView = UIImageView()
    private let nameTextField = UITextField()
    private let statusTextView = UITextView()
    
    private var selectedImage: UIImage?
    private var currentProfile: UserProfile?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Profile"
        currentProfile = ProfileManager.shared.currentProfile
        setupUI()
        setupConstraints()
        loadCurrentProfile()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTapped))
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Avatar setup
        avatarButton.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        avatarButton.layer.cornerRadius = 60
        avatarButton.layer.borderWidth = 2
        avatarButton.layer.borderColor = UIColor.systemBlue.cgColor
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        avatarButton.addTarget(self, action: #selector(avatarTapped), for: .touchUpInside)
        
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 56
        avatarImageView.layer.masksToBounds = true
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Name field
        nameTextField.placeholder = "Display Name"
        nameTextField.font = .systemFont(ofSize: 17)
        nameTextField.borderStyle = .roundedRect
        nameTextField.backgroundColor = .secondarySystemGroupedBackground
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Status text view
        statusTextView.font = .systemFont(ofSize: 17)
        statusTextView.backgroundColor = .secondarySystemGroupedBackground
        statusTextView.layer.cornerRadius = 8
        statusTextView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        statusTextView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        [avatarButton, avatarImageView, nameTextField, statusTextView].forEach {
            contentView.addSubview($0)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            avatarButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            avatarButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarButton.widthAnchor.constraint(equalToConstant: 120),
            avatarButton.heightAnchor.constraint(equalToConstant: 120),
            
            avatarImageView.centerXAnchor.constraint(equalTo: avatarButton.centerXAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: avatarButton.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 112),
            avatarImageView.heightAnchor.constraint(equalToConstant: 112),
            
            nameTextField.topAnchor.constraint(equalTo: avatarButton.bottomAnchor, constant: 30),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            nameTextField.heightAnchor.constraint(equalToConstant: 50),
            
            statusTextView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20),
            statusTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statusTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statusTextView.heightAnchor.constraint(equalToConstant: 100),
            statusTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    private func loadCurrentProfile() {
        guard let profile = currentProfile else { return }
        
        nameTextField.text = profile.displayName
        statusTextView.text = profile.status
        
        if let avatarImage = profile.avatarImage() {
            avatarImageView.image = avatarImage
            selectedImage = avatarImage
        }
    }
    
    @objc private func avatarTapped() {
        let alert = UIAlertController(title: "Change Photo", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
            self.presentImagePicker(sourceType: .camera)
        })
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
            self.presentImagePicker(sourceType: .photoLibrary)
        })
        
        if selectedImage != nil {
            alert.addAction(UIAlertAction(title: "Remove Photo", style: .destructive) { _ in
                self.avatarImageView.image = nil
                self.selectedImage = nil
            })
        }
        
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
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            showAlert(title: "Error", message: "Please enter a display name.")
            return
        }
        
        let status = statusTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalStatus = status.isEmpty ? "Hey there! I'm using OffChat" : status
        
        ProfileManager.shared.updateProfile(
            name: name,
            status: finalStatus,
            avatar: selectedImage
        )
        
        delegate?.profileDidUpdate()
        dismiss(animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
        selectedImage = image
        avatarImageView.image = image
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
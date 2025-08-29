import UIKit

protocol EnhancedInputViewDelegate: AnyObject {
    func didTapSendMessage(text: String)
    func didTapAttachmentButton()
    func didTapSearchButton()
}

final class EnhancedInputView: UIView {
    weak var delegate: EnhancedInputViewDelegate?
    
    private let containerView = UIView()
    private let attachmentButton = UIButton(type: .system)
    private let textView = UITextView()
    private let sendButton = UIButton(type: .system)
    private let placeholderLabel = UILabel()
    private let searchButton = UIButton(type: .system)
    
    private var textViewHeightConstraint: NSLayoutConstraint!
    
    private let maxTextViewHeight: CGFloat = 100
    private let minTextViewHeight: CGFloat = 36
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        setupKeyboardNotifications()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupViews() {
        backgroundColor = .systemBackground
        
        // Container setup
        containerView.backgroundColor = .systemBackground
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add separator line at top
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separator)
        
        // Attachment button setup
        attachmentButton.setImage(UIImage(systemName: "plus"), for: .normal)
        attachmentButton.tintColor = .systemBlue
        attachmentButton.translatesAutoresizingMaskIntoConstraints = false
        attachmentButton.addTarget(self, action: #selector(attachmentButtonTapped), for: .touchUpInside)
        
        // Text view setup
        textView.font = .systemFont(ofSize: 16)
        textView.layer.cornerRadius = 18
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.backgroundColor = .systemBackground
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.delegate = self
        textView.isScrollEnabled = false
        
        // Placeholder setup
        placeholderLabel.text = "Message"
        placeholderLabel.font = .systemFont(ofSize: 16)
        placeholderLabel.textColor = .placeholderText
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Send button setup
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.tintColor = .systemBlue
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        sendButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        
        // Search button setup
        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.tintColor = .systemBlue
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        
        addSubview(containerView)
        containerView.addSubview(attachmentButton)
        containerView.addSubview(textView)
        containerView.addSubview(sendButton)
        containerView.addSubview(searchButton)
        textView.addSubview(placeholderLabel)
        
        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: containerView.topAnchor),
            separator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
    
    private func setupConstraints() {
        textViewHeightConstraint = textView.heightAnchor.constraint(equalToConstant: minTextViewHeight)
        
        NSLayoutConstraint.activate([
            // Container view constraints
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Attachment button constraints
            attachmentButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            attachmentButton.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            attachmentButton.widthAnchor.constraint(equalToConstant: 30),
            attachmentButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Search button constraints
            searchButton.leadingAnchor.constraint(equalTo: attachmentButton.trailingAnchor, constant: 4),
            searchButton.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            searchButton.widthAnchor.constraint(equalToConstant: 30),
            searchButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Text view constraints
            textView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            textView.leadingAnchor.constraint(equalTo: searchButton.trailingAnchor, constant: 8),
            textView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            textView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            textViewHeightConstraint,
            
            // Send button constraints
            sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            sendButton.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            sendButton.widthAnchor.constraint(equalToConstant: 30),
            sendButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Placeholder constraints
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 8),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 16),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: textView.trailingAnchor, constant: -16)
        ])
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
        // The keyboard handling is now managed by the parent ChatViewController
        // through the inputBottomConstraint
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        // The keyboard handling is now managed by the parent ChatViewController
        // through the inputBottomConstraint
    }
    
    @objc private func attachmentButtonTapped() {
        delegate?.didTapAttachmentButton()
    }
    
    @objc private func searchButtonTapped() {
        delegate?.didTapSearchButton()
    }
    
    @objc private func sendButtonTapped() {
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        delegate?.didTapSendMessage(text: text)
        clearText()
    }
    
    private func updateTextViewHeight() {
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude))
        let newHeight = max(minTextViewHeight, min(maxTextViewHeight, size.height))
        
        if newHeight != textViewHeightConstraint.constant {
            textViewHeightConstraint.constant = newHeight
            textView.isScrollEnabled = newHeight >= maxTextViewHeight
            
            UIView.animate(withDuration: 0.1) {
                self.layoutIfNeeded()
            }
        }
    }
    
    func clearText() {
        textView.text = ""
        placeholderLabel.isHidden = false
        updateTextViewHeight()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension EnhancedInputView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        updateTextViewHeight()
    }
}
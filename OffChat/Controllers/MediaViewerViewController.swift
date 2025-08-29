import UIKit

final class MediaViewerViewController: UIViewController {
    private let media: MediaAttachment
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let closeButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let detailsLabel = UILabel()
    private let toolbarView = UIView()
    
    private var isToolbarVisible = true
    
    init(media: MediaAttachment) {
        self.media = media
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupGestures()
        loadMedia()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var prefersStatusBarHidden: Bool {
        return !isToolbarVisible
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    private func setupViews() {
        view.backgroundColor = .black
        
        // Scroll view for zooming
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        
        // Image view
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        
        // Toolbar
        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        // Close button
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        closeButton.layer.cornerRadius = 18
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        // Share button
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButton.tintColor = .white
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        
        // Save button
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
        saveButton.tintColor = .white
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        // Title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        
        // Details label
        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        detailsLabel.font = .systemFont(ofSize: 14)
        detailsLabel.textColor = .lightGray
        detailsLabel.textAlignment = .center
        detailsLabel.numberOfLines = 2
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(toolbarView)
        view.addSubview(closeButton)
        toolbarView.addSubview(shareButton)
        toolbarView.addSubview(saveButton)
        toolbarView.addSubview(titleLabel)
        toolbarView.addSubview(detailsLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Image view
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            
            // Close button
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),
            
            // Toolbar
            toolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            toolbarView.heightAnchor.constraint(equalToConstant: 120),
            
            // Share button
            shareButton.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor, constant: 32),
            shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            shareButton.widthAnchor.constraint(equalToConstant: 44),
            shareButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Save button
            saveButton.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor, constant: -32),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            saveButton.widthAnchor.constraint(equalToConstant: 44),
            saveButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: toolbarView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor, constant: -16),
            
            // Details label
            detailsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            detailsLabel.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor, constant: 16),
            detailsLabel.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor, constant: -16),
        ])
    }
    
    private func setupGestures() {
        // Single tap to toggle toolbar
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTap.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(singleTap)
        
        // Double tap to zoom
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTap)
        
        singleTap.require(toFail: doubleTap)
    }
    
    private func loadMedia() {
        if let image = UIImage(data: media.data) {
            imageView.image = image
            titleLabel.text = media.filename
            detailsLabel.text = formatFileSize(media.data.count)
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    @objc private func handleSingleTap() {
        toggleToolbar()
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let location = gesture.location(in: imageView)
            let rect = CGRect(x: location.x - 50, y: location.y - 50, width: 100, height: 100)
            scrollView.zoom(to: rect, animated: true)
        }
    }
    
    private func toggleToolbar() {
        isToolbarVisible.toggle()
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            self.toolbarView.alpha = self.isToolbarVisible ? 1.0 : 0.0
            self.closeButton.alpha = self.isToolbarVisible ? 1.0 : 0.0
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func shareButtonTapped() {
        guard let image = imageView.image else { return }
        
        let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        // For iPad
        if let popover = activityController.popoverPresentationController {
            popover.sourceView = shareButton
            popover.sourceRect = shareButton.bounds
        }
        
        present(activityController, animated: true)
    }
    
    @objc private func saveButtonTapped() {
        guard let image = imageView.image else { return }
        
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(savedToPhotos(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc private func savedToPhotos(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let title = error == nil ? "Saved!" : "Error"
        let message = error?.localizedDescription ?? "Image saved to Photos"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension MediaViewerViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Center the image when zoomed
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }
}
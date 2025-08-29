import UIKit
import UniformTypeIdentifiers

protocol FilePickerDelegate: AnyObject {
    func filePicker(didSelectFile fileURL: URL)
    func filePickerDidCancel()
}

final class FilePickerManager: NSObject {
    weak var delegate: FilePickerDelegate?
    private weak var presentingViewController: UIViewController?
    
    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
        super.init()
    }
    
    func presentDocumentPicker() {
        if #available(iOS 14.0, *) {
            let supportedTypes: [UTType] = [
                .pdf,
                .plainText,
                .image,
                .movie,
                .audio,
                .data,
                .archive,
                .spreadsheet,
                .presentation
            ]
            let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
            documentPicker.delegate = self
            documentPicker.allowsMultipleSelection = false
            documentPicker.shouldShowFileExtensions = true
            
            presentingViewController?.present(documentPicker, animated: true)
        } else {
            // Fallback for iOS 13
            let documentTypes = ["public.data", "public.content", "public.item"]
            let documentPicker = UIDocumentPickerViewController(documentTypes: documentTypes, in: .import)
            documentPicker.delegate = self
            documentPicker.allowsMultipleSelection = false
            
            presentingViewController?.present(documentPicker, animated: true)
        }
    }
    
    func presentPhotoPicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = ["public.image", "public.movie"]
        
        presentingViewController?.present(imagePicker, animated: true)
    }
    
    func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(title: "Camera Not Available", message: "Camera is not available on this device")
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.mediaTypes = ["public.image", "public.movie"]
        imagePicker.cameraCaptureMode = .photo
        
        presentingViewController?.present(imagePicker, animated: true)
    }
    
    func presentAttachmentOptions() {
        let alert = UIAlertController(title: "Send Attachment", message: "Choose an option", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "📷 Camera", style: .default) { [weak self] _ in
            self?.presentCamera()
        })
        
        alert.addAction(UIAlertAction(title: "🖼 Photo Library", style: .default) { [weak self] _ in
            self?.presentPhotoPicker()
        })
        
        alert.addAction(UIAlertAction(title: "📁 Files", style: .default) { [weak self] _ in
            self?.presentDocumentPicker()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.delegate?.filePickerDidCancel()
        })
        
        // For iPad
        if let popover = alert.popoverPresentationController,
           let presentingView = presentingViewController?.view {
            popover.sourceView = presentingView
            popover.sourceRect = CGRect(x: presentingView.bounds.midX, y: presentingView.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        presentingViewController?.present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presentingViewController?.present(alert, animated: true)
    }
    
    private func createTemporaryFileURL(for data: Data, filename: String) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempURL = tempDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to create temporary file: \(error)")
            return nil
        }
    }
}

// MARK: - UIDocumentPickerDelegate
extension FilePickerManager: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else { return }
        
        // Start accessing security-scoped resource
        guard fileURL.startAccessingSecurityScopedResource() else {
            showAlert(title: "Access Denied", message: "Cannot access the selected file")
            return
        }
        
        defer {
            fileURL.stopAccessingSecurityScopedResource()
        }
        
        delegate?.filePicker(didSelectFile: fileURL)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        delegate?.filePickerDidCancel()
    }
}

// MARK: - UIImagePickerControllerDelegate
extension FilePickerManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage {
            // Create temporary file for image
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                let filename = "IMG_\(Date().timeIntervalSince1970).jpg"
                if let tempURL = createTemporaryFileURL(for: imageData, filename: filename) {
                    delegate?.filePicker(didSelectFile: tempURL)
                }
            }
        } else if let videoURL = info[.mediaURL] as? URL {
            // Handle video
            delegate?.filePicker(didSelectFile: videoURL)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        delegate?.filePickerDidCancel()
    }
}
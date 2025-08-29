import UIKit
import AVFoundation
import UniformTypeIdentifiers

final class MediaManager: NSObject {
    static let shared = MediaManager()
    
    private override init() { super.init() }
    
    // MARK: - Image Processing
    func processImage(_ image: UIImage, maxSize: CGSize = CGSize(width: 1920, height: 1920), compressionQuality: CGFloat = 0.8) -> (data: Data?, thumbnail: Data?) {
        let processedImage = resizeImage(image, targetSize: maxSize)
        let thumbnailImage = generateThumbnail(from: processedImage)
        
        let imageData = processedImage.jpegData(compressionQuality: compressionQuality)
        let thumbnailData = thumbnailImage?.jpegData(compressionQuality: 0.6)
        
        return (imageData, thumbnailData)
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    private func generateThumbnail(from image: UIImage) -> UIImage? {
        let thumbnailSize = CGSize(width: 150, height: 150)
        
        UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return thumbnail
    }
    
    // MARK: - File Handling
    func createMediaAttachment(from image: UIImage, filename: String? = nil) -> MediaAttachment? {
        let processedData = processImage(image)
        guard let imageData = processedData.data else { return nil }
        
        let finalFilename = filename ?? "image_\(Date().timeIntervalSince1970).jpg"
        
        return MediaAttachment(
            filename: finalFilename,
            mimeType: "image/jpeg",
            data: imageData,
            thumbnailData: processedData.thumbnail
        )
    }
    
    func createMediaAttachment(from data: Data, filename: String, mimeType: String) -> MediaAttachment {
        var thumbnailData: Data?
        
        // Generate thumbnail for images
        if mimeType.hasPrefix("image/"), let image = UIImage(data: data) {
            thumbnailData = generateThumbnail(from: image)?.jpegData(compressionQuality: 0.6)
        }
        
        return MediaAttachment(
            filename: filename,
            mimeType: mimeType,
            data: data,
            thumbnailData: thumbnailData
        )
    }
    
    func createMediaAttachment(from fileURL: URL) -> MediaAttachment? {
        do {
            let data = try Data(contentsOf: fileURL)
            let filename = fileURL.lastPathComponent
            let mimeType = self.mimeType(for: fileURL.pathExtension)
            
            var thumbnailData: Data?
            
            // Generate appropriate thumbnails
            if mimeType.hasPrefix("image/"), let image = UIImage(data: data) {
                thumbnailData = generateThumbnail(from: image)?.jpegData(compressionQuality: 0.6)
            } else if mimeType.hasPrefix("video/") {
                thumbnailData = generateVideoThumbnail(from: fileURL)?.jpegData(compressionQuality: 0.6)
            }
            
            return MediaAttachment(
                filename: filename,
                mimeType: mimeType,
                data: data,
                thumbnailData: thumbnailData
            )
        } catch {
            print("Failed to create media attachment from URL: \(error)")
            return nil
        }
    }
    
    private func generateVideoThumbnail(from videoURL: URL) -> UIImage? {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1.0, preferredTimescale: 60)
        
        do {
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let thumbnail = UIImage(cgImage: imageRef)
            return generateThumbnail(from: thumbnail)
        } catch {
            print("Failed to generate video thumbnail: \(error)")
            return nil
        }
    }
    
    // MARK: - MIME Type Detection
    func mimeType(for fileExtension: String) -> String {
        if #available(iOS 14.0, *) {
            if let utType = UTType(filenameExtension: fileExtension) {
                return utType.preferredMIMEType ?? "application/octet-stream"
            }
        }
        
        // Fallback for older iOS versions
        let mimeTypes: [String: String] = [
            "jpg": "image/jpeg",
            "jpeg": "image/jpeg",
            "png": "image/png",
            "gif": "image/gif",
            "pdf": "application/pdf",
            "doc": "application/msword",
            "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "txt": "text/plain",
            "mp4": "video/mp4",
            "mov": "video/quicktime",
            "mp3": "audio/mpeg",
            "wav": "audio/wav"
        ]
        
        return mimeTypes[fileExtension.lowercased()] ?? "application/octet-stream"
    }
    
    // MARK: - Utility Methods
    func formattedFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    func isImageType(_ mimeType: String) -> Bool {
        return mimeType.hasPrefix("image/")
    }
    
    func isVideoType(_ mimeType: String) -> Bool {
        return mimeType.hasPrefix("video/")
    }
    
    func isAudioType(_ mimeType: String) -> Bool {
        return mimeType.hasPrefix("audio/")
    }
}
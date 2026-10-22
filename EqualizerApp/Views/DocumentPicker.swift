import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
import UIKit

/// Document Picker wrapper enabling the user to import audio files from Files, iCloud Drive, or local storage.
public struct DocumentPicker: UIViewControllerRepresentable {
    public typealias UIViewControllerType = UIDocumentPickerViewController
    
    let onFilePicked: (URL) -> Void
    
    public init(onFilePicked: @escaping (URL) -> Void) {
        self.onFilePicked = onFilePicked
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let contentTypes: [UTType] = [
            .audio,
            .mp3,
            .wav,
            .aiff,
            UTType("public.m4a-audio") ?? .audio,
            UTType("public.flac") ?? .audio,
            UTType("org.xiph.flac") ?? .audio
        ]
        
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    public class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let selectedURL = urls.first else { return }
            
            // Access security-scoped URL safely
            let shouldStopAccessing = selectedURL.startAccessingSecurityScopedResource()
            defer {
                if shouldStopAccessing {
                    selectedURL.stopAccessingSecurityScopedResource()
                }
            }
            
            // Copy file to App's temp/documents directory to ensure stable access
            let tempDir = FileManager.default.temporaryDirectory
            let targetURL = tempDir.appendingPathComponent(selectedURL.lastPathComponent)
            
            do {
                if FileManager.default.fileExists(atPath: targetURL.path) {
                    try FileManager.default.removeItem(at: targetURL)
                }
                try FileManager.default.copyItem(at: selectedURL, to: targetURL)
                parent.onFilePicked(targetURL)
            } catch {
                print("[DocumentPicker] Error copying file: \(error.localizedDescription)")
                // Fallback to source URL if copying failed
                parent.onFilePicked(selectedURL)
            }
        }
    }
}
#endif

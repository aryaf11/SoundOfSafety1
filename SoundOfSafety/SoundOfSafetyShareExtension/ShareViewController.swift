import SwiftUI
import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        extractSharedURL { [weak self] urlString in
            guard let self else { return }
            let text = urlString ?? ""
            let root = ShareCheckView(
                urlString: text,
                onOpenLink: { url in
                    self.extensionContext?.open(url, completionHandler: { _ in
                        self.extensionContext?.completeRequest(returningItems: nil)
                    })
                },
                onCancel: {
                    self.extensionContext?.completeRequest(returningItems: nil)
                }
            )

            let host = UIHostingController(rootView: root)
            addChild(host)
            view.addSubview(host.view)
            host.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                host.view.topAnchor.constraint(equalTo: view.topAnchor),
                host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            host.didMove(toParent: self)
        }
    }

    private func extractSharedURL(completion: @escaping (String?) -> Void) {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            completion(nil)
            return
        }
        for item in items {
            guard let providers = item.attachments else { continue }
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                        DispatchQueue.main.async {
                            if let url = item as? URL {
                                completion(url.absoluteString)
                            } else {
                                completion(nil)
                            }
                        }
                    }
                    return
                }
            }
        }
        completion(nil)
    }
}

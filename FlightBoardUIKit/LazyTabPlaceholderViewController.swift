import UIKit

final class LazyTabPlaceholderViewController: UIViewController {
    enum Tab {
        case notes
        case images
    }

    private let tabKind: Tab

    init(tab: Tab, title: String, image: UIImage?, selectedImage: UIImage?) {
        self.tabKind = tab
        super.init(nibName: nil, bundle: nil)
        tabBarItem = UITabBarItem(title: title, image: image, selectedImage: selectedImage)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeLoadedController() -> UIViewController {
        let root: UIViewController
        switch tabKind {
        case .notes:
            root = PlainTextViewController()
        case .images:
            root = ImagePagerViewController()
        }

        let navigationController = UINavigationController(rootViewController: root)
        navigationController.tabBarItem = tabBarItem
        return navigationController
    }
}

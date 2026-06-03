import UIKit

final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self

        let flights = UINavigationController(rootViewController: FlightsViewController())
        flights.tabBarItem = UITabBarItem(
            title: "航班",
            image: UIImage(systemName: "tablecells"),
            selectedImage: UIImage(systemName: "tablecells.fill")
        )

        let notes = LazyTabPlaceholderViewController(
            tab: .notes,
            title: "文本",
            image: UIImage(systemName: "text.alignleft"),
            selectedImage: UIImage(systemName: "text.alignleft")
        )

        let images = LazyTabPlaceholderViewController(
            tab: .images,
            title: "图片",
            image: UIImage(systemName: "photo.on.rectangle"),
            selectedImage: UIImage(systemName: "photo.on.rectangle.fill")
        )

        viewControllers = [flights, notes, images]
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard
            let placeholder = viewController as? LazyTabPlaceholderViewController,
            let index = viewControllers?.firstIndex(of: placeholder)
        else {
            return true
        }

        let loaded = placeholder.makeLoadedController()
        var controllers = viewControllers ?? []
        controllers[index] = loaded
        viewControllers = controllers
        selectedIndex = index
        return false
    }
}

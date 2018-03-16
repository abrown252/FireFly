# Firefly

Provides some custom animation options for UIViewController transitions. Firefly uses the `tag` property of a UIView object to locate view pairs, it constructs a `Transition` object and using the from/to pair animates between states. Firefly also provides a 'parent' transition for the main view to work in conjunction with subview animations. 

## Usage

Subscribe to  `UINavigationControllerDelegate` is using a `UINavigationController` to manage view controller hierarchy. 

Implement `func navigationController(navigationController:animationControllerForoperation:fromVC:toVC:)` and return a Firefly object with the desired parameters, for example:

```
extension  MainMenuViewController: UINavigationControllerDelegate {

func navigationController(_ navigationController: UINavigationController, 
							animationControllerFor operation: UINavigationControllerOperation, 
							from fromVC: UIViewController, 
							to toVC: UIViewController) -> 
							UIViewControllerAnimatedTransitioning? {
	switch operation {
		case .push:
			return FireFly(viewTags: [99], 
			transitionType: .push, 
			animationType: .scaleFrame, 
			parentTransition: .push)
		default:
			return FireFly(viewTags: [99], 
			transitionType: .pop, 
			animationType: .scaleFrame, 
			parentTransition: .push)
		}
	}
}
```


//
//  FireFly.swift
//  obrClient
//
//  Created by Alex Brown on 3/16/18.
//  Copyright © 2018 K2M, Inc. All rights reserved.
//

import Foundation

enum AnimationType: Int {
    case none
    case scaleFrame
    case crossFade
}

/** The transition of the parent view */
enum ParentTransition: Int {
    /** A take on the default iOS push animation */
    case push = 1
    /** A take on the default iOS push animation with added scale in/out effect */
    case pushScale = 2
    /** A take on the default iOS modal (from bottom) animation */
    case modal = 3
    /** Crossfade between origin and destination */
    case fade = 4
}

class FireFly: NSObject {
    
    /** The type of transition - pop or a push - add or remove respectively */
    let transitionType: TransitionType
    
    /**
     An array of Ints corresponding to tags of UIView objects. At runtime we check for these tags
     in both the origin and destination views.
     */
    let viewTags: [Int]
    
    /** Animation duration */
    let duration: TimeInterval
    
    /** Type of animation to run on subviews within the `viewTags` array */
    var animationType: AnimationType
    
    /** Type of animation to run on the parent, these are separate for more customization */
    var parentTransition: ParentTransition
    
    /** List of Transition structs, these are used to store information about each subview transition */
    private var transitions = [Transition]()
    
    init(viewTags: [Int], transitionType: TransitionType, duration: TimeInterval = 0.4, animationType: AnimationType = .scaleFrame, parentTransition: ParentTransition = .push) {
        self.viewTags = viewTags
        self.transitionType = transitionType
        self.duration = duration
        self.animationType = animationType
        self.parentTransition = parentTransition
    }
    
    /**
     Parse views from the origin and destination using tags from the `viewTags` array
     
     - parameter transitionContext: The instance of `UIViewControllerContextTransitioning` to use for transition variables
     */
    private func loadTransitions(transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else { return }
        guard let toView = transitionContext.view(forKey: .to) else { return }
        
        for tag in viewTags {
            guard
                let fromView = fromView.viewWithTag(tag),
                let toView = toView.viewWithTag(tag)
                else {continue}
            
            transitions.append(Transition(transitionContext: transitionContext, fromView: fromView, toView: toView))
        }
    }

    /**
     Animation function for the main view. We check the type of animation required and forwar dthis on accordingly
     
     - parameter container: The container view for the transition
     - parameter duration: The animation duration
     */
    private func animate(container: UIView, duration: TimeInterval) {
        if animationType == .scaleFrame {
            scaleInAnimation(container: container, duration: duration)
        }
    }
    
    /**
     Called on subviews when animation type is `scaleFrame`. Moves a view from an origin
     location to a destination using the frames of 2 views with macthing tags. To achieve this
     we use a `snapshotView`, this is good for performance but sacrifices autolayout.
     
     - parameter container: The container view for the transition
     - parameter duration: The animation duration
     */
    private func scaleInAnimation(container: UIView, duration: TimeInterval) {
        for transition in transitions {
            let view = transition.fromView.snapshotView(afterScreenUpdates: false)!
            
            transition.fromView.isHidden = true
            transition.toView.isHidden = true
            
            view.frame = transition.fromFrame
            container.addSubview(view)
            
            UIView.animate(withDuration: duration, animations: {
                view.frame = transition.toFrame
            }) { (complete) in
                transition.fromView.isHidden = false
                transition.toView.isHidden = false
                view.removeFromSuperview()
            }
        }
    }

    /**
     Parses the commonly used objects out of an UIViewControllerContextTransitioning object
     
     - paramater context: The UIViewControllerContextTransitioning object used in the animation
     
     - returns: A tuple with names parameters containing the common variables found in
     the UIViewControllerContextTransitioning object
     */
    private func parseContext(context: UIViewControllerContextTransitioning) -> (container: UIView, fromView: UIView, toView: UIView, toVc: UIViewController)? {
        let container = context.containerView
        
        guard let fromView = context.view(forKey: .from) else { return nil }
        guard let toView = context.view(forKey: .to) else { return nil }
        guard let toVc = context.viewController(forKey: .to) else { return nil }
        
        return (container: container, fromView: fromView, toView: toView, toVc: toVc)
    }
    
    /**
     Called when `parentTransition` is `push`. Takes the destination view and pushes it over
     the origin view. does this in reverse for the pop animation. This is a take on the
     default iOS push/pop animation.
     
     - paramater context: The UIViewControllerContextTransitioning object used in the animation
     */
    private func pushMainView(transitionContext: UIViewControllerContextTransitioning) {
        guard let contextParams = parseContext(context: transitionContext)
            else {return}
        
        let container = contextParams.container
        let fromView = contextParams.fromView
        let toView = contextParams.toView
        let toVc = contextParams.toVc
        
        let duration = self.transitionDuration(using: transitionContext)
        
        var targetFrame = transitionContext.finalFrame(for: toVc)
        var initialFrame = transitionContext.finalFrame(for: toVc)
        
        initialFrame.origin.x = transitionType == .push ? targetFrame.size.width : 0
        
        // Add a shadow§ to the left edge, looks nicer when pushing
        toView.layer.shadowColor = UIColor.gray.cgColor
        toView.layer.shadowRadius = 2
        toView.layer.shadowOpacity = 0.3
        toView.layer.shadowOffset = CGSize(width: -2, height: 0)
        toView.translatesAutoresizingMaskIntoConstraints = true
        toView.frame = initialFrame
        toView.layoutIfNeeded()
        
        container.addSubview(fromView)
        container.addSubview(toView)
        var animationView = toView
        if transitionType == .pop {
            container.bringSubview(toFront: fromView)
            animationView = fromView
            targetFrame.origin.x = targetFrame.size.width
        }

        UIView.animate(withDuration: duration, animations: {
            animationView.frame = targetFrame
        }) { (complete) in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            toVc.viewDidAppear(true)
        }
    }
    
    /**
     Called when `parentTransition` is `fade`. Cross fades the origin and destination views.
     
     - paramater context: The UIViewControllerContextTransitioning object used in the animation
     */
    private func fadeMainView(transitionContext: UIViewControllerContextTransitioning) {
        guard let contextParams = parseContext(context: transitionContext)
            else {return}
        
        let container = contextParams.container
        let fromView = contextParams.fromView
        let toView = contextParams.toView
        let toVc = contextParams.toVc
        
        let duration = self.transitionDuration(using: transitionContext)
        
        container.addSubview(fromView)
        container.addSubview(toView)
        let fromAlpha: CGFloat = 1
        let toAlpha: CGFloat = 0
        
        fromView.alpha = fromAlpha
        toView.alpha = toAlpha
        
        UIView.animate(withDuration: duration, animations: {
            fromView.alpha = toAlpha
            toView.alpha = fromAlpha
        }) { (complete) in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            toVc.viewDidAppear(true)
        }
    }
}

extension FireFly: UIViewControllerAnimatedTransitioning {
    /** Delegate function of UIViewControllerAnimatedTransitioning used to return the animation duration. */
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    /** Delegate method of UIViewControllerAnimatedTransitioning. Provides a transitionContext object */
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        let duration = self.transitionDuration(using: transitionContext)
        loadTransitions(transitionContext: transitionContext)
        
        switch parentTransition {
        case .push:
            pushMainView(transitionContext: transitionContext)
        case .fade:
            animationType = .none
            fadeMainView(transitionContext: transitionContext)
        default:
            print("Implement modal")
            // Modal
        }
        
        animate(container: container, duration: duration)
    }
}


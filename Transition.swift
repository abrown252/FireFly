//
//  Transition.swift
//  obrClient
//
//  Created by Alex Brown on 3/16/18.
//  Copyright © 2018 K2M, Inc. All rights reserved.
//

import Foundation

/** the type of transition to perform, push or pop. */
enum TransitionType: Int {
    /** Adding a new view */
    case push = 1
    /** returning to previous view */
    case pop = 2
}

/** A struct which stores variables used constructed for a transition */
struct Transition {
    /** the transition context taken from the UIViewControllerAnimatedTransitioning protocol */
    let transitionContext: UIViewControllerContextTransitioning
    /** The view we're transitioning from */
    let fromView: UIView
    /** The view we're transitioning to */
    let toView: UIView
    
    /** finds the frame for `toView` within it's top-most parent */
    var toFrame: CGRect {
        get {
            guard let toViewParent = transitionContext.view(forKey: .to) else { return CGRect.zero }
            
            var targetFrame = toView.convert(toView.bounds, to: toViewParent)
            targetFrame.origin.y += 64
            return targetFrame
        }
    }
    
    /** finds the frame for `fromView` within it's top-most parent */
    var fromFrame: CGRect {
        get {
            guard let fromViewParent = transitionContext.view(forKey: .from) else { return CGRect.zero }
            
            var targetFrame = fromView.convert(fromView.bounds, to: fromViewParent)
            targetFrame.origin.y += 64
            return targetFrame
        }
    }
}

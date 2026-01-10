//
//  TrapezioNavigator.swift
//  Trapezio
//
//  Created by Jason Jamieson on 1/10/26.
//

import Foundation

/// Hoists navigation and coordination logic out of the feature.
public protocol TrapezioNavigator: AnyObject {
    
    // MARK: - Navigation
    
    /// Navigates to a strongly-typed TrapezioScreen.
    func goTo(_ screen: any TrapezioScreen)
    
    /// Navigates using a custom identifier (e.g. an enum's raw string value).
    func goTo(custom: String)
    
    // MARK: - Dismissal
    
    /// Dismisses the current active feature.
    func dismiss()
    
    /// Dismisses back to a specific strongly-typed TrapezioScreen.
    func dismissTo(_ screen: any TrapezioScreen)
    
    /// Dismisses back to a specific custom identifier string.
    func dismissTo(custom: String)
}

//
//  TrapezioFeature.swift
//  Trapezio
//
//  Created by Jason Jamieson on 1/10/26.
//

import Foundation

/// The central anchor for a feature.
/// This forces the State and Event to be linked to one "Name".
public protocol TrapezioFeature {
    associatedtype State: TrapezioState
    associatedtype Event: TrapezioEvent
}

//
//  DesignSystem.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation
import SwiftUI

// MARK: - Spacing

enum Spacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Typography

extension Font {
    static let appTitle       = Font.system(size: 30, weight: .bold)
    static let appHeadline    = Font.system(size: 21, weight: .semibold)
    static let appBody        = Font.system(size: 18, weight: .regular)
    static let appCallout     = Font.system(size: 17, weight: .medium)
    static let appCaption     = Font.system(size: 15, weight: .regular)
    static let appCaptionBold = Font.system(size: 15, weight: .semibold)
}

// MARK: - Corner Radius

enum CornerRadius {
    static let card:   CGFloat = 12
    static let sheet:  CGFloat = 20
    static let button: CGFloat = 50
    static let badge:  CGFloat = 6
    static let avatar: CGFloat = 8
}

// MARK: - Animations

enum Animations {
    /// Standard UI transitions: 0.22s easeInOut
    static let standard = Animation.easeInOut(duration: 0.22)
    /// Spring for interactive elements
    static let springy  = Animation.spring(response: 0.38, dampingFraction: 0.72)
    /// Fast fade for overlays
    static let fade     = Animation.easeOut(duration: 0.18)
}

// MARK: - View Modifiers

/// Applies the standard card surface style
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(Color.border, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    /// Wraps animations to respect Reduce Motion accessibility setting
    func withStandardAnimation<V: Equatable>(value: V) -> some View {
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        return self.animation(reduceMotion ? .none : Animations.standard, value: value)
    }
}


// SplashThemes.swift
import Splash
#if canImport(UIKit)
import UIKit

extension Splash.Theme {
    static let lightTheme: Splash.Theme = {
        let font = UIFont.systemFont(ofSize: 14) // Using UIFont for iOS
        return Splash.Theme(
            font: font,
            plainTextColor: UIColor.black,
            tokenColors: [
                .keyword: UIColor.blue,
                .string: UIColor.red,
                .type: UIColor.purple,
                .call: UIColor.brown,
                .number: UIColor.magenta,
                .comment: UIColor.gray
            ]
        )
    }()
    
    static let darkTheme: Splash.Theme = {
        let font = UIFont.systemFont(ofSize: 14) // Using UIFont for iOS
        return Splash.Theme(
            font: font,
            plainTextColor: UIColor.white,
            tokenColors: [
                .keyword: UIColor.cyan,
                .string: UIColor.green,
                .type: UIColor.orange,
                .call: UIColor.yellow,
                .number: UIColor.magenta,
                .comment: UIColor.lightGray
            ]
        )
    }()
}

#elseif canImport(AppKit)
import AppKit

extension Splash.Theme {
    static let lightTheme: Splash.Theme = {
        let font = NSFont.systemFont(ofSize: 14) // Using NSFont for macOS
        return Splash.Theme(
            font: font,
            plainTextColor: NSColor.black,
            tokenColors: [
                .keyword: NSColor.blue,
                .string: NSColor.red,
                .type: NSColor.purple,
                .call: NSColor.brown,
                .number: NSColor.magenta,
                .comment: NSColor.gray
            ]
        )
    }()
    
    static let darkTheme: Splash.Theme = {
        let font = NSFont.systemFont(ofSize: 14) // Using NSFont for macOS
        return Splash.Theme(
            font: font,
            plainTextColor: NSColor.white,
            tokenColors: [
                .keyword: NSColor.cyan,
                .string: NSColor.green,
                .type: NSColor.orange,
                .call: NSColor.yellow,
                .number: NSColor.magenta,
                .comment: NSColor.lightGray
            ]
        )
    }()
}

#endif

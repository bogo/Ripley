import Foundation

// MARK: - REPL setup

struct MockEngine: RipleyEngine {
    func eval(_ expr: String) -> String {
        return "Hello, \(expr)"
    }
}

// MARK: - Playground Setup

import UIKit
import PlaygroundSupport

let ripleyViewController = { () -> RipleyViewController in
    // TODO:(bogo) Relocate this to a JSON file.
    let baliTheme = { () -> RipleyTheme in
        let volcanoGrey = #colorLiteral(red: 0.2549019753932953, green: 0.27450981736183167, blue: 0.3019607961177826, alpha: 1.0)
        let pandanGreen = #colorLiteral(red: 0.7215686440467834, green: 0.886274516582489, blue: 0.5921568870544434, alpha: 1.0)
        let firaCode = UIFont(name: "Menlo", size: 12)!
        
        return RipleyTheme(prompt: "> ",
                         backgroundColor: volcanoGrey,
                         textColor: pandanGreen,
                         font: firaCode)
    }()
    
    return RipleyViewController(engine: MockEngine(),
                                theme: baliTheme)
}()

PlaygroundPage.current.liveView = ripleyViewController



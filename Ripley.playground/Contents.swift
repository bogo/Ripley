import Foundation
// import JavaScriptCore

// MARK: - REPL setup

class JSContext {
    let context: NSObject = {
        Bundle(path: "/System/Library/Frameworks/JavaScriptCore.framework")!.load()
        let klass = NSClassFromString("JSContext") as! NSObject.Type
        return klass.init()
    }()
    
    typealias JSExceptionHandler = (NSObject?, NSObject?) -> Void
    var exceptionHandler: JSExceptionHandler? {
        didSet {
            guard let exceptionHandler = exceptionHandler else {
                return
            }
            context.setValue(exceptionHandler as @convention(block) (NSObject?, NSObject?) -> Void, 
                             forKey: "exceptionHandler")
        }
    }
    
    func evaluate(script: String) -> String {
        let value = context
            .perform(Selector("evaluateScript:"), with: script)
            .takeUnretainedValue()
        
        guard let result = value
            .perform(Selector("toString"))
            .takeUnretainedValue() as? String else {
            fatalError("Unable to convert the JavaScript result to a String")
        }
        
        return result
    }
}

class JSEngine: RipleyEngine {
    var insert: (RipleyResult) -> Void = { _ in }
    let context = JSContext()
    
    init() {
        context.exceptionHandler = { (_, exception) in
            guard let exception = exception else {
                return
            }
            
            guard let string = exception
                .perform(Selector("toString"))
                .takeUnretainedValue() as? String else {
                    fatalError()
            }
            
            self.insert(.failure(string))
        }
    }
    
    func eval(_ expr: String) -> RipleyResult {
        return .success(context.evaluate(script: expr))
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
        let lavaRed = #colorLiteral(red: 0.9254902005195618, green: 0.23529411852359772, blue: 0.10196078568696976, alpha: 1.0)
        let menlo = UIFont(name: "Menlo", size: 12)!
        
        return RipleyTheme(prompt: "> ",
                           backgroundColor: volcanoGrey,
                           textColor: pandanGreen,
                           errorColor: lavaRed,
                           font: menlo)
    }()
    
    return RipleyViewController(engine: JSEngine(),
                                theme: baliTheme)
}()

PlaygroundPage.current.liveView = ripleyViewController

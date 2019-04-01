import Foundation
import UIKit
import PlaygroundSupport

// MARK: - Result
public enum RipleyResult {
    case success(String)
    case failure(String)
}

// MARK: - Engine
public protocol RipleyEngine {
    var insert: (RipleyResult) -> Void { get set }
    func eval(_ expr: String) -> RipleyResult
}

// MARK: - Theme

// TODO:(bogo) Make RipleyTheme codable
public struct RipleyTheme {
    let prompt: String
    let backgroundColor: UIColor
    let textColor: UIColor
    let errorColor: UIColor
    let font: UIFont
    
    public init(prompt: String,
                backgroundColor: UIColor,
                textColor: UIColor,
                errorColor: UIColor,
                font: UIFont) {
         self.prompt = prompt
         self.backgroundColor = backgroundColor
         self.textColor = textColor
         self.errorColor = errorColor
         self.font = font
    }
    
    public static var defaultTheme: RipleyTheme {
        return self.init(prompt: "> ",
                    backgroundColor: UIColor.black,
                    textColor: UIColor.white, 
                    errorColor: UIColor.red,
                    font: UIFont(name: "Menlo", size: 12)!)
    }
}

// MARK: - Text View

class RipleyTextView: UITextView {
    var readOnlyRange: Range<String.Index>?
    var historySource: RipleyHistorySource?
    
    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: UIKeyCommand.inputUpArrow,
                         modifierFlags: UIKeyModifierFlags(rawValue: 0),
                         action: #selector(RipleyTextView.upArrow)),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow,
                         modifierFlags: UIKeyModifierFlags(rawValue: 0),
                         action: #selector(RipleyTextView.downArrow)),                
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow,
                         modifierFlags: UIKeyModifierFlags(rawValue: 0),
                         action: #selector(RipleyTextView.leftArrow)),                
            UIKeyCommand(input: UIKeyCommand.inputRightArrow,
                         modifierFlags: UIKeyModifierFlags(rawValue: 0),
                         action: #selector(RipleyTextView.rightArrow)),
        ]
    }
    
    func replaceCurrentPrompt(with string: String) {
        guard let readOnlyRange = readOnlyRange else {
            return
        }
        
        let editRange = readOnlyRange.upperBound...
        text.replaceSubrange(editRange, with: string)
    }
    
    @objc func upArrow() {
        guard let previousString = historySource?.providePreviousRecommendation() else {
            return
        }
        
        replaceCurrentPrompt(with: previousString)
    }
    
    @objc func downArrow() {
        guard let nextString = historySource?.provideNextRecommendation() else {
            return
        }
        
        replaceCurrentPrompt(with: nextString)
    }
    
    @objc func leftArrow() {
        guard let readOnlyRange = readOnlyRange else {
            return
        }
        
        let expectedRange = NSMakeRange(selectedRange.location + (selectedRange.length > 0 ? 0 : -1), 0)
        
        let cursorRange = Range(expectedRange, in: text)!
        if readOnlyRange.contains(cursorRange.lowerBound) {
            return
        }
        
        selectedRange = expectedRange
    }
    
    @objc func rightArrow() {
        selectedRange = NSMakeRange(selectedRange.location + (selectedRange.length > 0 ? selectedRange.length : 1), 0)
    }
}

// MARK: - History Source

protocol RipleyHistorySource {
    // previous is the one before/earlier, next is the one after/later
    func providePreviousRecommendation() -> String?
    func provideNextRecommendation() -> String?
}

// MARK: - View Controller

public class RipleyViewController: UIViewController {
    let theme: RipleyTheme
    var engine: RipleyEngine
    
    let textView = RipleyTextView()
    var readOnlyRange: Range<String.Index>
    
    public var inputHistory = [String]() {
        didSet {
            // set the current index at the bottom of the inputHistory
            currentIndex = inputHistory.count
        }
    }
    // could probably be range
    var currentIndex = 0
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Bad UIKit!")
    }
    
    public init(engine: RipleyEngine,
                theme: RipleyTheme = RipleyTheme.defaultTheme) {
        self.engine = engine
        self.theme = theme
        
        readOnlyRange = theme.prompt.startIndex..<theme.prompt.endIndex
        textView.readOnlyRange = readOnlyRange
        
        super.init(nibName: nil, bundle: nil)

        self.engine.insert = { self.insert(result: $0) }
        textView.historySource = self
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(textView)
        self.configure(textView)
    }
    
    func configure(_ textView: UITextView) {
        textView.backgroundColor = theme.backgroundColor 
        textView.textColor = theme.textColor
        textView.font = theme.font
        textView.text = theme.prompt
        
        textView.textContainer.lineBreakMode = .byCharWrapping
        textView.spellCheckingType = .no
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.autocorrectionType = .no
        textView.delegate = self
        
        let views = [
            "textView" : textView
        ]
        
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[textView]|",
                                                                   options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                   metrics: [:],
                                                                   views: views)
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[textView]|",
                                                                 options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                 metrics: [:],
                                                                 views: views)
                                                                 
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints(horizontalConstraints + verticalConstraints)
    }
    
    func obtainInput(_ continueConsuming: inout Bool) -> String {
        let inputRange = readOnlyRange.upperBound...
        let inputString = String(textView.text[inputRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        
        if inputString.last! == "\\" {
            let newPrompt = String(inputString.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
            textView.replaceCurrentPrompt(with: newPrompt + "\n")
            continueConsuming = true
        }
        
        return inputString
    }
    
    public func insert(result: RipleyResult) {        
        let mutableString = textView.attributedText.mutableCopy() as! NSMutableAttributedString
        let stringToInsert = addAttributes(to: result)
        mutableString.append(stringToInsert)
        textView.attributedText = mutableString as NSAttributedString
        textView.text += "\n"
    }
    
    func addAttributes(to result: RipleyResult) -> NSAttributedString {
        switch result {
        case .success(let result):
            let attributes: [NSAttributedString.Key: Any] = [
                .font : theme.font,
                .foregroundColor : theme.textColor,
            ]

            return NSAttributedString(string: result,
                                      attributes: attributes)
            
        case .failure(let error):
            let attributes: [NSAttributedString.Key: Any] = [
                .font : theme.font,
                .foregroundColor : theme.errorColor,
            ]

            return NSAttributedString(string: error,
                                      attributes: attributes)
        }
    }
    
    func handleInput() {
        textView.text += "\n"
        
        var continueConsuming = false
        let input = obtainInput(&continueConsuming)
        
        if continueConsuming {
            return
        }
        
        inputHistory.append(input)
        insert(result: engine.eval(input))
        
        textView.text += theme.prompt
        readOnlyRange = calculateReadOnlyRange(in: textView.text)
        textView.readOnlyRange = readOnlyRange
    }    
}

extension RipleyViewController: RipleyHistorySource {
    func providePreviousRecommendation() -> String? {
        currentIndex = max(currentIndex - 1, 0)
        if currentIndex >= inputHistory.count {
            return nil
        }
        return inputHistory[currentIndex]
    }
    
    func provideNextRecommendation() -> String? {
        currentIndex = min(currentIndex + 1, inputHistory.count)
        if currentIndex >= inputHistory.count {
            return ""
        }
        return inputHistory[currentIndex]
    }
}

extension RipleyViewController: UITextViewDelegate {
     func calculateReadOnlyRange(in string: String) -> Range<String.Index> {
        let promptRange = string.range(of: theme.prompt, options: .backwards)!
        
        return string.startIndex..<promptRange.upperBound
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let editRange = Range(range, in: textView.text)!
        if readOnlyRange.contains(editRange.lowerBound) {
            return false
        }
        
        if text == "\n" {
            handleInput()
            return false
        }
        
        return true
    }
    
    public func textViewDidChangeSelection(_ textView: UITextView) {
        // TODO:(bogo) Add support for forcing the cursor back into the read-write range.
    }
}

//
//  MSGInputView.swift
//  MessengerKit
//
//  Created by Stephen Radford on 08/06/2018.
//  Copyright © 2018 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import AudioToolbox

/// The base class for the input view used within `MSGMessengerViewController`.
/// This can be subclassed to add custom views.
open class MSGInputView: UIControl {

    /// The text view used for text input
    @IBOutlet public var textView: MSGPlaceholderTextView!

    /// The send button
    @IBOutlet public var sendButton: UIButton!
    @IBOutlet public var recordButton: UIButton!
    @IBOutlet public var attachButton: UIButton!
    
    @IBOutlet public var audioView: UIView!
    @IBOutlet public var durationLbl: UILabel!
    @IBOutlet public var cancelButton: UIButton!

    /// The height constraint to be modified as required.
    /// This should not be set manually but instead use the `minHeight` and `maxHeight` properties.
    private var heightConstraint: NSLayoutConstraint!

    private var audioWidthCOnstrain: NSLayoutConstraint!
    
    /// The minimum height constraint to be set
    public var minHeight: CGFloat = 48

    /// The maximum height constraint to be set
    public var maxHeight: CGFloat = 120
    
    /// The nib the view should be loaded from.
    /// If this isn't set the view will be loaded from code.
    public class var nib: UINib? { return nil }
    
    private var timer:Timer?
    
    var timeDuration:Int = 0
    
    /// The style guide the input view should use.
    public var style: MSGMessengerStyle? {
        didSet {
            guard let style = style else { return }
            textView.font = style.inputFont
            textView.placeholder = style.inputPlaceholder
            textView.textColor = style.inputTextColor
            textView.placeholderColor = style.inputPlaceholderTextColor
            backgroundColor = style.inputViewBackgroundColor
        }
    }

    /// The message the user sent.
    /// This is stored whenever the send button is tapped.
    private(set) open var message = ""

    /// The text in the textView
    private var text: String! {
        return textView.text
    }
    
    override open var tintColor: UIColor! {
        didSet {
            textView.tintColor = tintColor
            sendButton.tintColor = tintColor
        }
    }
    
    required public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init() {
        super.init(frame: .zero)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    open func setup() {
        addHeightConstraints()
        setupTextView()
        setupSendButton()
        setupCancelButton()
        setupRecordButton()
        setupAttachmentButton()
    }

    private func addHeightConstraints() {
        heightConstraint = heightAnchor.constraint(equalToConstant: minHeight)
        heightConstraint.isActive = true
    }

    private func setupTextView() {
        textView.tintColor = tintColor
        textView.delegate = self
    }

    private func setupSendButton() {
        sendButton.isEnabled = true
        sendButton.addTarget(self, action: #selector(sendButtonTapped(_:)), for: .touchUpInside)
    }
    
    private func setupRecordButton() {
        recordButton.isEnabled = true
        let longPress:UILongPressGestureRecognizer = UILongPressGestureRecognizer.init(target: self, action:  #selector(longPress(_:)))
        longPress.minimumPressDuration = 1
        recordButton.addGestureRecognizer(longPress)
    }

    private func setupCancelButton() {
        cancelButton.isEnabled = true
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped(_:)), for: .touchUpInside)
    }
    
    private func setupAttachmentButton() {
        attachButton.isEnabled = true
        attachButton.addTarget(self, action: #selector(attachmentButtonTapped(_:)), for: .touchUpInside)
    }
    
    @objc func longPress(_ gesture: UILongPressGestureRecognizer) {
        if (textView.text.count > 0) {
            sendActions(for: .primaryActionTriggered)
            return
        }
        else if gesture.state == UIGestureRecognizerState.began {
            startRecording()
            sendActions(for: .touchDragEnter)
        }
    }
    
    func startRecording()  {
        audioView.isHidden = false
        sendButton.isHidden = false
        recordButton.isHidden = true
        timeDuration = 0
        if let timerrunning = timer {
            timerrunning.invalidate()
        }
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {[unowned self] timer in
            self.timeDuration += 1
            let (m,s) = self.secondsToHoursMinutesSeconds(seconds: self.timeDuration)
            self.durationLbl.text = String(format: "%02d:%02d", m, s)
        }
    }
    
    func endRecording () {
        audioView.isHidden = true
        sendButton.isHidden = true
        recordButton.isHidden = false
        sendButton.backgroundColor = UIColor.clear
        timeDuration = 0
        if let timerrunning = timer {
            timerrunning.invalidate()
        }
    }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int) {
        return ((seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    @objc func cancelButtonTapped(_ sender: UIButton) {
        endRecording()
        sendActions(for: .touchCancel)
    }
    
    @objc func attachmentButtonTapped(_ sender: UIButton) {
        endRecording()
        sendActions(for: .touchDragInside)
    }
    
    @objc func sendButtonTapped(_ sender: UIButton) {
        if audioView.isHidden == false {
            endRecording()
            sendActions(for: .touchDragExit)
        }
        else {
            message = textView.text
            textView.text = nil
            sendActions(for: .primaryActionTriggered)
        }
    }
    
    @discardableResult open override func resignFirstResponder() -> Bool {
        return textView.resignFirstResponder()
    }
    
    @discardableResult open override func becomeFirstResponder() -> Bool {
        return textView.becomeFirstResponder()
    }

}

extension MSGInputView: MSGPlaceholderTextViewDelegate {

    open func textViewDidChange(_ textView: UITextView) {
        if(textView.text != "") {
            sendButton.isHidden = false
            recordButton.isHidden = true
        }
        else {
            sendButton.isHidden = true
            recordButton.isHidden = false
        }
        let size = textView.sizeThatFits(CGSize(width: textView.bounds.size.width, height: .infinity))
        let height = size.height + 11

        heightConstraint.constant = height < maxHeight ? height : maxHeight

        sendActions(for: .valueChanged)
    }

}

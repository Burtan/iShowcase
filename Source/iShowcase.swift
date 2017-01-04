//
//  iShowcase.swift
//  iShowcase
//
//  Created by Rahul Iyer on 12/10/15.
//  Copyright © 2015 rahuliyer. All rights reserved.
//

import UIKit
import Foundation

@objc public protocol iShowcaseDelegate: NSObjectProtocol {
    /**
     Called when the showcase is displayed
     
     - showcase: The instance of the showcase displayed
     */
    @objc optional func iShowcaseShown(_ showcase: iShowcase)
    /**
     Called when the showcase is removed from the view
     
     - showcase: The instance of the showcase removed
     */
    @objc optional func iShowcaseDismissed(_ showcase: iShowcase, _ programmatically: Bool)
}

@objc open class iShowcase: UIView {
    
    // MARK: Properties
    
    /**
     Type of the highlight for the showcase
     
     - CIRCLE:    Creates a circular highlight around the view
     - RECTANGLE: Creates a rectangular highligh around the view
     */
    @objc public enum TYPE: Int {
        case circle = 0
        case rectangle = 1
    }
    
    fileprivate enum REGION: Int {
        case top = 0
        case left = 1
        case bottom = 2
        case right = 3
        case none = 4
        
        static func regionFromInt(_ region: Int) -> REGION {
            switch region {
            case 0:
                return .top
            case 1:
                return .left
            case 2:
                return .bottom
            case 3:
                return .right
            case 4:
                return .none
            default:
                return .top
            }
        }
    }
    
    fileprivate var containerView: UIView!
    fileprivate var showcaseRect: CGRect?
    fileprivate var region = REGION.none
    fileprivate var gestureRecognizer: UIGestureRecognizer!
    fileprivate var showcaseImageView: UIImageView!
    fileprivate var textContainer: UIView!
    
    /// Label to show the title of the showcase
    open var titleLabel: UILabel!
    /// the view which is showcased
    open var targetView: UIView?
    /// Label to show the description of the showcase
    open var detailsLabel: UILabel!
    /// Button to show custom action
    open var button: UIButton!
    /// Color of the background for the showcase. Default is black
    open var coverColor: UIColor!
    /// Alpha of the background of the showcase. Default is 0.75
    open var coverAlpha: CGFloat!
    /// Color of the showcase highlight. Default is #1397C5
    open var highlightColor: UIColor!
    /// Type of the showcase to be created. Default is Rectangle
    open var type: TYPE!
    /// Radius of the circle with iShowcase type Circle. Default radius is 25
    open var radius: Float!
    /// Single Shot ID for iShowcase
    open var singleShotId: Int64!
    /// Hide on tapped outside the showcase spot
    open var hideOnTouchOutside = true
    /// Delegate for handling iShowcase callbacks
    open var delegate: iShowcaseDelegate?
    
    // MARK: Initialize
    
    /**
     Initialize an instance of iShowcae
     */
    public init() {
        super.init(frame: CGRect(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.height))
        setup()
    }
    
    /**
     This method is not supported
     */
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Public
    
    /**
     Setup the showcase for a view
     
     - parameter view:    The view to be highlighted
     */
    open func setupShowcaseForView(_ view: UIView) {
        targetView = view
        setupShowcaseForLocation(view.convert(view.bounds, to: containerView))
    }
    
    /**
     Setup showcase for the item at 1st position (0th index) of the table
     
     - parameter tableView: Table whose item is to be highlighted
     */
    open func setupShowcaseForTableView(_ tableView: UITableView) {
        setupShowcaseForTableView(tableView, withIndexOfItem: 0, andSectionOfItem: 0)
    }
    
    /**
     Setup showcase for the item at the given indexpath
     
     - parameter tableView: Table whose item is to be highlighted
     - parameter indexPath: IndexPath of the item to be highlighted
     */
    open func setupShowcaseForTableView(_ tableView: UITableView,
                                        withIndexPath indexPath: IndexPath) {
        setupShowcaseForTableView(tableView,
                                  withIndexOfItem: (indexPath as NSIndexPath).row,
                                  andSectionOfItem: (indexPath as NSIndexPath).section)
    }
    
    /**
     Setup showcase for the item at the given index in the given section of the table
     
     - parameter tableView: Table whose item is to be highlighted
     - parameter row:       Index of the item to be highlighted
     - parameter section:   Section of the item to be highlighted
     */
    open func setupShowcaseForTableView(_ tableView: UITableView,
                                        withIndexOfItem row: Int, andSectionOfItem section: Int) {
        let indexPath = IndexPath(row: row, section: section)
        targetView = tableView.cellForRow(at: indexPath)
        setupShowcaseForLocation(tableView.convert(
            tableView.rectForRow(at: indexPath),
            to: containerView))
    }
    
    /**
     Setup showcase for the Bar Button in the Navigation Bar
     
     - parameter barItem: Bar button to be highlighted
     */
    open func setupShowcaseForBarItem(_ barItem: UIBarItem) {
        setupShowcaseForView(barItem.value(forKey: "view") as! UIView)
    }
    
    /**
     Setup showcase to highlight a particular location on the screen
     
     - parameter location: Location to be highlighted
     */
    open func setupShowcaseForLocation(_ location: CGRect) {
        showcaseRect = location
    }
    
    /**
     Display the iShowcase
     */
    open func show() {
        if singleShotId != -1
            && UserDefaults.standard.bool(forKey: String(
                format: "iShowcase-%ld", singleShotId)) {
            return
        }
        
        self.alpha = 1
        for view in containerView.subviews {
            view.isUserInteractionEnabled = false
        }
        
        UIView.transition(
            with: containerView,
            duration: 0.5,
            options: UIViewAnimationOptions.transitionCrossDissolve,
            animations: { () -> Void in
                self.containerView.addSubview(self)
        }) { (_) -> Void in
            if let delegate = self.delegate {
                if delegate.responds(to: #selector(iShowcaseDelegate.iShowcaseShown)) {
                    delegate.iShowcaseShown!(self)
                }
            }
        }
    }

    /**
    Position the views on the screen for display
    */
    open override func layoutSubviews() {
        super.layoutSubviews()

        frame = CGRect(
                x: 0,
                y: 0,
                width: UIScreen.main.bounds.width,
                height: UIScreen.main.bounds.height
        )

        if showcaseImageView != nil {
            recycleViews()
        }
        if let view = targetView {
            showcaseRect = view.convert(view.bounds, to: containerView)
        }

        updateBackground()
        updateRegion()
        updateTextContainer()
        updateButton()
        gestureRecognizer = getGestureRecgonizer()

        addSubview(showcaseImageView)
        addSubview(textContainer)
        addSubview(button)
        addGestureRecognizer(gestureRecognizer)
    }
    
    // MARK: Private
    
    fileprivate func setup() {
        self.backgroundColor = UIColor.clear
        containerView = UIApplication.shared.delegate!.window!
        coverColor = UIColor.black
        highlightColor = UIColor.blue
        coverAlpha = 0.75
        type = .rectangle
        radius = 25
        singleShotId = -1

        // Load textContainer and assign title and details
        let bundle = Bundle(for: self.classForCoder)
        let nib = UINib(nibName: "textContainer", bundle: bundle)
        textContainer = nib.instantiate(withOwner: nil)[0] as! UIView
        titleLabel = textContainer.subviews[0] as! UILabel
        detailsLabel = textContainer.subviews[1] as! UILabel
        
        // Setup button defaults
        button = UIButton()

    }
    
    fileprivate func updateBackground() {
        UIGraphicsBeginImageContextWithOptions(UIScreen.main.bounds.size,
                                               false, UIScreen.main.scale)
        var context: CGContext? = UIGraphicsGetCurrentContext()
        context?.setFillColor(coverColor.cgColor)
        context?.fill(containerView.bounds)
        
        if type == .rectangle {
            if let showcaseRect = showcaseRect {
                
                // Outer highlight
                let highlightRect = CGRect(
                    x: showcaseRect.origin.x - 15,
                    y: showcaseRect.origin.y - 15,
                    width: showcaseRect.size.width + 30,
                    height: showcaseRect.size.height + 30)
                
                context?.setShadow(offset: CGSize.zero, blur: 30, color: highlightColor.cgColor)
                context?.setFillColor(coverColor.cgColor)
                context?.setStrokeColor(highlightColor.cgColor)
                context?.addPath(UIBezierPath(rect: highlightRect).cgPath)
                context?.drawPath(using: .fillStroke)
                
                // Inner highlight
                context?.setLineWidth(3)
                context?.addPath(UIBezierPath(rect: showcaseRect).cgPath)
                context?.drawPath(using: .fillStroke)
                
                let showcase = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                // Clear region
                UIGraphicsBeginImageContext((showcase?.size)!)
                showcase?.draw(at: CGPoint.zero)
                context = UIGraphicsGetCurrentContext()
                context?.clear(showcaseRect)
            }
        } else {
            if let showcaseRect = showcaseRect {
                let center = CGPoint(
                    x: showcaseRect.origin.x + showcaseRect.size.width / 2.0,
                    y: showcaseRect.origin.y + showcaseRect.size.height / 2.0)
                
                // Draw highlight
                context?.setLineWidth(2.54)
                context?.setShadow(offset: CGSize.zero, blur: 30, color: highlightColor.cgColor)
                context?.setFillColor(coverColor.cgColor)
                context?.setStrokeColor(highlightColor.cgColor)
                context?.addArc(center: center, radius: CGFloat(radius * 2), startAngle: 0, endAngle: CGFloat(2 * M_PI), clockwise: false)
                context?.drawPath(using: .fillStroke)
                context?.addArc(center: center, radius: CGFloat(radius), startAngle: 0, endAngle: CGFloat(2 * M_PI), clockwise: false)
                context?.drawPath(using: .fillStroke)
                
                // Clear circle
                context?.setFillColor(UIColor.clear.cgColor)
                context?.setBlendMode(.clear)
                context?.addArc(center: center, radius: CGFloat(radius - 0.54), startAngle: 0, endAngle: CGFloat(2 * M_PI), clockwise: false)
                context?.drawPath(using: .fill)
                context?.setBlendMode(.normal)
            }
        }
        showcaseImageView = UIImageView(image: UIGraphicsGetImageFromCurrentImageContext())
        showcaseImageView.alpha = coverAlpha
        UIGraphicsEndImageContext()
    }
    
    fileprivate func updateRegion() {
        if let showcaseRect = showcaseRect {
            let left = showcaseRect.origin.x,
            right = showcaseRect.origin.x + showcaseRect.size.width,
            top = showcaseRect.origin.y,
            bottom = showcaseRect.origin.y + showcaseRect.size.height
            
            let areas = [
                top * UIScreen.main.bounds.size.width, // Top region
                left * UIScreen.main.bounds.size.height, // Left region
                (UIScreen.main.bounds.size.height - bottom)
                    * UIScreen.main.bounds.size.width, // Bottom region
                (UIScreen.main.bounds.size.width - right)
                    - UIScreen.main.bounds.size.height // Right region
            ]
            
            var largestIndex = 0
            for i in 0..<areas.count {
                if areas[i] > areas[largestIndex] {
                    largestIndex = i
                }
            }
            region = REGION.regionFromInt(largestIndex)
        }
    }
    
    fileprivate func updateTextContainer() {

        switch region {
        case .top:
            textContainer.frame = CGRect(
                    x: 0,
                    y: 0,
                    width: containerView.frame.width,
                    height: showcaseRect!.origin.y
            )
        case .bottom:
            let topBorder = showcaseRect!.origin.y + showcaseRect!.height
            textContainer.frame = CGRect(
                    x: 0,
                    y: topBorder,
                    width: containerView.frame.width,
                    height: containerView.frame.height - topBorder
            )
        case .left:
            textContainer.frame = CGRect(
                    x: 0,
                    y: 0,
                    width: showcaseRect!.origin.y,
                    height: containerView.frame.height
            )

        case .right:
            let leftBorder = showcaseRect!.origin.x + showcaseRect!.width
            textContainer.frame = CGRect(
                    x: leftBorder,
                    y: 0,
                    width: containerView.frame.width - leftBorder,
                    height: containerView.frame.height
            )
        case .none:
            textContainer.frame = CGRect(
                    x: 0,
                    y: 0,
                    width: containerView.frame.width,
                    height: containerView.frame.height
            )
        }
    }
    
    fileprivate func updateButton() {
        button.setTitleColor(highlightColor, for: .normal)
        button.frame = containerView.frame
        button.sizeToFit()
        button.frame = CGRect(
            x: containerView.frame.width - 8 - button.frame.width,
            y: containerView.frame.height - 8 - button.frame.height,
            width: button.frame.width,
            height: button.frame.height
        )
        button.sizeToFit()
        
    }
    
    fileprivate func getGestureRecgonizer() -> UIGestureRecognizer {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(showcaseTapped))
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1
        return singleTap
    }
    
    internal func showcaseTapped(_ gestureRecognizer: UIGestureRecognizer) {
        if !hideOnTouchOutside && showcaseRect != nil {
            //only dismiss if touch is inside spot area
            let point = gestureRecognizer.location(in: self)
            if !showcaseRect!.contains(point) {
                return
            }
        }
        hide(false)
    }
    
    open func hide(_ programmatically: Bool) {
        UIView.animate(
            withDuration: 0.5,
            animations: {
                self.alpha = 0
            }, completion: { _ in
                self.onAnimationComplete(programmatically)
            }
        )
    }
    
    fileprivate func onAnimationComplete(_ programmatically: Bool) {
        if singleShotId != -1 {
            UserDefaults.standard.set(true, forKey: String(
                format: "iShowcase-%ld", singleShotId))
        }
        for view in self.containerView.subviews {
            view.isUserInteractionEnabled = true
        }
        recycleViews()
        self.removeFromSuperview()
        if let delegate = delegate {
            if delegate.responds(to: #selector(iShowcaseDelegate.iShowcaseDismissed)) {
                delegate.iShowcaseDismissed!(self, programmatically)
            }
        }
    }
    
    fileprivate func recycleViews() {
        showcaseImageView.removeFromSuperview()
        textContainer.removeFromSuperview()
        button.removeFromSuperview()
        removeGestureRecognizer(gestureRecognizer)
    }
    
}
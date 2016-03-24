//
//  Aardvark.swift
//  Aardvark
//
//  Created by Dan Federman on 3/23/16.
//  Copyright © 2016 Square, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation


// MARK: Aardvark

@objc(ARKAardvark) public class Aardvark : NSObject {
    
    /// Sets up a two finger press-and-hold gesture recognizer to trigger email bug reports that will be sent to emailAddress. Returns the created bug reporter for convenience.
    public static func addDefaultBugReportingGestureWithEmailBugReporterWithRecipient(emailAddress: String) -> ARKEmailBugReporter {
        let logStore = ARKLogDistributor.defaultDistributor().defaultLogStore
        let bugReporter = ARKEmailBugReporter(emailAddress: emailAddress, logStore: logStore)
        
        UIApplication.sharedApplication().addTwoFingerPressAndHoldGestureRecognizerTriggerWithBugReporter(bugReporter)
        
        return bugReporter;
    }
    
    /// Creates and returns a gesture recognizer that when triggered will call [bugReporter composeBugReport].
    @nonobjc public static func addBugReporter<GestureRecognizer: UIGestureRecognizer>(bugReporter: ARKBugReporter, triggeringGestureRecognizerClass: GestureRecognizer.Type) -> GestureRecognizer? {
        return UIApplication.sharedApplication().addBugReporter(bugReporter, triggeringGestureRecognizerClass: triggeringGestureRecognizerClass)
    }
    
    /// Creates and returns a gesture recognizer that when triggered will call [bugReporter composeBugReport].
    @objc(addBugReporter:gestureRecognizerClass:) public static func objc_addBugReporter(bugReporter: ARKBugReporter, triggeringGestureRecognizerClass gestureRecognizerClass: AnyClass) -> AnyObject? {
        guard let triggeringGestureRecognizerClass = gestureRecognizerClass as? UIGestureRecognizer.Type else {
            noteImproperAPIUse("\(gestureRecognizerClass) is not a gesture recognizer class!")
            return nil
        }
        
        return UIApplication.sharedApplication().addBugReporter(bugReporter, triggeringGestureRecognizerClass: triggeringGestureRecognizerClass)
    }
}

// MARK: UIApplication Extension

extension UIApplication {
    @nonobjc private static var observingKeyWindowNotifications = false
    @nonobjc private static let bugReporterToGestureRecognizerMap = NSMapTable.strongToStrongObjectsMapTable()
    
    @nonobjc func addTwoFingerPressAndHoldGestureRecognizerTriggerWithBugReporter(bugReporter: ARKBugReporter) {
        let bugReportingGestureRecognizer = self.addBugReporter(bugReporter, triggeringGestureRecognizerClass: UILongPressGestureRecognizer.self)
        bugReportingGestureRecognizer?.numberOfTouchesRequired = 2
    }
    
    /// Creates and returns a gesture recognizer that when triggered will call [bugReporter composeBugReport]. Must be called from the main thread.
    @nonobjc func addBugReporter<GestureRecognizer: UIGestureRecognizer>(bugReporter: ARKBugReporter, triggeringGestureRecognizerClass: GestureRecognizer.Type) -> GestureRecognizer? {
        guard NSThread.isMainThread() else {
            noteImproperAPIUse("Must call \(#function) from the main thread!")
            return nil
        }
        
        guard bugReporter.logStores().count > 0 else {
            noteImproperAPIUse("Attempting to add a bug reporter without a log store!")
            return nil
        }
        
        let bugReportingGestureRecognizer = triggeringGestureRecognizerClass.init(target: self, action: #selector(UIApplication.didFireBugReportGestureRecognizer(_:)))
        self.keyWindow?.addGestureRecognizer(bugReportingGestureRecognizer)
        
        UIApplication.bugReporterToGestureRecognizerMap.setObject(bugReportingGestureRecognizer, forKey: bugReporter)

        if !UIApplication.observingKeyWindowNotifications {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(windowDidBecomeKeyNotification(_:)), name: UIWindowDidBecomeKeyNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(windowDidResignKeyNotification(_:)), name: UIWindowDidBecomeKeyNotification, object: nil)
            
            UIApplication.observingKeyWindowNotifications = true
        }
        
        return bugReportingGestureRecognizer
    }
    
    @nonobjc func removeBugReporter(bugReporter: ARKBugReporter) {
        if let gestureRecognizerToRemove: UIGestureRecognizer = UIApplication.bugReporterToGestureRecognizerMap.objectForKey(bugReporter) as? UIGestureRecognizer {
            gestureRecognizerToRemove.view?.removeGestureRecognizer(gestureRecognizerToRemove)
            
            UIApplication.bugReporterToGestureRecognizerMap.removeObjectForKey(bugReporter)
        }
    }
    
    @objc(ARK_didFireBugReportGestureRecognizer:) func didFireBugReportGestureRecognizer(bugReportRecognizer: UIGestureRecognizer) {
        guard bugReportRecognizer.state == .Began else
        { return }
        
        var bugReporters = [ARKBugReporter]()
        for bugReporter in UIApplication.bugReporterToGestureRecognizerMap.keyEnumerator() {
            guard let bugReporter = bugReporter as? ARKBugReporter where !bugReporters.contains({ $0 === bugReporter }) else
            { continue }
            guard let recognizerForBugReport = UIApplication.bugReporterToGestureRecognizerMap.objectForKey(bugReporter) as? UIGestureRecognizer where recognizerForBugReport == bugReportRecognizer else
            { continue }
            
            bugReporters.append(bugReporter)
        }
        
        guard bugReporters.count > 0 else
        { return }
        
        for bugReporter in bugReporters {
            bugReporter.composeBugReport()
        }
    }
    
    @objc(ARK_windowDidBecomeKeyNotification:) func windowDidBecomeKeyNotification(notification: NSNotification) {
        guard let window = notification.object as? UIWindow else
        { return }
        guard let gestureRecognizersEnumerator = UIApplication.bugReporterToGestureRecognizerMap.objectEnumerator() else
        { return }
        
        for gestureRecognizer in gestureRecognizersEnumerator {
            if let gestureRecognizer = gestureRecognizer as? UIGestureRecognizer {
                window.addGestureRecognizer(gestureRecognizer)
            }
        }
    }
    
    @objc(ARK_windowDidResignKeyNotification:) func windowDidResignKeyNotification(notification: NSNotification) {
        guard let window = notification.object as? UIWindow else
        { return }
        guard let gestureRecognizersEnumerator = UIApplication.bugReporterToGestureRecognizerMap.objectEnumerator() else
        { return }
        
        for gestureRecognizer in gestureRecognizersEnumerator {
            if let gestureRecognizer = gestureRecognizer as? UIGestureRecognizer {
                window.removeGestureRecognizer(gestureRecognizer)
            }
        }
    }
}

// MARK: Private Functions

private func noteImproperAPIUse(message: String) {
    do {
        throw NSError(domain: "ARKImproperAPIUsageDomain", code: 0, userInfo: nil)
    } catch _ {
        NSLog(message)
    }
}

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


@objc public class Aardvark : NSObject {
    
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

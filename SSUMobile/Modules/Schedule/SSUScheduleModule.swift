//
//  SSUScheduleModule.swift
//  SSUMobile
//
//  Created by Eli Simmonds on 4/19/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation

class SSUScheduleModule: SSUCoreDataModuleBase, SSUModuleUI {
    
    @objc(sharedInstance)
    static let instance = SSUScheduleModule()
    
    // MARK: SSUModule
    
    var title: String {
        return NSLocalizedString("Schedule", comment: "A tool for students to view their classes and search current courses offered at SSU")
    }
    
    var identifier: String {
        return "schedule"
    }
    
    func setup() {
        setupCoreData(modelName: "SSUCatalog", storeName: "Schedule")
    }
    
    
    func updateData(completion: (() -> Void)? = nil) {
        SSULogging.logDebug("Update Schedule")
        SSUMoonlightCommunicator.getJSONFromPath("catalog/course") { (response, json, error) in
            if let error = error {
                SSULogging.logError("Error while attemping to update Schedule Classes: \(error)")
                completion?()
            } else {
                self.build(json: json) {
                    completion?()
                }
            }
        }
    }

    private func build(json: Any, completion: (() -> Void)? = nil) {
        let builder = SSUCourseBuilder()
        builder.context = backgroundContext
        backgroundContext.perform {
            builder.build(json)
            SSULogging.logDebug("Finish building Schedule")
            completion?()
        }
    }
    
    // MARK: SSUModuleUI
    
    func imageForHomeScreen() -> UIImage? {
        return UIImage(named: "schedule_icon") // TODO: Add schedule icond
    }
    
    func viewForHomeScreen() -> UIView? {
        return nil
    }
    
    func initialViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Schedule", bundle: Bundle(for: type(of: self)))
        return storyboard.instantiateInitialViewController()! // TODO: Add Schedule Storyboard item
    }
    
    func shouldNavigateToModule() -> Bool {
        return true
    }
    
    func showModuleInNavigationBar() -> Bool {
        return false
    }
    
}




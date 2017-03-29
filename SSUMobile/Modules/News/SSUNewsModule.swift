//
//  SSUNewsModule.swift
//  SSUMobile
//
//  Created by Eric Amorde on 3/26/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation

public let SSUNewsArticleFetchDateLimit: TimeInterval = 60*60*24*180; // 6 months

class SSUNewsModule: SSUCoreDataModuleBase, SSUModuleUI {
    
    static let instance = SSUNewsModule()
    
    let articleFetchDateLimit: TimeInterval = 60*60*24*180; // 6 months
    
    // MARK: SSUModule
    
    override static func sharedInstance() -> SSUNewsModule {
        return instance
    }
    
    func title() -> String {
        return NSLocalizedString("News", comment: "The campus News provides upcoming information on upcoming events")
    }
    
    func identifier() -> String {
        return "news"
    }
    
    override func setup() {
        super.setup()
        let objectModel = model(withName: "News")
        let coordinator = persistentStoreCoordinator(withName: "News", model: objectModel)
        context = self.context(with: coordinator)
        backgroundContext = self.backgroundContext(from: context)
        
        // TODO: this is currently impossible to do in the app delegate because it is inaccessible in objective c.
        // When app delegate is rewritten in Swift, this should be moved there
        ImageCache.default.maxDiskCacheSize = UInt(100 * 1024 * 1024)
    }
    
    override func updateData(_ completion: (() -> Void)? = nil) {
        SSULogging.logDebug("Update News")
        let lastUpdate = SSUConfiguration.sharedInstance().newsLastUpdate
        SSUMoonlightCommunicator.getJSONFromPath("news/article", since: lastUpdate) { (response, json, error) in
            if error != nil {
                SSULogging.logError("Error while updating News: \(error)")
                completion?()
            } else {
                SSUConfiguration.sharedInstance().newsLastUpdate = Date()
                self.build(json: json)
                completion?()
            }
        }
    }
    
    private func build(json: Any) {
        let builder = SSUNewsBuilder()
        builder.context = backgroundContext
        backgroundContext.perform {
            builder.build(json)
            SSULogging.logDebug("Finish building News")
        }
    }
    
    // MARK: SSUModuleUI
    
    func imageForHomeScreen() -> UIImage? {
        return UIImage(named: "news_icon")
    }
    
    func viewForHomeScreen() -> UIView? {
        return nil
    }
    
    func initialViewController() -> UIViewController {
        return SSUNewsViewController(style: .grouped)
    }
    
    func shouldNavigateToModule() -> Bool {
        return true
    }
    
    func showModuleInNavigationBar() -> Bool {
        return false
    }
}

//
//  DataController.swift
//  Virtual Tourist
//
//  Created by Frank Aceves on 6/20/18.
//  Copyright © 2018 Frank Aceves. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    init(modelName: String) {
        container = NSPersistentContainer(name: modelName)
    }
    
    func load(completion: ( () -> Void)? = nil ) {
        container.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            completion?()
        }
    }
}

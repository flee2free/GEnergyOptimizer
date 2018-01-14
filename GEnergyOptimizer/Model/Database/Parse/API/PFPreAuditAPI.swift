//
// Created by Binay Budhthoki on 1/12/18.
// Copyright (c) 2018 GeminiEnergyServices. All rights reserved.
//

import Foundation
import CleanroomLogger
import Parse

class PFPreAuditAPI {

    class var sharedInstance: PFPreAuditAPI {
        struct Singleton {
            static let instance = PFPreAuditAPI()
        }
        return Singleton.instance
    }

    func initialize() -> PFPreAudit {
        Log.message(.info, message: "Parse - Initializing PFPreAudit")
        var pfPreAudit = PFPreAudit()
        pfPreAudit.featureData = Dictionary<String, [Any]>()

        save(pfPreAudit: pfPreAudit) {
            //*** Global PreAuditDTO Registration ***//
            //self.registerPreAuditDTO(preAuditDTO: preAudit)
        }

        return pfPreAudit
    }

    func get(objectId: String, complete: @escaping (Bool, PFObject?)->Void) {
        if let query = PFPreAudit.query() {

            var status = false
            query.getObjectInBackground(withId: objectId) { object, error in
                if (error == nil) {
                    status = true
                    Log.message(.info, message: "Parse - PFPreAudit Query - No Errors")
                } else {
                    Log.message(.error, message: error.debugDescription)
                }
                complete(status, object)
            }
        }
    }

    func save(pfPreAudit: PFPreAudit, complete: @escaping ()->Void) {
        pfPreAudit.saveInBackground { success, error in
            if (success) {
                Log.message(.info, message: "Parse - PFPreAudit Data Saved : Successful")
            } else {
                Log.message(.error, message: error.debugDescription)
            }

            complete()
        }
    }

    func delete(preAudit: PFPreAudit) {

    }
}
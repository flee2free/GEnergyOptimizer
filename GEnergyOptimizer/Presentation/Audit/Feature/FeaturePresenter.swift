//
// Created by Binay Budhthoki on 1/16/18.
// Copyright (c) 2018 GeminiEnergyServices. All rights reserved.
//

import Foundation
import CleanroomLogger

class FeaturePresenter {
    var data = Dictionary<String, Any?>()
    fileprivate var modelLayer = ModelLayer()
    fileprivate var state = StateController.sharedInstance
}

extension FeaturePresenter {
    func loadData(vc: GEFormViewController) {
        modelLayer.loadFeatureData(vc: vc) { source, data in
            self.data = data
            NotificationCenter.default.post(name: .loadFeatureDataForm, object: nil)
        }
    }

    func saveData(data: [String: Any?], model: GEnergyFormModel, vc: GEFormViewController,finished: @escaping (Bool)->Void) {
        modelLayer.saveFeatureData(data: data, model: model, vc: vc) { status in
           finished(status)
        }
    }

    func getActiveZone() -> String {
        if let zone = state.getActiveZone() { return zone }
        else { return EZone.none.rawValue }
    }

    func getApplianceType() -> String {
        return "hvac"
    }

    func bundleResource(entityType: EntityType?) -> String {
        if let entityType = entityType {
            switch entityType {
            case .preaudit: return FileResource.preaudit.rawValue
            case .appliances: return getApplianceType()
            case .zone: return getActiveZone().lowercased()
            default: Log.message(.error, message: "Entity Type : None"); return EntityType.none.rawValue
            }
        } else { Log.message(.error, message: "Entity Type : None"); return EntityType.none.rawValue }
    }
}
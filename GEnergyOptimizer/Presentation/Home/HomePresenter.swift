//
// Created by Binay Budhthoki on 1/10/18.
// Copyright (c) 2018 GeminiEnergyServices. All rights reserved.
//

import Foundation
import CleanroomLogger

typealias SourceBlock = (Source) -> Void

class HomePresenter {
    var data = [HomeListDTO]()
    fileprivate var modelLayer = ModelLayer()
    fileprivate var state = GEStateController.sharedInstance
}


extension HomePresenter {
    func loadData(finished: @escaping SourceBlock) {
        modelLayer.loadHomeData { [weak self] source, data in
            self?.data = data
            finished(source)
        }
    }

    func initGEnergyOptimizer(auditIdentifier: String) {
        modelLayer.initGEnergyOptimizer(identifier: auditIdentifier) {
            Log.message(.info, message: "Callback -> initGEnergyOptimizer")
        }
    }

    func setActiveZone(zone: String) {
        state.registerActiveZone(zone: zone)
    }
}

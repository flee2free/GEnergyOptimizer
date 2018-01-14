//
// Created by Binay Budhthoki on 1/10/18.
// Copyright (c) 2018 GeminiEnergyServices. All rights reserved.
//

import Foundation

typealias SourceBlock = (Source) -> Void

class HomePresenter {
    var data = [HomeListDTO]()
    fileprivate var modelLayer = ModelLayer()
}


extension HomePresenter {
    func loadData(finished: @escaping SourceBlock) {
        modelLayer.loadData { [weak self] source, data in
            self?.data = data
            finished(source)
        }
    }
}

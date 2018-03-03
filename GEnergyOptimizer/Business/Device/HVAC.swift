//
// Created by Binay Budhthoki on 2/26/18.
// Copyright (c) 2018 GeminiEnergyServices. All rights reserved.
//

import Foundation
import CleanroomLogger

class HVAC: EnergyBase, Computable {
    func compute() -> [[String: String]]? {
        let feature = super.mappedFeature
        let preaudit = super.preAudit

        Log.message(.warning, message: feature.debugDescription)
        if let btuPerHour = feature["Cooling Capacity (Btu/hr)"] as? Int64, let seer = feature["SEER"] as? Int64 {
            let annualOperationHours = 8760.00
            let power = Double(btuPerHour / seer) / 1000
            let energy: Double = power * annualOperationHours

            Log.message(.warning, message: "Calculated Energy Value [HVAC] - \(energy.description)")
        }

        return nil
    }
}
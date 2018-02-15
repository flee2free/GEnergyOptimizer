//
// Created by Binay Budhthoki on 2/13/18.
// Copyright (c) 2018 GeminiEnergyServices. All rights reserved.
//

import Foundation
import CleanroomLogger
import CoreData
import Parse

class EnergyCalculator {
    var preAudit = Dictionary<String, Any>()
    var mappedFeature = Dictionary<String, Any>()

    init(feature: [CDFeatureData], preAudit: [CDFeatureData]) {
        self.preAudit = mapFeatureData(feature: preAudit)
        self.mappedFeature = mapFeatureData(feature: feature)
    }

    func compute() {
        Log.message(.error, message: "Please override method Compute")
        fatalError("Must be over-ridden")
    }

    func alternateProductMatchFilter(query: PFQuery<PFObject>) -> PFQuery<PFObject> {
        Log.message(.error, message: "Please override method getBundleResource")
        fatalError("Must be over-ridden")
    }

    func productMatchFilter(query: PFQuery<PFObject>) -> PFQuery<PFObject> {
        let model_number = String(describing: mappedFeature["Model Number"]!)
        let company = String(describing: mappedFeature["Company"]!)

        query.whereKey("data.company", equalTo: company)
        query.whereKey("data.model_number", equalTo: model_number)

        return query
    }

    func pricingChart() -> Dictionary<EPeak, Double> {
        fatalError("Must be over-ridden")
    }

    func peakHourSchedule() -> Dictionary<EPeak, Int> {
        fatalError("Must be over-ridden")
    }
}

extension EnergyCalculator {

    func costElectricity(hourEnergyUse: Double) -> Double {
        let peakPricing = pricingChart()
        let mappedUsageByPeak = peakHourSchedule()

        var summer = Double(mappedUsageByPeak[EPeak.summerOn]!) * hourEnergyUse * Double(peakPricing[EPeak.summerOn]!)
        summer += Double(mappedUsageByPeak[EPeak.summerPart]!) * hourEnergyUse * Double(peakPricing[EPeak.summerPart]!)
        summer += Double(mappedUsageByPeak[EPeak.summerOff]!) * hourEnergyUse * Double(peakPricing[EPeak.summerOff]!)

        var winter = Double(mappedUsageByPeak[EPeak.winterPart]!) * hourEnergyUse * Double(peakPricing[EPeak.winterPart]!)
        winter += Double(mappedUsageByPeak[EPeak.winterOff]!) * hourEnergyUse * Double(peakPricing[EPeak.winterOff]!)

        return (summer + winter)
    }

    func costGas() {

    }
}

extension EnergyCalculator {

    func isEnergyStar(curr_values: Dictionary<String, Any>, complete: @escaping (Bool) -> Void) {
        Log.message(.warning, message: "Energy Star Check")

        if let query = PlugLoad.query() {
            let queryWithProductMatchFilter = productMatchFilter(query: query)
            queryWithProductMatchFilter.findObjectsInBackground { object, error in
                if (error == nil) {
                    Log.message(.info, message: "Parse - Plugload Query - No Error")
                } else {
                    Log.message(.error, message: error.debugDescription)
                    return
                }

                guard let data = object as? [PlugLoad] else {
                    Log.message(.error, message: "Guard Failed : Plugload Data - Core Data Zone")
                    return
                }

                if (data.count > 0) {complete(true)}
                else {complete(false)}
            }
        }
    }

    func findBestModel(curr_values: Dictionary<String, Any>, complete: @escaping ([PlugLoad]) -> Void) {
        if let query = PlugLoad.query() {
            let queryWithAlternateProductMatchFilter = alternateProductMatchFilter(query: query)
            queryWithAlternateProductMatchFilter.findObjectsInBackground { object, error in
                if (error == nil) {
                    Log.message(.info, message: "Parse - Plugload Query - No Error")
                } else {
                    Log.message(.error, message: error.debugDescription)
                    return
                }

                guard let data = object as? [PlugLoad] else {
                    Log.message(.error, message: "Guard Failed : Plugload Data - Core Data Zone")
                    return
                }

                complete(data)
            }
        }
    }
}

extension EnergyCalculator {

    func mapFeatureData(feature: [CDFeatureData]) -> Dictionary<String, Any> {
        var mapped = Dictionary<String, Any>()
        feature.map {
            let type = InitEnumMapper.sharedInstance.enumMap[$0.type!]
            if let eBaseType = type as? BaseRowType {
                switch eBaseType {
                case .intRow: mapped[$0.key!] = $0.value_int
                case .decimalRow: mapped[$0.key!] = $0.value_double
                default: mapped[$0.key!] = $0.value_string
                }
            }
        }

        return mapped
    }

    func getBillData(bill_type: String) -> Dictionary<EPeak, Double> {
        let rows = GUtils.openCSV(filename: "pge_electric")!
        var outgoing = Dictionary<EPeak, Double>()
        for row in rows {
            if row["rate"]! == bill_type {
                let key = "\(row["season"]!)-\(row["ec_period"]!)"
                outgoing[GUtils.getEPeak(rawValue: key)] = Double(row["energy_charge"]!)
            }
        }

        return outgoing
    }
}
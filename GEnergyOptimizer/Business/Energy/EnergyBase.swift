//
// Created by Binay Budhthoki on 2/13/18.
// Copyright (c) 2018 GeminiEnergyServices. All rights reserved.
//

import Foundation
import CleanroomLogger

protocol Computable {
    func compute(_ complete: @escaping (OutgoingRows?) -> Void)
    func fields() -> [String]?
}

class EnergyBase {
    var preAudit = Dictionary<String, Any>()
    var mappedFeature = Dictionary<String, Any>()
    var operatingHours = Dictionary<EDay, String>()
    var outgoing: [[String: String]]

    init(_ feature: [CDFeatureData]) {
        let preAudit = try! AuditFactory.sharedInstance.setPreAudit()
        self.preAudit = GUtils.mapFeatureData(feature: preAudit)
        self.mappedFeature = GUtils.mapFeatureData(feature: feature)
        self.operatingHours = GUtils.mapOperationHours(preAudit: preAudit)
        self.outgoing = [[String: String]]()
    }

    // ToDo: Relay this info back to the Main Class
    func starValidator(complete: @escaping (Bool, GError?) -> Void) {
        let energyStar = EnergyStar(mappedFeature: self.mappedFeature)
        energyStar.query() { status, error in
            complete(status, error)
        }
    }

    static func createEntry(_ object: Computable, _ feature: [String: Any]) -> [String: String] {
        var entry = [String: String]()
        if let fields = object.fields() {
            fields.filter { !$0.starts(with: "__") }
                    .forEach { field in
                        if let value = feature[field] { entry[field] = String(describing: value) }
                        else { entry[field] = "" }
                    }
        }
        return entry
    }
}

class OutgoingRows {
    typealias Row = [String: String]
    enum EType: String {
        case raw, computed
    }
    var header: [String]?
    var rows: [Row]
    var entity: String
    var eType: EType
    var parentFolder: String

    init(rows: [Row], entity: String, type: EType = .computed) {
        self.rows = rows
        self.entity = entity.lowercased()
        self.eType = type
        self.parentFolder = try! AuditFactory.sharedInstance.getIdentifier()
    }

    func setHeader(header: [String]) {
        self.header = header
    }

    func upload(_ completed: @escaping (GError) -> Void) {
        Log.message(.warning, message: "**** Uploading ****")
        let baseDir = getBaseDir()
        var path: String = "\(baseDir)\(parentFolder)/\(eType.rawValue)/\(entity).csv"
        Log.message(.error, message: path.description)

        var buffer: String = header!.joined(separator: ",")
        buffer.append("\r\n")
        for row in rows {
            if let header = self.header {
                var tmp = [String]()
                header.forEach { item in
                    if let value = row[item] {tmp.append(sanitize(value))}
                    else {tmp.append("")}
                }
                buffer.append(tmp.joined(separator: ","))
                buffer.append("\r\n")
            }
        }
        Log.message(.info, message: buffer.debugDescription)

        let dropbox = DropBoxUploader()
        if let data = buffer.data(using: .utf8) {
            dropbox.upload(path: path, data: data) { error in
                completed(error)
            }
            return
        }
        completed(.noData)
    }

    //-- ToDo: What about if there is a quote within the value ?? huh
    func sanitize(_ value: String) -> String {
        var fix: String = value
        if value.contains(",") {
            fix.append("\"\(value)\"")
        }

        return fix
    }

    func getBaseDir() -> String {
        if var baseDir = Settings.auditDataSaveLocation {
            Log.message(.info, message: "Base Dir : \(baseDir)")

            if !(baseDir.starts(with: "/")) {baseDir = "/\(baseDir)"}
            let regex = try! NSRegularExpression(pattern: "^.*/$")
            let match = regex.matches(in: baseDir, range: NSRange(location: 0, length: baseDir.count))
            if !(match.count > 0) {
                baseDir.append("/")
            }

            return baseDir
        } else {return "/Gemini/Energy/Audit/"}
    }
}

protocol Consumption {
  func cost(energyUsed: Double) -> Double
}

class GasCost: Consumption {

    lazy var pricing: Dictionary<ERateKey, Double> = {
        let utility = GasRate()
        return utility.getBillData()
    }()

    // *** Gives the Average Cost Per Day *** //
    //ToDo: How do you interpret the slabs for other utitlity companies ??
    func cost(energyUsed: Double) -> Double {

        var slabPricing = 0.0

        if energyUsed <= 5 {
            slabPricing = pricing[ERateKey.slab1]!
        } else if energyUsed <= 16 {
            slabPricing = pricing[ERateKey.slab2]!
        } else if energyUsed <= 41 {
            slabPricing = pricing[ERateKey.slab3]!
        } else if energyUsed <= 123 {
            slabPricing = pricing[ERateKey.slab4]!
        } else {
            slabPricing = pricing[ERateKey.slab5]!
        }

        // Since the values are per day - Dividing by 2 averages Summer | Winter as they are both of 6 months
        slabPricing += (pricing[ERateKey.summerTransport]! + pricing[ERateKey.winterTransport]!) / 2 + pricing[ERateKey.surcharge]!

        return  (slabPricing * energyUsed)
    }
}

class ElectricCost: Consumption {
    var rateStructure: String
    var operatingHours: Dictionary<EDay, String>

    lazy var pricing: Dictionary<ERateKey, Double> = {
        let utility = ElectricRate(type: rateStructure)
        return utility.getBillData()
    }()

    lazy var usageByPeak: Dictionary<ERateKey, Double> = {
        let peak = PeakHourMapper()
        return peak.run(usage: operatingHours)
    }()

    lazy var usageByDay: Double = {
        let peak = PeakHourMapper()
        return peak.annualOperatingHours(operatingHours) / 365
    }()

    init(rateStructure: String, operatingHours: Dictionary<EDay, String>) {
        self.rateStructure = rateStructure
        self.operatingHours = operatingHours
    }

    //ToDo: What about cases where is no Time of Use ??
    func cost(energyUsed: Double) -> Double {

        var regex = try! NSRegularExpression(pattern: "^.*tou$")
        let match = regex.matches(in: rateStructure.lowercased(), range: NSRange(location: 0, length: rateStructure.count))
        if (match.count > 0) {
            var summer = Double(usageByPeak[ERateKey.summerOn]!) * energyUsed * pricing[ERateKey.summerOn]!
            summer += Double(usageByPeak[ERateKey.summerPart]!) * energyUsed * pricing[ERateKey.summerPart]!
            summer += Double(usageByPeak[ERateKey.summerOff]!) * energyUsed * pricing[ERateKey.summerOff]!

            var winter = Double(usageByPeak[ERateKey.winterPart]!) * energyUsed * pricing[ERateKey.winterPart]!
            winter += Double(usageByPeak[ERateKey.winterOff]!) * energyUsed * pricing[ERateKey.winterOff]!

            return (summer + winter) / 2
        } else {
            let summer = usageByDay * energyUsed * pricing[ERateKey.summerNone]!
            let winter = usageByDay * energyUsed * pricing[ERateKey.winterNone]!

            return (summer + winter) / 2
        }
    }
}

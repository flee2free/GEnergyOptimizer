//
//  ZoneListingViewController.swift
//  GEnergyOptimizer
//
//  Created by Binay Budhthoki on 12/3/17.
//  Copyright © 2017 GeminiEnergyServices. All rights reserved.
//

import UIKit
import CleanroomLogger
import PopupDialog

class ZoneListViewController: UIViewController {

    @IBOutlet weak var lblZoneHeader: UILabel!
    @IBOutlet weak var tableView: UITableView!

    var presenter = ZonePresenter()
    var zone: String?

    static let cellIdentifier = "zoneListCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        Log.message(.info, message: "GEnergy - ZoneList View Controller")

        self.initTableView()
        self.setZoneHeader()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        zone = presenter.getActiveZone()
        presenter.loadData { source in
            self.tableView.reloadData()
        }
    }
}

//Mark: - Touch Events
extension ZoneListViewController {

    @IBAction func btnAddZonePressed(_ sender: Any) {
        Log.message(.info, message: "Add New Zone")
        let popup = ControllerUtils.getPopEdit() { name in
            if (name.isEmpty) {
                GUtils.message(title: "Alert", message: "Zone Name Cannot be Empty", vc: self)
                return
            }

            if let zone = self.zone {
                self.presenter.createZone(name: name, type: zone)
            }
        }

        self.present(popup, animated: true, completion: nil)
    }
}

//Mark: - UITableViewDataSource
extension ZoneListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.presenter.data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let zone = presenter.data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ZoneListViewController.cellIdentifier, for: indexPath)
        cell.textLabel?.text = zone.title

        return cell
    }
}

//Mark: - UITableViewDelegate
extension  ZoneListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let featureViewController = ControllerUtils.fromStoryboard(reference: String(describing: FeatureViewController.self)) as? FeatureViewController
        navigationController?.pushViewController(featureViewController!, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let actions = ControllerUtils.getTableEditActions(
                delete: { row in Log.message(.info, message: "Delete Action - Clouser Executed @ \(row.description)")},
                edit: { row in Log.message(.info, message: "Edit Action - Clouser Executed @ \(row.description)")}
        )

        return actions
    }
}

//Mark: - Helper Methods
extension ZoneListViewController {

    func initTableView() {
        tableView!.dataSource = self
        tableView!.delegate = self
        tableView!.rowHeight = 60
    }

    func setZoneHeader() {
        if let zone = zone {
            self.lblZoneHeader.text = "Zone - \(zone))"
        }
    }
}
//
//  ViewController.swift
//  LocalizeToExample
//
//  Created by Sergey Chehuta on 24/08/2019.
//  Copyright © 2019 WhiteTown. All rights reserved.
//

import UIKit
import LocalizeTo

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private let apikey    = "787847642e3b9c47c773921261d490e8"
    private let languages = ["en", "de", "es", "fr", "pl", "sk", "uk", "ru", "cs"]
    private var language  = "en"

    private var keys = [
        "ok",
        "cancel",
        "error",
        "choose_language",
        "yes",
        "no",
        "retry",
        "abort",
        ]

    override func viewDidLoad() {
        super.viewDidLoad()

        initializeNavbar()
        initializeLocalize()
        initializeTableView()
    }

    private func initializeNavbar() {
        let btnSelect = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(xchgLanguage))
        self.navigationItem.leftBarButtonItem = btnSelect

        let btnLatest   = UIBarButtonItem(title: "Latest", style: .plain, target: self, action: #selector(getLatestLanguages))
        let btnSnapshot = UIBarButtonItem(title: "v1.0.0", style: .plain, target: self, action: #selector(getSnapshot))
        self.navigationItem.rightBarButtonItems = [btnLatest, btnSnapshot]
    }

    private func initializeLocalize() {
        LocalizeTo.shared.configure(apiKey: self.apikey)
        LocalizeTo.shared.load(languages: self.languages)
    }

    private func initializeTableView() {

        self.tableView.dataSource = self
        self.tableView.allowsSelection = false
    }

    @objc private func xchgLanguage() {

        let ac = UIAlertController(title: "choose_language".localized, message: nil, preferredStyle: .actionSheet)

        for language in self.languages {
            ac.addAction(UIAlertAction(title: language, style: .default, handler: { (action) in
                LocalizeTo.shared.setCurrentLanguageCode(language)
                self.tableView.reloadData()
            }))
        }

        ac.addAction(UIAlertAction(title: "cancel".localized, style: .cancel, handler: { (action) in }))

        self.present(ac, animated: true, completion: nil)
    }

    @objc private func getLatestLanguages() {

        weak var welf = self
        LocalizeTo.shared.download(languages: self.languages) { (errors) in
            if let errors = errors {
                print(errors)
            } else {
                LocalizeTo.shared.reload(languages: welf?.languages ?? [])
                welf?.tableView.reloadData()
            }
        }
    }

    @objc private func getSnapshot() {

        weak var welf = self
        LocalizeTo.shared.download(version: "v1.0.0") { (errors) in
            if let errors = errors {
                print(errors)
            } else {
                LocalizeTo.shared.reload(languages: welf?.languages ?? [], version: "v1.0.0")
                welf?.tableView.reloadData()
            }
        }
    }

}

extension ViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.keys.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.cellForRow(at: indexPath) ?? UITableViewCell(style: .value1, reuseIdentifier: "UITableViewCellValue1")

        let key = self.keys[indexPath.row]

        cell.textLabel?.text       = key

        //get localization for current language
        cell.detailTextLabel?.text = key.localized

        // the same as above
        //cell.detailTextLabel?.text = key.localize()

        // get localization for particular language
        //cell.detailTextLabel?.text = key.localize(to: "ru")

        return cell
    }




}

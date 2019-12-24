//
//  LocalizeTo.swift
//  LocalizeTo
//
//  Created by Sergey Chehuta on 24/08/2019.
//  Copyright © 2019 WhiteTown. All rights reserved.
//

import UIKit

@objc open class LocalizeTo: NSObject {

    @objc public static let shared = LocalizeTo()
    @objc public static let localizationFolderName = "LocalizeTo"

    private let baseURL         = "https://localize.to/api/v1"
    private var apiKey          = ""
    private var currentLanguage = Locale.current.languageCode ?? "en"
    private var defaultLanguage : String? = "en"
    private var folderName      = localizationFolderName
    public  var sortedKeys      = true

    private(set) var translations = [String:[String:String]]()


}

extension LocalizeTo {

    @objc public func configure(apiKey: String,
                                currentLanguageCode: String  = Locale.current.languageCode ?? "en",
                                defaultLanguageCode: String? = "en",
                                localizationFolderName: String = LocalizeTo.localizationFolderName) {

        self.apiKey          = apiKey
        self.currentLanguage = currentLanguageCode
        self.defaultLanguage = defaultLanguageCode
        self.folderName      = localizationFolderName
    }

    @objc public func setCurrentLanguageCode(_ languageCode: String) {
        self.currentLanguage = languageCode
    }

    @objc public func setDefaultLanguageCode(_ languageCode: String?) {
        self.defaultLanguage = languageCode
    }

}

extension LocalizeTo {

    @objc public func localize(_ key: String) -> String {
        return localize(key, to: self.currentLanguage)
    }

    @objc public func localize(_ key: String, to language: String) -> String {

        if let pairs = self.translations[language] {
            if let result = pairs[key] { return result }
        }

        if let defaultLanguage = self.defaultLanguage, language != defaultLanguage {
            if let pairs = self.translations[defaultLanguage] {
                if let result = pairs[key] { return result }
            }
        }

        return NSLocalizedString(key, comment: "")
    }

    @objc public func numberOfKeys(for language: String) -> Int {
        if let pairs = self.translations[language] {
            return pairs.keys.count
        }
        return 0
    }

    @objc public func reload(languages: [String], version: String? = nil) {
        self.translations = [:]
        load(languages: languages, version: version)
    }

    @objc public func load(languages: [String], version: String? = nil) {
        for language in languages {
            loadLanguage(language, version: version)
        }
    }

    @objc public func download(language: String, completion: @escaping (([Error]?)->Void)) {
        self.download(languages: [language], completion: completion)
    }

    @objc public func download(languages: [String], completion: @escaping (([Error]?)->Void)) {

        DispatchQueue.global(qos: .background).async {
            self.downloadLanguages(languages) { (errors) in
                DispatchQueue.main.async {
                    completion(errors)
                }
            }
        }
    }

    @objc public func download(version: String, completion: @escaping (([Error]?)->Void)) {
        self.download(version: version, languages: [], completion: completion)
    }

    @objc public func download(version: String, language: String, completion: @escaping (([Error]?)->Void)) {
        self.download(version: version, languages: [language], completion: completion)
    }

    @objc public func download(version: String, languages: [String], completion: @escaping (([Error]?)->Void)) {

        DispatchQueue.global(qos: .background).async {
            self.downloadSnapshot(version, languages: languages) { (errors) in
                DispatchQueue.main.async {
                    completion(errors)
                }
            }
        }
    }

}

private extension LocalizeTo {

    private func createOutputFolder(_ version: String? = nil) {
        let folder = localizationFolder(version)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
    }

    func loadLanguage(_ language: String, version: String? = nil) {

        if loadFromFile(filenameInDocuments(language, version), language: language) {
            return
        }

        if let filename = filenameInBundle(language) {
            let _ = loadFromFile(filename, language: language)
        }
    }

    func filenameInBundle(_ language: String) -> URL? {

        if let path = Bundle.main.path(forResource: language, ofType: "json") {
            return URL(fileURLWithPath: path)
        }
        return nil
    }

    func localizationFolder(_ version: String? = nil) -> URL {
        let docUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        if let version = version {
            return docUrl.appendingPathComponent(self.folderName).appendingPathComponent(version)
        } else {
            return docUrl.appendingPathComponent(self.folderName)
        }
    }

    func filenameInDocuments(_ language: String, _ version: String? = nil) -> URL {
        return localizationFolder(version).appendingPathComponent("\(language).json")
    }

    func loadFromFile(_ filename: URL, language: String) -> Bool {

        do {
            let data = try Data(contentsOf: filename, options: .mappedIfSafe)
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            if let langPairs = json as? [String:String] {
                self.translations[language] = self.unescapeSpecialSymbols(langPairs)
                return true
            }
        } catch {
        }
        return false
    }

}

private extension LocalizeTo {

    func unescapeSpecialSymbols(_ json: [String:String]) -> [String:String] {
        var result = [String:String]()
        for (key, value) in json {
            result[key] = value.unescaped
        }
        return result
    }

    func jsonToData(_ json: [String:String]?) -> Data? {

        guard let json = json else { return nil }

        if !self.sortedKeys {
            return try? JSONSerialization.data(withJSONObject: json as Any, options: [.prettyPrinted])
        }

        if #available(iOS 11.0, *) {
            return try? JSONSerialization.data(withJSONObject: json as Any, options: [.prettyPrinted, .sortedKeys])
        } else {

            let keys = json.keys.sorted(by: { $0 < $1 })
            var index = 1
            var text = "{\n"
            for key in keys {
                if let value = json[key] {
                    text += "  \"\(key)\": \"\(value)\"\(index==keys.count ? "" : ",")\n"
                }
                index += 1
            }
            text += "}\n"

            return text.data(using: .utf8)
        }
    }

    func downloadLanguages(_ languages: [String], completion: @escaping ([Error]?) -> Void) {

        apiCall(.languages(languages), success: { (json, data) in

            var errors = [Error]()

            if let json = json as? [String:[String:String]] {

                self.createOutputFolder()
                for language in languages {
                    let filename = self.filenameInDocuments(language)
                    if let ldata = self.jsonToData(json[language]) {
                        if let _ = try? ldata.write(to: filename, options: Data.WritingOptions.atomic) {}
                        else {
                            errors.append(LocalizeToError.withType(.savingError))
                        }
                    } else {
                        errors.append(LocalizeToError.withType(.parsingError))
                    }
                }
            } else {
                errors.append(LocalizeToError.withType(.parsingError))
            }

            errors.count > 0 ? completion(errors) : completion(nil)

        }, failure: { (error) in
            completion([error])
        })
    }

    func downloadSnapshot(_ version: String, languages: [String], completion: @escaping ([Error]?) -> Void) {

        let url: LocalizeToURL = languages.count > 0 ? .snapshot_languages(version, languages) : .snapshot(version)

        apiCall(url, success: { (json, data) in

            var errors = [Error]()

            if let json = json as? [String:[String:String]] {

                self.createOutputFolder(version)
                let snapshot_languages = languages.count > 0 ? languages : Array(json.keys)

                for language in snapshot_languages {
                    let filename = self.filenameInDocuments(language, version)

                    if let ldata = self.jsonToData(json[language]) {
                        if let _ = try? ldata.write(to: filename, options: Data.WritingOptions.atomic) {}
                        else {
                            errors.append(LocalizeToError.withType(.savingError))
                        }
                    } else {
                        errors.append(LocalizeToError.withType(.parsingError))
                    }
                }
            } else {
                errors.append(LocalizeToError.withType(.parsingError))
            }

            errors.count > 0 ? completion(errors) : completion(nil)

        }, failure: { (error) in
            completion([error])
        })
    }

}


private extension LocalizeTo {

    enum LocalizeToURL {
        case languages([String])
        case snapshot(String)
        case snapshot_languages(String, [String])
    }

    func downloadURL(_ urlString: LocalizeToURL) -> URL? {
        switch urlString {
        case .languages(let languages):
            return URL(string: "\(self.baseURL)/languages/\(languages.joined(separator: ","))?apikey=\(self.apiKey)")
        case .snapshot(let version):
            return URL(string: "\(self.baseURL)/snapshot/\(version)?apikey=\(self.apiKey)")
        case .snapshot_languages(let version, let languages):
            return URL(string: "\(self.baseURL)/snapshot/\(version)/language/\(languages.joined(separator: ","))?apikey=\(self.apiKey)")
        }
    }

    func apiCall(_ url: LocalizeToURL, success: @escaping (Any, Data) -> Void, failure: @escaping (Error) -> Void) {

        guard let url = downloadURL(url) else {
            failure(LocalizeToError.withType(.wrongURL))
            return
        }

        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept-Type")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            if let error = error {
                failure(error)
            } else {
                if let response = response as? HTTPURLResponse {
                    if response.statusCode == 200 {
                        if let data = data {
                            if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves) {
                                success(json, data)
                            } else {
                                failure(LocalizeToError.withType(.parsingError))
                            }
                        } else {
                            failure(LocalizeToError.withType(.emptyResponse))
                        }
                    } else {
                        failure(LocalizeToError.withType(.wrongStatusCode))
                    }
                } else {
                    failure(LocalizeToError.withType(.wrongResponseType))
                }
            }

        })
        task.resume()

    }
}

@objc public class LocalizeToError: NSError {

    enum LocalizeToErrorType {
        case unknown
        case wrongURL
        case wrongResponseType
        case wrongStatusCode
        case emptyResponse
        case parsingError
        case savingError

        var errorMessage: String {
            switch self {
            case .unknown:          return "UnknownError"
            case .wrongURL:         return "Cannot create URL"
            case .wrongResponseType:return "Unexpected response type"
            case .wrongStatusCode:  return "Wrong status code"
            case .emptyResponse:    return "Unexpected response"
            case .parsingError:     return "Parsing error. Not a JSON"
            case .savingError:      return "Cannot save data to a disc"
            }
        }

        var code: Int {
            switch self {
            case .unknown:          return 1
            case .wrongURL:         return 2
            case .wrongResponseType:return 3
            case .wrongStatusCode:  return 4
            case .emptyResponse:    return 5
            case .parsingError:     return 6
            case .savingError:      return 7
            }
        }
    }

    private static let domainName = "LocalizeTo"
    private static let errorKey   = "error"

    static func withType(_ type: LocalizeToErrorType) -> LocalizeToError {
        return LocalizeToError(domain: domainName, code: type.code, userInfo: [errorKey: type.errorMessage])
    }

}

extension String {

    public var localized: String {
        return LocalizeTo.shared.localize(self)
    }

    public func localize() -> String {
        return LocalizeTo.shared.localize(self)
    }

    public func localize(to language: String) -> String {
        return LocalizeTo.shared.localize(self, to: language)
    }


    #if DEBUG
    public var unlocalized: String {
        return self
    }
    #else
    @available(*, deprecated, message: "You should not use unlocalized strings in release builds")
    public var unlocalized: String {
        return self
    }
    #endif

}

private extension String {
    var unescaped: String {
        let entities = ["\0", "\t", "\n", "\r", "\"", "\'", "\\"]
        var current = self
        for entity in entities {
            let descriptionCharacters = entity.debugDescription.dropFirst().dropLast()
            let description = String(descriptionCharacters)
            current = current.replacingOccurrences(of: description, with: entity)
        }
        return current
    }
}


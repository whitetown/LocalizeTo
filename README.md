# Localize.To Swift Client

This module allows you to get localization strings from [Localize.to](https://localize.to) service.
It's nice and flexible replacement for native iOS localization files.

## Localize.To REST API

GET /language/{language}

GET /languages/{language1,language2}

GET /snapshots

GET /snapshot/latest/info

GET /snapshot/latest

GET /snapshot/{version}

GET /snapshot/{version}/language/{language}

GET /snapshot/{version}/languages/{language1,language2}

## Currently, this module implements only these API calls:

    GET /languages/{language1,language2}
    GET /snapshot/{version}
    GET /snapshot/{version}/languages/{language1,language2}

this is enough for the most cases.

## Installation

With CocoaPods:

    pod 'LocalizeTo'


## Initialize the module with an API key

```swift
    import LocalizeTo

    LocalizeTo.shared.configure(apiKey: PROJECT_API_KEY)

    //additional parameters:
    LocalizeTo.shared.configure(apiKey: PROJECT_API_KEY,
        currentLanguageCode: "es",  //by default "en"
        defaultLanguageCode: "en",  //could be nil, by default "en"
        localizationFolderName: "LocalizeTo", // by default "LocalizeTo"
        )
```

## Load earlier downloaded languages from 'Documents' or Application bundle

```swift
    LocalizeTo.shared.load(languages: ["en", "de", "es", ..., ])
```

## Set current and/or default language

```swift
    LocalizeTo.shared.setCurrentLanguageCode("fr")

    LocalizeTo.shared.setDefaultLanguageCode("en")
```

The default language is used if there is no translation for current language.
i.e.
let value = "my_key".localized
first will try to find French translation, then English translation


## Get localization strings

```swift
    //for current language
    let value = LocalizeTo.shared.localize("localization_key")

    //for particular language
    let value = LocalizeTo.shared.localize("localization_key", to: "de")
```

It's more convenient to use String extensions:

```swift
    //for current language
    let value = "localization_key".localized

    //or
    let value = "localization_key".localize()

    //for particular language
    let value = "localization_key".localize(to: "de")
```

## Special unlocalized extension

```swift
    let value = "localization_key".unlocalized
```

It does nothing for DEBUG mode, but produces a warning for RELEASE.
Use it when you do not know localization keys yet and then you can easily find all of them in your project.

## Download new localization strings from the service

    Get localized strings for particular languages

```swift
    LocalizeTo.shared.download(languages: ["en", "fr", "de", ...]) { (errors) in
        if let errors = errors {
            print(errors)
        } else {
            LocalizeTo.shared.reload(languages: ["en", "fr", "de", ...])
        }
    }

```

Get localized strings for a snapshot (all languages)

```swift
    LocalizeTo.shared.download(version: "v1.0.0") { (errors) in
        if let errors = errors {
            print(errors)
        } else {
            LocalizeTo.shared.reload(languages: ["en", "fr", "de", ...])
        }
    }

```

Get localized strings for a snapshot (particular languages)

```swift
    LocalizeTo.shared.download(version: "v1.0.0", language: "en") { (errors) in
        if let errors = errors {
            print(errors)
        } else {
            LocalizeTo.shared.load(languages: ["en"])
        }
    }

    LocalizeTo.shared.download(version: "v1.0.0", languages: ["en", "de"]) { (errors) in
        if let errors = errors {
            print(errors)
        } else {
            LocalizeTo.shared.load(languages: ["en", "de"])
        }
    }
```


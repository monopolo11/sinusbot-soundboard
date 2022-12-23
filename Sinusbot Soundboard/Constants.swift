//
//  Constants.swift
//  Sinusbot Soundboard
//
//  Created by Bernardo Ruiz  on 23/12/22.
//

import Foundation

struct LocaleObject: Codable, Hashable {
    var locale: String
    var language: String
}

let KEYCHAIN_IDENTIFIER = "dev.bernardo.ruiz.Sinusbot-Soundboard"

let Locales: [LocaleObject] = [
    LocaleObject(locale: "es_ES", language: "Spanish (Spain)"),
    LocaleObject(locale: "es_MX", language: "Spanish (Mexico)"),
    LocaleObject(locale: "en_US", language: "English (US)"),
    LocaleObject(locale: "en_UK", language: "English (UK)"),
    LocaleObject(locale: "pt_BR", language: "Portugese (Brazil)"),
    LocaleObject(locale: "it_IT", language: "Italian"),
    LocaleObject(locale: "ja_JP", language: "Japanese"),
    LocaleObject(locale: "de_DE", language: "German"),
]

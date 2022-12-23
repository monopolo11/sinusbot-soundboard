//
//  BotClient.swift
//  Sinusbot Soundboard
//
//  Created by Bernardo Ruiz  on 12/12/22.
//

import Foundation
import KeychainAccess

struct LoginResponse: Codable {
    var token: String
    var botId: String
    var success: Bool
}

struct LoginRequest: Codable {
    var username: String
    var password: String
    var botId: String = "287be86e-382a-434d-9537-6a80b35d4113"
}

struct ChannelChangeRequest: Codable {
    var channelName: String
}

struct SayTTSRequest: Codable {
    var text: String
    var locale: String
}

struct Track: Codable, Hashable {
    let uuid: String
    let duration: Int
    var title: String
    let artist: String?
}

struct Instance: Codable, Hashable {
    let backend: String
    let uuid: String
    let name: String
    let nick: String
    var running: Bool
    var playing: Bool
}

struct GenericResponse: Codable {
    let success: Bool
}

struct Client: Codable, Hashable {
    let id: String
    let uid: String
    let nick: String
    let outputMuted: Bool
    let inputMuted: Bool
    let Status: Int
}

struct Channel: Codable, Hashable {
    let id: String
    let name: String
    let parent: String
    let order: Int
    let disabled: Bool
    let clients: [Client]?
}

func getUrl() -> String? {
    do {
        let keychain = Keychain(service: KEYCHAIN_IDENTIFIER).synchronizable(true)
        let url = try keychain
            .get("url")
        if url == nil { return nil }
        return url
    } catch {
        print(error)
        return nil
    }
}

func getLoginRequest() -> LoginRequest? {
    do {
        let keychain = Keychain(service: KEYCHAIN_IDENTIFIER).synchronizable(true)
        let username = try keychain
            .get("username")
        let password = try keychain
            .get("password")
        if username == nil || password == nil { return nil }
        return LoginRequest(username: username!, password: password!)
    } catch {
        print(error)
        return nil
    }
}

func login() async -> (success: Bool, message: String?) {
    print("Logging in")
    let defaults = UserDefaults.standard
    let url: String? = getUrl()
    if url == nil { defaults.set(false, forKey: "isOnboarded"); return (false,nil) }
    let botUrl = URL(string: "\(url!)/bot/login")!
    var urlRequest = URLRequest(url: botUrl)
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.httpMethod = "POST"
    let postData: LoginRequest? = getLoginRequest()
    if postData == nil { defaults.set(false, forKey: "isOnboarded"); return (false,nil) }
    guard let encodedBody = try? JSONEncoder().encode(postData) else {
        print("Error encoding request body for login")
        return (false,"Error encoding request body for login")
    }
    do {
        let (data, response) = try await URLSession.shared.upload(for: urlRequest, from: encodedBody)
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode > 299 {
                let message = String(data: data, encoding: .utf8)
                return (false, message)
            }
        }

        let encoded = try JSONDecoder().decode(LoginResponse.self, from: data)
        defaults.set(encoded.token, forKey: "token")
        return (true, "Logged In")
    } catch {
        print("Login failed.")
        print(error)
    }
    return (false,nil)
}

func getInfoAndValidateToken() async {
    print("getInfoAndValidateToken")
    let defaults = UserDefaults.standard
    let url: String? = getUrl()
    if url == nil { defaults.set(false, forKey: "isOnboarded"); return }
    let botUrl = URL(string: "\(url!)/bot/info")!
    var urlRequest = URLRequest(url: botUrl)
    let token = "Bearer \(defaults.string(forKey: "token")!)"
    urlRequest.httpMethod = "GET"
    urlRequest.setValue(token, forHTTPHeaderField: "Authorization")
    do {
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode > 299 {
                await login()
            }
        }
        print(data)
    } catch {
        print("Get Info failed.")
        print(error)
    }
}

func getTracks() async -> [Track]? {
    print("getTracks")
    let defaults = UserDefaults.standard
    let url: String? = getUrl()
    if url == nil { defaults.set(false, forKey: "isOnboarded"); return nil }
    let botUrl = URL(string: "\(url!)/bot/files")!
    var urlRequest = URLRequest(url: botUrl)
    let token = defaults.string(forKey: "token")
    let authHeader = "Bearer \(token!)"
    urlRequest.httpMethod = "GET"
    urlRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
    do {
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        if let httpResponse = response as? HTTPURLResponse {
            print(httpResponse.statusCode)
        }
        let encoded = try JSONDecoder().decode([Track].self, from: data)
        var formatted: [Track] = []
        encoded.forEach { track in
            var trackCopy = track
            trackCopy.title = trackCopy.title.lowercased()
            formatted.append(trackCopy)
        }
        return formatted.sorted(by: { $0.title < $1.title })
    } catch {
        print("Get Tracks failed.")
        print(error)
    }
    return nil
}

func getInstances() async -> [Instance]? {
    print("getInstances")
    let defaults = UserDefaults.standard
    let url: String? = getUrl()
    if url == nil { defaults.set(false, forKey: "isOnboarded"); return nil }
    let botUrl = URL(string: "\(url!)/bot/instances")!
    var urlRequest = URLRequest(url: botUrl)
    let token = "Bearer \(defaults.string(forKey: "token")!)"
    urlRequest.httpMethod = "GET"
    urlRequest.setValue(token, forHTTPHeaderField: "Authorization")
    do {
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        if let httpResponse = response as? HTTPURLResponse {
            print(httpResponse.statusCode)
        }
        let encoded = try JSONDecoder().decode([Instance].self, from: data)
        return encoded.sorted(by: { $0.nick < $1.nick })
    } catch {
        print("Get Instances failed.")
        print(error)
    }
    return nil
}

func playAudioById(trackId: String, instanceId: String = "23558887-338b-40ae-8733-3400b7f825df") async -> Bool {
    print("playAudioById")
    let defaults = UserDefaults.standard
    let url: String? = getUrl()
    if url == nil { defaults.set(false, forKey: "isOnboarded"); return false }
    let botUrl = URL(string: "\(url!)/bot/i/\(instanceId)/play/byId/\(trackId)")!
    var urlRequest = URLRequest(url: botUrl)
    let token = "Bearer \(defaults.string(forKey: "token")!)"
    urlRequest.setValue(token, forHTTPHeaderField: "Authorization")
    urlRequest.httpMethod = "POST"
    do {
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        let encoded = try JSONDecoder().decode(GenericResponse.self, from: data)
        return encoded.success
    } catch {
        print("Playback failed.")
        print(error)
    }
    return false
}

func stopPlayback(instanceId: String) async -> Bool {
    print("stopPlayback")
    let defaults = UserDefaults.standard
    let url: String? = getUrl()
    if url == nil { defaults.set(false, forKey: "isOnboarded"); return false }
    let botUrl = URL(string: "\(url!)/bot/i/\(instanceId)/stop")!
    var urlRequest = URLRequest(url: botUrl)
    let token = "Bearer \(defaults.string(forKey: "token")!)"
    urlRequest.setValue(token, forHTTPHeaderField: "Authorization")
    urlRequest.httpMethod = "POST"
    do {
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        let encoded = try JSONDecoder().decode(GenericResponse.self, from: data)
        return encoded.success
    } catch {
        print("Stop failed.")
        print(error)
    }
    return false
}

func getChannels(instanceId: String) async -> [Channel]? {
    print("getChannels")
    let defaults = UserDefaults.standard
    let url: String? = getUrl()
    if url == nil { defaults.set(false, forKey: "isOnboarded"); return nil }
    let botUrl = URL(string: "\(url!)/bot/i/\(instanceId)/channels")!
    var urlRequest = URLRequest(url: botUrl)
    let token = "Bearer \(defaults.string(forKey: "token")!)"
    urlRequest.httpMethod = "GET"
    urlRequest.setValue(token, forHTTPHeaderField: "Authorization")
    urlRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    do {
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        let encoded = try JSONDecoder().decode([Channel].self, from: data)
        let filtered = encoded.filter {
            $0.disabled == false || $0.name.contains("no audio")
        }
        return filtered.sorted(by: { $0.name < $1.name })
    } catch {
        print("Get Channels failed.")
        print(error)
    }
    return nil
}

func changeChannel(instanceId: String, channelId: String) async -> Bool {
    print("changeChannel")
    let defaults = UserDefaults.standard
    let url: String? = getUrl()
    if url == nil { defaults.set(false, forKey: "isOnboarded"); return false }
    let botUrl = URL(string: "\(url!)/bot/i/\(instanceId)/settings")!
    var urlRequest = URLRequest(url: botUrl)
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.httpMethod = "POST"
    let token = "Bearer \(defaults.string(forKey: "token")!)"
    urlRequest.setValue(token, forHTTPHeaderField: "Authorization")
    let postData = ChannelChangeRequest(channelName: channelId)
    guard let encodedBody = try? JSONEncoder().encode(postData) else {
        print("Error encoding request body for login")
        return false
    }
    do {
        let (data, _) = try await URLSession.shared.upload(for: urlRequest, from: encodedBody)
        let encoded = try JSONDecoder().decode(GenericResponse.self, from: data)
        return encoded.success
    } catch {
        print("Change Failed failed.")
        print(error)
    }
    return false
}

func playTTS(text: String,locale: String ,instanceId: String) async -> Bool {
    print("playTTS")
    let defaults = UserDefaults.standard
    let url: String? = getUrl()
    if url == nil { defaults.set(false, forKey: "isOnboarded"); return false }
    let botUrl = URL(string: "\(url!)/bot/i/\(instanceId)/say")!
    var urlRequest = URLRequest(url: botUrl)
    let postData = SayTTSRequest(text: text, locale: locale)
    guard let encodedBody = try? JSONEncoder().encode(postData) else {
        print("Error encoding request body for login")
        return false
    }
    let token = "Bearer \(defaults.string(forKey: "token")!)"
    urlRequest.setValue(token, forHTTPHeaderField: "Authorization")
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    do {
        let (data, _) = try await URLSession.shared.upload(for: urlRequest,from: encodedBody)
        let encoded = try JSONDecoder().decode(GenericResponse.self, from: data)
        return encoded.success
    } catch {
        print("Playback failed.")
        print(error)
    }
    return false
}

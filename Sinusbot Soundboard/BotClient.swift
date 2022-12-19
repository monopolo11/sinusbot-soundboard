//
//  BotClient.swift
//  Sinusbot Soundboard
//
//  Created by Bernardo Ruiz  on 12/12/22.
//

import Foundation

let botUri: String = "https://bot.monopolo11.com/api/v1/bot"

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

func login() async {
    print("Logging in")
    let defaults = UserDefaults.standard
    let botUrl = URL(string: "\(botUri)/login")!
    var urlRequest = URLRequest(url: botUrl)
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.httpMethod = "POST"
    let postData = LoginRequest(username: "admin", password: "weywey")
    guard let encodedBody = try? JSONEncoder().encode(postData) else {
        print("Error encoding request body for login")
        return
    }
    do {
        let (data, _) = try await URLSession.shared.upload(for: urlRequest, from: encodedBody)
        let encoded = try JSONDecoder().decode(LoginResponse.self, from: data)
        defaults.set(encoded.token, forKey: "token")
    } catch {
        print("Login failed.")
        print(error)
    }
}

func getInfoAndValidateToken() async {
    print("getInfoAndValidateToken")
    let defaults = UserDefaults.standard
    let botUrl = URL(string: "\(botUri)/info")!
    var urlRequest = URLRequest(url: botUrl)
    let token = "Bearer \(defaults.string(forKey: "token")!)"
    urlRequest.httpMethod = "GET"
    urlRequest.setValue(token, forHTTPHeaderField: "Authorization")
    do {
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        if let httpResponse = response as? HTTPURLResponse {
            if(httpResponse.statusCode > 299) {
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
    let botUrl = URL(string: "\(botUri)/files")!
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
    let botUrl = URL(string: "\(botUri)/instances")!
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
        return encoded
    } catch {
        print("Get Instances failed.")
        print(error)
    }
    return nil
}

func playAudioById(trackId: String = "891c6bc4-beb1-44ae-8060-05a2a82ddec5", instanceId: String = "23558887-338b-40ae-8733-3400b7f825df") async -> Bool {
    print("playAudioById")
    let defaults = UserDefaults.standard
    let botUrl = URL(string: "\(botUri)/i/\(instanceId)/play/byId/\(trackId)")!
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
    let botUrl = URL(string: "\(botUri)/i/\(instanceId)/stop")!
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
    let botUrl = URL(string: "\(botUri)/i/\(instanceId)/channels")!
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
        return filtered
    } catch {
        print("Get Channels failed.")
        print(error)
    }
    return nil
}

func changeChannel(instanceId: String, channelId: String) async -> Bool {
    print("changeChannel")
    let defaults = UserDefaults.standard
    let botUrl = URL(string: "\(botUri)/i/\(instanceId)/settings")!
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

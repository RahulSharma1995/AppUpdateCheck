//
//  AppVersionCheckManager.swift
//  AppVersionCheckManager
//
//  Created by Rahul Sharma on 11/05/22.
//  Copyright © 2022 AppVersionCheckManager. All rights reserved.
//

import Foundation
import Combine
import UIKit

enum NetworkError: Error {
    case invalidURL
    case responseError
    case unknown
}

struct LookupModel: Decodable {
    let appinfo: [AppInfoModel]?
    
    enum CodingKeys: String, CodingKey {
        case appinfo  = "results"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        appinfo  = try values.decodeIfPresent([AppInfoModel].self, forKey: .appinfo )
    }
    
}

struct AppInfoModel: Decodable {
    let version: String
    let trackViewUrl: String
}

class AppVersionCheckManager {
    
    static let shared = AppVersionCheckManager()
    
    private init(){ }
    private var cancellables = Set<AnyCancellable>()
    
    func showUpdateView(complition: @escaping (Bool) -> Void){
        checkVersionInfo { complition($0) }
    }
    
    private func checkVersionInfo(infoComplition: @escaping (Bool) -> Void) {
        if let currentVersion = getBundle(key: "CFBundleShortVersionString") {
            getVersionInfo()
                .tryMap({ info -> Bool in
                    return info.version > currentVersion
//                    return  "2.3.9" > "2.4"
                })
                .receive(on: RunLoop.main)
                .sink { completion in
                    if case .failure(_) = completion {
                        infoComplition(false)
                    }
                    print("App Info Complition: \(completion)")
                } receiveValue: { infoComplition($0) }
                .store(in: &cancellables)
        }
    }
    
    private func getVersionInfo()-> Future<AppInfoModel, Error>{
        return Future<AppInfoModel, Error> { [weak self] promise in
            guard let self = self, let identifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String, let url = URL(string: "http://itunes.apple.com/in/lookup?bundleId=\(identifier)") else {
                return
            }
            URLSession.shared.dataTaskPublisher(for: url)
                .tryMap { (data, response) -> Data in
                    guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                        throw NetworkError.responseError
                    }
                    return data
                }
                .decode(type: LookupModel.self, decoder: JSONDecoder())
                .tryMap { lookup -> AppInfoModel in
                    guard let info = lookup.appinfo?.first else {
                        throw NetworkError.unknown
                    }
                    return info
                }
                .sink { completion in
                    if case let .failure(error) = completion {
                        switch error {
                        case let decodingError as DecodingError:
                            print("")
                            promise(.failure(decodingError))
                        case let apiError as NetworkError:
                            print("")
                            promise(.failure(apiError))
                        default:
                            print("")
                            promise(.failure(NetworkError.unknown))
                        }
                    }
                } receiveValue: { promise(.success($0))}
                .store(in: &self.cancellables)
        }
    }
    
    func getBundle(key: String) -> String? {
        guard let filePath = Bundle.main.path(forResource: "Info", ofType: "plist") else {
            return nil
        }
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: key) as? String else {
            return nil
        }
        return value
    }
    
}

//
//  Bundle-Decoding.swift
//  spaceshooter
//
//  Created by iMac on 6/2/20.
//  Copyright © 2020 Lord Nibbler. All rights reserved.
//

// 37:26
// 1:02:22
import Foundation

extension Bundle {
    // decode some sort of decodable thing in our bundle (for loading JSON)
    func decode<T: Decodable>(_ type: T.Type, from file: String) -> T {
        // get URL to file to decode
        guard let url = self.url(forResource: file, withExtension: nil) else {
            fatalError("Failed to locate \(file) in bundle")
        }

        // get data from url
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(file) from bundle")
        }

        // decode it as JSON
        let decoder = JSONDecoder()
    
        var loaded: T?
        do {
            loaded = try decoder.decode(T.self, from: data) as T
        } catch {
            print("Unexpected error: \(error).")
            fatalError("Failed to decode \(file) from bundle.")
        }
        
        return loaded!
    }
}

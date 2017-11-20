//
//  Geohash.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 11/9/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation

struct Geohash {
    
    private static let DecimalToBase32Map = Array("0123456789bcdefghjkmnpqrstuvwxyz")
    private static let Base32BitflowInit: UInt8 = 0b10000

   private enum Parity {
        case even, odd
    }
    
    private static func Flip(_ parity: Parity) -> Parity {
        return parity == .even ? .odd : .even
    }
    
    public static func decode(_ hash: String) -> (latitude: Double, longitude: Double)? {
        var parityMode = Parity.even;
        var lat = (-90.0, 90.0)
        var long = (-180.0, 180.0)
        
        for char in hash {
            guard let bitmap = DecimalToBase32Map.index(of: char) else {
                return nil
            }
            
            var mask = Int(Base32BitflowInit)
            while mask != 0 {
                
                switch (parityMode) {
                case .even:
                    if(bitmap & mask != 0) {
                        long.0 = (long.0 + long.1) / 2
                    } else {
                        long.1 = (long.0 + long.1) / 2
                    }
                case .odd:
                    if(bitmap & mask != 0) {
                        lat.0 = (lat.0 + lat.1) / 2
                    } else {
                        lat.1 = (lat.0 + lat.1) / 2
                    }
                }
                
                parityMode = Flip(parityMode)
                mask >>= 1
            }
        }
        let latitude = (lat.1 + lat.0) / 2
        let longitude = (long.1 + long.0) / 2
        return (latitude, longitude)
    }
    
    public static func encode(latitude: Double, longitude: Double, precision: Int) -> String {
        var lat = (-90.0, 90.0)
        var long = (-180.0, 180.0)
        
        var result = String()
        
        var parityMode = Parity.even
        var base32char = 0
        var bit = Base32BitflowInit
        
        repeat {
            switch (parityMode) {
            case .even:
                let mid = (long.0 + long.1) / 2
                if(longitude >= mid) {
                    base32char |= Int(bit)
                    long.0 = mid;
                } else {
                    long.1 = mid;
                }
            case .odd:
                let mid = (lat.0 + lat.1) / 2
                if(latitude >= mid) {
                    base32char |= Int(bit)
                    lat.0 = mid;
                } else {
                    lat.1 = mid;
                }
            }
            
            parityMode = Flip(parityMode)
            bit >>= 1
            
            if(bit == 0b00000) {
                result += String(DecimalToBase32Map[base32char])
                bit = Base32BitflowInit
                base32char = 0
            }
            
        } while result.count < precision
        return result
    }
}

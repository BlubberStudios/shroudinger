//
//  ShroudingerExtension.swift
//  ShroudingerExtension
//
//  Created by Rex Liu on 7/11/25.
//

import Foundation
import FSKit

@main
struct ShroudingerExtension : UnaryFileSystemExtension {
    var fileSystem : FSUnaryFileSystem & FSUnaryFileSystemOperations {
        ShroudingerExtensionFileSystem()
    }
}

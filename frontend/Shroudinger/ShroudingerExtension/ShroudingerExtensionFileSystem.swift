//
//  ShroudingerExtensionFileSystem.swift
//  ShroudingerExtension
//
//  Created by Rex Liu on 7/11/25.
//

import Foundation
import FSKit

@objc
class ShroudingerExtensionFileSystem : FSUnaryFileSystem & FSUnaryFileSystemOperations {
    func probeResource(resource: FSResource) async throws -> FSProbeResult {
        <#code#>
    }

    func loadResource(resource: FSResource, options: FSTaskOptions) async throws -> FSVolume {
        <#code#>
    }

    func unloadResource(resource: FSResource, options: FSTaskOptions) async throws {
        <#code#>
    }
}

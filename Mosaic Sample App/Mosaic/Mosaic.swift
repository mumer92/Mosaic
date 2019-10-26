//
//  Mosaic.swift
//  Mosaic
//
//  Created by Boris Emorine on 10/11/19.
//  Copyright © 2019 Boris Emorine. All rights reserved.
//

import UIKit

public final class Mosaic {
    
    /// The numbner of tiles in the mosaic per length (width & height).
    private static let numberOfTiles: Int = 20
    
    private var tileRects: TileRects?
    
    private let imagePositionMapper: PoolTileMapper
    private let averageZoneColorFinder = AverageZoneColorFinder()
    
    // MARK: Public Functions
    
    public init(imagePool: [UIImage]) throws {
        guard imagePool.count > 3 else {
            let error = NSError()
            throw error
        }
        
        let poolManager = ImagePoolManager(images: imagePool)
        self.imagePositionMapper = PoolTileMapper(poolManager: poolManager)
    }
    
    public func generateMosaic(for texture: MTLTexture) -> UIImage? {
        let imageSize = CGSize(width: texture.width, height: texture.height)
        
        guard let tileRects = tileRects else {
            generateTileRects(with: imageSize)
            return generateMosaic(for: texture)
        }
        
        let averageColors = averageZoneColorFinder.findAverageZoneColor(on: texture, with: tileRects)
        
        return mosaic(with: imageSize, tileRects, averageColors)
    }
    
    public func generateMosaic(for image: CGImage) -> UIImage? {
        let imageSize = CGSize(width: image.width, height: image.height)
        
        guard let tileRects = tileRects else {
            generateTileRects(with: imageSize)
            return generateMosaic(for: image)
        }

        let averageColors = averageZoneColorFinder.findAverageZoneColor(on: image, with: tileRects)
        
        return mosaic(with: imageSize, tileRects, averageColors)
    }
    
    private func mosaic(with imageSize: CGSize, _ tileRects: TileRects, _ averageColors: [UInt16]) -> UIImage? {
        let tileImagePositions = imagePositionMapper.imagePositions(for: tileRects, of: averageColors)
        let mosaicImage = ImageStitcher.stitch(images: tileImagePositions, to: imageSize)

        return mosaicImage
    }
    
    /// Optionally prepares the `Mosaic` instance so that it can start doing its work as fast as possible.
    /// Call this function when you know that a mosaic could be generated, but the process hasn't started yet.
    /// @see `preHeat()`
    /// - Parameters:
    ///   - imageSize: The size of the image that will be transformed into a Mosaic.
    public func preHeat(withImageSize imageSize: CGSize? = nil) {
        imagePositionMapper.preHeat()
        averageZoneColorFinder.preHeat()
        if let imageSize = imageSize {
            generateTileRects(with: imageSize)
        }
    }
    
    // MARK: - Convenience
    
    private func generateTileRects(with imageSize: CGSize) {
        self.tileRects = TileRects(numberOfTiles: Mosaic.numberOfTiles, imageSize: imageSize)
    }
    
}

struct ImagePositionValuePair {
    
    let image: UIImage
    let position: CGPoint
    
}

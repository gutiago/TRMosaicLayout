//
//  TRMosaicColumn.swift
//  Pods
//
//  Created by Vincent Le on 7/7/16.
//
//

import UIKit

struct TRMosaicColumns {
    
    var columns:[TRMosaicColumn]
    
    var smallestColumn: TRMosaicColumn {
        return columns.sorted().first!
    }
    
    var biggestColumn: TRMosaicColumn {
        return columns.sorted().last!
    }
    
    init() {
        columns = [TRMosaicColumn](repeating: TRMosaicColumn(), count: 3)
    }
    
    subscript(index: Int) -> TRMosaicColumn {
        get {
            return columns[index]
        }
        set(newColumn) {
            columns[index] = newColumn
        }
    }
}

struct TRRandomSize {
    private static var lastMosaic = 0
    private static var randomMosaic = [TRMosaicCellType]()
    
    static func getRandomMosaic(at indexPath: IndexPath) -> TRMosaicCellType {
        return randomMosaic[indexPath.item]
    }
    
    static func generateMosaicArray(for numberOfItems: Int, appendingObjects: Bool) {
        if !appendingObjects {
            randomMosaic.removeAll()
        }
        for _ in 0..<numberOfItems {
            guard randomMosaic.count < numberOfItems else {
                return
            }
            randomMosaic.append(contentsOf: randomSize())
        }
    }
    
    static func random(_ range: UInt32) -> Int {
        return Int(arc4random_uniform(range))
    }
    
    static func randomSize() -> [TRMosaicCellType] {
        let randomNumber = random(2)
        var options = [0, 1, 2]
        options.remove(at: options.index(of: lastMosaic)!)
        
        let switchValue = randomNumber == 0 ? options.first! : options.last!
        
        TRRandomSize.lastMosaic = switchValue
        switch switchValue {
        case 0:
            return [.small, .small, .small]
        case 1:
            return [.medium, .medium]
        default:
            return [.big, .small, .small]
        }
    }
    
}

struct TRMosaicColumn {
    var columnHeight: CGFloat
    
    init() {
        columnHeight = 0
    }
    
    mutating func appendToColumn(withHeight height: CGFloat) {
        columnHeight += height
    }
}

extension TRMosaicColumn: Equatable { }
extension TRMosaicColumn: Comparable { }

// MARK: Equatable

func ==(lhs: TRMosaicColumn, rhs: TRMosaicColumn) -> Bool {
    return lhs.columnHeight == rhs.columnHeight
}

// MARK: Comparable

func <=(lhs: TRMosaicColumn, rhs: TRMosaicColumn) -> Bool {
    return lhs.columnHeight <= rhs.columnHeight
    
}

func >(lhs: TRMosaicColumn, rhs: TRMosaicColumn) -> Bool {
    return lhs.columnHeight > rhs.columnHeight
}

func <(lhs: TRMosaicColumn, rhs: TRMosaicColumn) -> Bool {
    return lhs.columnHeight < rhs.columnHeight
}

func >=(lhs: TRMosaicColumn, rhs: TRMosaicColumn) -> Bool {
    return lhs.columnHeight >= rhs.columnHeight
}

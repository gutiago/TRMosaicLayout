//
//  TRMosaicLayout.swift
//  Pods
//
//  Created by Vincent Le on 7/1/16.
//
//

import UIKit

public enum TRMosaicCellType {
    case big
    case medium
    case small
}

public protocol TRMosaicLayoutDelegate {
    
    /* func collectionView(_ collectionView:UICollectionView, mosaicCellSizeTypeAtIndexPath indexPath:IndexPath) -> TRMosaicCellType */
    
    func collectionView(_ collectionView:UICollectionView, layout collectionViewLayout: TRMosaicLayout, insetAtSection:Int) -> UIEdgeInsets
    
    func heightForSmallMosaicCell() -> CGFloat
    
}

open class TRMosaicLayout: UICollectionViewLayout {
    
    open var delegate:TRMosaicLayoutDelegate!
    
    var columns = TRMosaicColumns()
    
    var cachedCellLayoutAttributes = [IndexPath:UICollectionViewLayoutAttributes]()
    
    let numberOfColumnsInSection = 3
    let numberOfColumnsMedium = 2
    
    var contentWidth:CGFloat {
        get { return collectionView!.bounds.size.width }
    }
    
    // MARK: - UICollectionViewLayout Implementation
    
    override open func prepare() {
        super.prepare()
        resetLayoutState()
        configureMosaicLayout()
    }
    
    /**
     Iterates throught all items in section and
     creates new layouts for each item as a mosaic cell
     */
    func configureMosaicLayout() {
        // Queue containing cells that have yet to be added due to column constraints
        var smallCellIndexPathBuffer = [IndexPath]()
        var mediumCellIndexPathBuffer = [IndexPath]()
        
        var lastBigCellOnLeftSide = false
        // Loops through all items in the first section, this layout has only one section
        for cellIndex in 0..<collectionView!.numberOfItems(inSection: 0) {
            
            (lastBigCellOnLeftSide, smallCellIndexPathBuffer, mediumCellIndexPathBuffer) = createCellLayout(withIndexPath: cellIndex,
                                                                                                            bigCellSide: lastBigCellOnLeftSide,
                                                                                                            cellBuffer: smallCellIndexPathBuffer, mediumCellBuffer: mediumCellIndexPathBuffer)
        }
    }
    
    /**
     Creates new layout for the cell at specified index path
     
     - parameter index:       index path of cell
     - parameter bigCellSide: specifies which side to place big cell
     - parameter cellBuffer:  buffer containing small cell
     - parameter mediumCellBuffer:  buffer containing medium cell
     
     - returns: tuple containing cellSide and cellBuffer, only one of which will be mutated
     */
    func createCellLayout(withIndexPath index: Int, bigCellSide: Bool, cellBuffer: [IndexPath], mediumCellBuffer: [IndexPath]) -> (Bool, [IndexPath], [IndexPath]) {
        let cellIndexPath = IndexPath(item: index, section: 0)
        let cellType:TRMosaicCellType = mosaicCellType(index: cellIndexPath)
        
        var newSmallBuffer = cellBuffer
        var newMediumBuffer = mediumCellBuffer
        var newSide = bigCellSide
        
        if cellType == .big {
            newSide = createBigCellLayout(withIndexPath: cellIndexPath, cellSide: bigCellSide)
        } else if cellType == .medium {
            newMediumBuffer = createMediumCellLayout(withIndexPath: cellIndexPath, buffer: newMediumBuffer)
        } else if cellType == .small {
            newSmallBuffer = createSmallCellLayout(withIndexPath: cellIndexPath, buffer: newSmallBuffer)
        }
        return (newSide, newSmallBuffer, newMediumBuffer)
    }
    
    /**
     Creates new layout for the big cell at specified index path
     - returns: returns new cell side
     */
    func createBigCellLayout(withIndexPath indexPath:IndexPath, cellSide: Bool) -> Bool {
        addBigCellLayout(atIndexPath: indexPath, atColumn: cellSide ? 1 : 0)
        return !cellSide
    }
    
    /**
     Creates new layout for the medium cell at specified index path
     - returns: returns new cell side
     */
    func createMediumCellLayout(withIndexPath indexPath:IndexPath, buffer: [IndexPath]) -> [IndexPath] {
        var newBuffer = buffer
        newBuffer.append(indexPath)
        if newBuffer.count >= 2 {
            addMediumCellLayout(atIndexPath: newBuffer[1], atColumn: 1)
            newBuffer.removeAll()
        } else {
            addMediumCellLayout(atIndexPath: newBuffer[0], atColumn: 0)
        }
        return newBuffer
    }
    
    /**
     Creates new layout for the small cell at specified index path
     - returns: returns new cell buffer
     */
    func createSmallCellLayout(withIndexPath indexPath:IndexPath, buffer: [IndexPath]) -> [IndexPath] {
        var newBuffer = buffer
        newBuffer.append(indexPath)
        if newBuffer.count >= 1 {
            addSmallCellLayout(atIndexPath: newBuffer[0], atColumn: indexOfShortestColumn())
            newBuffer.removeAll()
        }
        return newBuffer
    }
    
    /**
     Returns the entire content view of the collection view
     */
    override open var collectionViewContentSize: CGSize {
        get {
            
            let height: CGFloat = columns.biggestColumn.columnHeight
            return CGSize(width: contentWidth, height: height)
        }
    }
    
    /**
     Returns all layout attributes within the given rectangle
     */
    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributesInRect = [UICollectionViewLayoutAttributes]()
        cachedCellLayoutAttributes.forEach {
            if rect.intersects($1.frame) {
                attributesInRect.append($1)
            }
        }
        return attributesInRect
    }
    
    /**
     Returns all layout attributes for the current indexPath
     */
    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        return self.cachedCellLayoutAttributes[indexPath]
        
    }
    
    // MARK: Layout
    
    /**
     Configures the layout for cell type: Big
     Adds the new layout to cache
     Updates the column heights for each effected column
     */
    func addBigCellLayout(atIndexPath indexPath:IndexPath, atColumn column:Int) {
        let cellHeight = layoutAttributes(withCellType: .big, indexPath: indexPath, atColumn: column)
        
        columns[column].appendToColumn(withHeight: cellHeight)
        columns[column + 1].appendToColumn(withHeight: cellHeight)
    }
    
    /**
     Configures the layout for cell type: Medium
     Adds the new layout to cache
     Updates the column heights for each effected column
     */
    func addMediumCellLayout(atIndexPath indexPath:IndexPath, atColumn column:Int) {
        let cellHeight = layoutAttributes(withCellType: .medium, indexPath: indexPath, atColumn: column)
        columns[column].appendToColumn(withHeight: cellHeight)
        if column == 1 {
            columns[column + 1].appendToColumn(withHeight: cellHeight)
        }
    }
    
    /**
     Configures the layout for cell type: Small
     Adds the new layout to cache
     Updates the column heights for each effected column
     */
    func addSmallCellLayout(atIndexPath indexPath:IndexPath, atColumn column:Int) {
        let cellHeight = layoutAttributes(withCellType: .small, indexPath: indexPath, atColumn: column)
        columns[column].appendToColumn(withHeight: cellHeight)
    }
    
    /**
     Creates layout attribute with the given parameter and adds it to cache
     
     - parameter type:      Cell type
     - parameter indexPath: Index of cell
     - parameter column:    Index of column
     
     - returns: new cell height from layout
     */
    func layoutAttributes(withCellType type: TRMosaicCellType, indexPath:IndexPath, atColumn column:Int) -> CGFloat {
        let layoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        let frame = cellRect(for: type, at: indexPath, column: column)
        
        layoutAttributes.frame = frame
        
        let cellHeight = layoutAttributes.frame.size.height + insetForMosaicCell().top
        
        cachedCellLayoutAttributes[indexPath] = layoutAttributes
        
        return cellHeight
    }
    
    // MARK: Cell Sizing
    
    /**
     Creates the bounding rectangle for the given cell type
     
     - parameter type:      Cell type
     - parameter indexPath: Index of cell
     - parameter column:    Index of column
     
     - returns: Bounding rectangle
     */
    func cellRect(for type: TRMosaicCellType, at indexPath: IndexPath, column: Int) -> CGRect {
        var mosaicCellHeight = cellHeight(for: type)
        var mosaicCellWidth = cellWidth(for: type)
        
        let numberOfColumns = type != .medium ? numberOfColumnsInSection : numberOfColumnsMedium
        var originX: CGFloat = CGFloat(column) * (contentWidth / CGFloat(numberOfColumns))
        var originY: CGFloat = columns[column].columnHeight
        
        let sectionInset = insetForMosaicCell()
        
        originX += sectionInset.left
        originY += sectionInset.top
        
        mosaicCellWidth -= sectionInset.right
        mosaicCellHeight -= sectionInset.bottom
        
        return CGRect(x: originX, y: originY, width: mosaicCellWidth, height: mosaicCellHeight)
    }
    
    /**
     Calculates height for the given cell type
     
     - parameter cellType: Cell type
     
     - returns: Calculated height
     */
    func cellHeight(for mosaic: TRMosaicCellType) -> CGFloat {
        let height = delegate.heightForSmallMosaicCell()
        switch mosaic {
        case .small:
            return height
        case .medium:
            return height * 1.5
        default:
            return height * 2
        }
    }
    
    /**
     Calculates width for the given cell type
     
     - parameter cellType: Cell type
     
     - returns: Calculated width
     */
    func cellWidth(for mosaic: TRMosaicCellType) -> CGFloat {
        switch mosaic {
        case .small:
            return contentWidth / 3
        case .medium:
            return contentWidth / 2
        default:
            return (contentWidth / 3) * 2
        }
    }
    
    // MARK: Orientation
    
    /**
     Determines if a layout update is needed when the bounds have been changed
     
     - returns: True if layout needs update
     */
    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        let currentBounds:CGRect = self.collectionView!.bounds
        
        if currentBounds.size.equalTo(newBounds.size) {
            self.prepare()
            return true
        }
        
        return false
    }
    
    // MARK: Delegate Wrappers
    
    /**
     Returns the cell type for the specified cell at index path
     You can also use the delegate method:
     delegate.collectionView(collectionView!, mosaicCellSizeTypeAtIndexPath:indexPath)
     
     - returns: Cell type
     */
    func mosaicCellType(index indexPath: IndexPath) -> TRMosaicCellType {
        return TRRandomSize.getRandomMosaic(at: indexPath)
    }
    
    /**
     - returns: Returns the UIEdgeInsets that will be used for every cell as a border
     */
    func insetForMosaicCell() -> UIEdgeInsets {
        return delegate.collectionView(collectionView!, layout: self, insetAtSection: 0)
    }
}

extension TRMosaicLayout {
    
    // MARK: Helper Functions
    
    /**
     - returns: The index of the column with the smallest height
     */
    func indexOfShortestColumn() -> Int {
        guard let min = columns.columns.min(), let index = columns.columns.index(of: min) else {
            return 0
        }
        return index
    }
    
    /**
     Resets the layout cache and the heights array
     */
    func resetLayoutState() {
        columns = TRMosaicColumns()
        cachedCellLayoutAttributes = [IndexPath:UICollectionViewLayoutAttributes]()
    }
}

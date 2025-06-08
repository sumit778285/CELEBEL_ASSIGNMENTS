-- 1. InsertOrderDetails Procedure
GO
CREATE PROCEDURE InsertOrderDetail
    @OrderID INT,
    @ProductID INT,
    @UnitPrice MONEY = NULL,
    @Quantity INT,
    @Discount FLOAT = 0
AS
BEGIN
    DECLARE @CurrentStock INT, @ReorderLevel INT, @ProductPrice MONEY
    
    -- Check if product exists and get current stock
    SELECT @CurrentStock = Quantity, @ReorderLevel = SafetyStockLevel, @ProductPrice = ListPrice
    FROM Production.ProductInventory pi
    JOIN Production.Product p ON pi.ProductID = p.ProductID
    WHERE pi.ProductID = @ProductID
    
    -- If no UnitPrice provided, use product's list price
    IF @UnitPrice IS NULL
        SET @UnitPrice = @ProductPrice
    
    -- Check if enough stock exists
    IF @CurrentStock IS NULL OR @CurrentStock < @Quantity
    BEGIN
        PRINT 'Not enough stock available for ProductID ' + CAST(@ProductID AS VARCHAR)
        RETURN -1
    END
    
    BEGIN TRY
        BEGIN TRANSACTION
        
        -- Insert order detail
        INSERT INTO Sales.SalesOrderDetail (
            SalesOrderID, ProductID, OrderQty, UnitPrice, UnitPriceDiscount
        ) VALUES (
            @OrderID, @ProductID, @Quantity, @UnitPrice, @Discount
        )
        
        -- Check if insert was successful
        IF @@ROWCOUNT = 0
        BEGIN
            PRINT 'Failed to place the order. Please try again.'
            ROLLBACK TRANSACTION
            RETURN -1
        END
        
        -- Update inventory
        UPDATE Production.ProductInventory
        SET Quantity = Quantity - @Quantity
        WHERE ProductID = @ProductID
        
        -- Check if stock dropped below reorder level
        IF (@CurrentStock - @Quantity) < @ReorderLevel
            PRINT 'Warning: Stock for ProductID ' + CAST(@ProductID AS VARCHAR) + ' has dropped below reorder level.'
        
        COMMIT TRANSACTION
        PRINT 'Order successfully placed.'
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        
        PRINT 'Error occurred: ' + ERROR_MESSAGE()
        RETURN -1
    END CATCH
END
GO

-- 2. UpdateOrderDetails Procedure
GO
CREATE PROCEDURE UpdateOrderDetails
    @OrderID INT,
    @ProductID INT,
    @UnitPrice MONEY = NULL,
    @Quantity INT = NULL,
    @Discount FLOAT = NULL
AS
BEGIN
    DECLARE @OldQuantity INT, @OldUnitPrice MONEY, @OldDiscount FLOAT
    DECLARE @CurrentStock INT, @NewQuantity INT
    
    -- Get existing order details
    SELECT @OldQuantity = OrderQty, @OldUnitPrice = UnitPrice, @OldDiscount = UnitPriceDiscount
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID AND ProductID = @ProductID
    
    -- If order detail doesn't exist
    IF @OldQuantity IS NULL
    BEGIN
        PRINT 'Order detail not found for OrderID ' + CAST(@OrderID AS VARCHAR) + ' and ProductID ' + CAST(@ProductID AS VARCHAR)
        RETURN -1
    END
    
    -- Get current stock
    SELECT @CurrentStock = Quantity
    FROM Production.ProductInventory
    WHERE ProductID = @ProductID
    
    -- Calculate net quantity change
    SET @NewQuantity = ISNULL(@Quantity, @OldQuantity)
    
    -- Check if enough stock exists for increase
    IF @Quantity > @OldQuantity AND (@CurrentStock - (@Quantity - @OldQuantity)) < 0
    BEGIN
        PRINT 'Not enough stock available to increase quantity for ProductID ' + CAST(@ProductID AS VARCHAR)
        RETURN -1
    END
    
    BEGIN TRY
        BEGIN TRANSACTION
        
        -- Update order detail
        UPDATE Sales.SalesOrderDetail
        SET 
            OrderQty = ISNULL(@Quantity, OrderQty),
            UnitPrice = ISNULL(@UnitPrice, UnitPrice),
            UnitPriceDiscount = ISNULL(@Discount, UnitPriceDiscount)
        WHERE SalesOrderID = @OrderID AND ProductID = @ProductID
        
        -- Update inventory based on quantity change
        IF @Quantity IS NOT NULL AND @Quantity <> @OldQuantity
        BEGIN
            UPDATE Production.ProductInventory
            SET Quantity = Quantity + (@OldQuantity - @NewQuantity)
            WHERE ProductID = @ProductID
        END
        
        COMMIT TRANSACTION
        PRINT 'Order details successfully updated.'
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        
        PRINT 'Error occurred: ' + ERROR_MESSAGE()
        RETURN -1
    END CATCH
END
GO

-- 3. GetOrderDetails Procedure
GO
CREATE PROCEDURE GetOrderDetails
    @OrderID INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Sales.SalesOrderHeader WHERE SalesOrderID = @OrderID)
    BEGIN
        PRINT 'The OrderID ' + CAST(@OrderID AS VARCHAR) + ' does not exist'
        RETURN 1
    END
    
    SELECT 
        sod.SalesOrderDetailID,
        sod.ProductID,
        p.Name AS ProductName,
        sod.OrderQty,
        sod.UnitPrice,
        sod.UnitPriceDiscount,
        sod.LineTotal
    FROM Sales.SalesOrderDetail sod
    JOIN Production.Product p ON sod.ProductID = p.ProductID
    WHERE sod.SalesOrderID = @OrderID
END
GO

-- 4. DeleteOrderDetails Procedure
GO
CREATE PROCEDURE DeleteOrderDetails
    @OrderID INT,
    @ProductID INT
AS
BEGIN
    -- Validate parameters
    IF NOT EXISTS (SELECT 1 FROM Sales.SalesOrderHeader WHERE SalesOrderID = @OrderID)
    BEGIN
        PRINT 'Invalid OrderID: ' + CAST(@OrderID AS VARCHAR)
        RETURN -1
    END
    
    IF NOT EXISTS (SELECT 1 FROM Sales.SalesOrderDetail WHERE SalesOrderID = @OrderID AND ProductID = @ProductID)
    BEGIN
        PRINT 'ProductID ' + CAST(@ProductID AS VARCHAR) + ' not found in OrderID ' + CAST(@OrderID AS VARCHAR)
        RETURN -1
    END
    
    DECLARE @Quantity INT
    
    -- Get quantity being deleted
    SELECT @Quantity = OrderQty
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID AND ProductID = @ProductID
    
    BEGIN TRY
        BEGIN TRANSACTION
        
        -- Delete the order detail
        DELETE FROM Sales.SalesOrderDetail
        WHERE SalesOrderID = @OrderID AND ProductID = @ProductID
        
        -- Restore inventory
        UPDATE Production.ProductInventory
        SET Quantity = Quantity + @Quantity
        WHERE ProductID = @ProductID
        
        COMMIT TRANSACTION
        PRINT 'Order detail successfully deleted.'
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        
        PRINT 'Error occurred: ' + ERROR_MESSAGE()
        RETURN -1
    END CATCH
END
GO

--Functions

-- 1. Date Format MM/DD/YYYY
GO
CREATE FUNCTION dbo.FormatDateMMDDYYYY
(
    @InputDate DATETIME
)
RETURNS VARCHAR(10)
AS
BEGIN
    RETURN CONVERT(VARCHAR(10), @InputDate, 101)
END
GO

-- 2. Date Format YYYYMMDD
GO
CREATE FUNCTION dbo.FormatDateYYYYMMDD
(
    @InputDate DATETIME
)
RETURNS VARCHAR(8)
AS
BEGIN
    RETURN CONVERT(VARCHAR(8), @InputDate, 112)
END
GO

--Views

-- 1. vwCustomerOrders
GO
CREATE VIEW vwCustomerOrders AS
SELECT 
    c.AccountNumber AS CompanyName,
    soh.SalesOrderID AS OrderID,
    soh.OrderDate,
    sod.ProductID,
    p.Name AS ProductName,
    sod.OrderQty AS Quantity,
    sod.UnitPrice,
    (sod.OrderQty * sod.UnitPrice * (1 - sod.UnitPriceDiscount)) AS TotalPrice
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
GO

-- 2. vwCustomerOrdersYesterday
GO
CREATE VIEW vwCustomerOrdersYesterday AS
SELECT 
    c.AccountNumber AS CompanyName,
    soh.SalesOrderID AS OrderID,
    soh.OrderDate,
    sod.ProductID,
    p.Name AS ProductName,
    sod.OrderQty AS Quantity,
    sod.UnitPrice,
    (sod.OrderQty * sod.UnitPrice * (1 - sod.UnitPriceDiscount)) AS TotalPrice
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
WHERE CONVERT(DATE, soh.OrderDate) = CONVERT(DATE, DATEADD(day, -1, GETDATE()))
GO

-- 3. MyProducts View (Updated to use correct Vendor relationships)
GO
CREATE VIEW MyProducts AS
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    p.Size AS QuantityPerUnit,
    p.ListPrice AS UnitPrice,
    v.Name AS CompanyName,
    pc.Name AS CategoryName
FROM Production.Product p
LEFT JOIN Purchasing.ProductVendor pv ON p.ProductID = pv.ProductID
LEFT JOIN Purchasing.Vendor v ON pv.VendorID = v.VendorID
LEFT JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
LEFT JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE p.DiscontinuedDate IS NULL
GO


--Triggers
-- 1. Instead of Delete Trigger for Orders
GO
CREATE TRIGGER tr_OrderDelete
ON Sales.SalesOrderHeader
INSTEAD OF DELETE
AS
BEGIN
    -- First delete all order details for the deleted orders
    DELETE FROM Sales.SalesOrderDetail
    WHERE SalesOrderID IN (SELECT SalesOrderID FROM deleted)
    
    -- Then delete the orders
    DELETE FROM Sales.SalesOrderHeader
    WHERE SalesOrderID IN (SELECT SalesOrderID FROM deleted)
    
    PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' order(s) and their details were deleted.'
END
GO

-- 2. Order Detail Insert Trigger for Stock Check
GO
CREATE TRIGGER tr_OrderDetailInsert
ON Sales.SalesOrderDetail
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @ProductID INT, @Quantity INT, @CurrentStock INT
    
    -- Cursor to process each inserted row
    DECLARE order_cursor CURSOR FOR
    SELECT ProductID, OrderQty FROM inserted
    
    OPEN order_cursor
    FETCH NEXT FROM order_cursor INTO @ProductID, @Quantity
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Get current stock
        SELECT @CurrentStock = Quantity
        FROM Production.ProductInventory
        WHERE ProductID = @ProductID
        
        -- Check stock
        IF @CurrentStock < @Quantity
        BEGIN
            CLOSE order_cursor
            DEALLOCATE order_cursor
            RAISERROR('Insufficient stock for ProductID %d. Order not placed.', 16, 1, @ProductID)
            RETURN
        END
        
        FETCH NEXT FROM order_cursor INTO @ProductID, @Quantity
    END
    
    CLOSE order_cursor
    DEALLOCATE order_cursor
    
    -- If all checks passed, insert the records and update inventory
    BEGIN TRY
        BEGIN TRANSACTION
        
        -- Insert the order details
        INSERT INTO Sales.SalesOrderDetail (
            SalesOrderID, ProductID, OrderQty, UnitPrice, UnitPriceDiscount
        )
        SELECT 
            SalesOrderID, ProductID, OrderQty, UnitPrice, UnitPriceDiscount
        FROM inserted
        
        -- Update inventory for each product
        UPDATE pi
        SET pi.Quantity = pi.Quantity - i.OrderQty
        FROM Production.ProductInventory pi
        JOIN inserted i ON pi.ProductID = i.ProductID
        
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        RAISERROR('Error processing order: %s', 16, 1, @ErrorMessage)
    END CATCH
END
GO



/* 1. LIST OF ALL CUSTOMERS */
SELECT * FROM Sales.Customer;

-- 2. list of all customers where company name ending in N
SELECT * FROM Sales.Store
WHERE Name LIKE '%N';



-- 3. list of customers who live in berlin or london 
SELECT DISTINCT
    C.CustomerID,
    P.FirstName,
    P.LastName,
    A.City
FROM
    Sales.Customer AS C
JOIN
    Person.Person AS P ON C.PersonID = P.BusinessEntityID
JOIN
    Person.BusinessEntityAddress AS BEA ON P.BusinessEntityID = BEA.BusinessEntityID
JOIN
    Person.Address AS A ON BEA.AddressID = A.AddressID
WHERE
    A.City = 'Berlin' OR A.City = 'London';



/* 4.list of all customer who have territory id 9 or 7 */
SELECT * FROM Sales.Customer WHERE TerritoryID IN (9, 7);

/* 5. List all products sorted by product name: */
SELECT * FROM [Production].[ProductModel] ORDER BY Name;

/* 6. List all products where product name starts with an A: */
SELECT * FROM [Production].[ProductModel] WHERE Name LIKE 'A%';
 
--7. List of customers who never placed an order:
SELECT * FROM Sales.Customer
WHERE CustomerID NOT IN (SELECT CustomerID FROM Sales.SalesOrderHeader);

--8.  List of Customers who ever placed an order in London and have bought chai
SELECT DISTINCT
    C.CustomerID,
    P.FirstName,
    P.LastName
FROM
    Sales.SalesOrderHeader AS SOH
JOIN
    Sales.SalesOrderDetail AS SOD ON SOH.SalesOrderID = SOD.SalesOrderID
JOIN
    Production.Product AS Prod ON SOD.ProductID = Prod.ProductID
JOIN
    Sales.Customer AS C ON SOH.CustomerID = C.CustomerID
JOIN
    Person.Person AS P ON C.PersonID = P.BusinessEntityID -- Get customer's name
JOIN
    Person.Address AS A ON SOH.BillToAddressID = A.AddressID -- Assuming BillToAddressID or ShipToAddressID points to the order's city
WHERE
    A.City = 'London'
    AND Prod.Name = 'Chai'; -- Assuming the product name is 'Chai'



--9.LIST OF CUSTOMER WHO NEVER PLACED AN ORDER
SELECT * FROM Sales.Customer
WHERE CustomerID NOT IN (SELECT CustomerID FROM Sales.SalesOrderHeader);

--10.list of customer who ordered tofu
SELECT DISTINCT Sales.Customer.*
FROM Sales.Customer
JOIN Sales.SalesOrderHeader ON Sales.Customer.CustomerID = Sales.SalesOrderHeader.CustomerID
JOIN Sales.SalesOrderDetail ON Sales.SalesOrderHeader.SalesOrderID = Sales.SalesOrderDetail.SalesOrderID
JOIN Production.Product ON Sales.SalesOrderDetail.ProductID = Production.Product.ProductID
WHERE Production.Product.Name = 'Tofu';

--11. detail of first order of system
SELECT TOP 1 * FROM Sales.SalesOrderHeader
ORDER BY OrderDate ASC;
 
 --12. Find the details of the most expensive order date:
 SELECT TOP 1 SalesOrderID, ModifiedDate, MAX(UnitPrice * OrderQty) AS TotalAmount
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID, ModifiedDate
ORDER BY TotalAmount DESC;

--13.For each order, get the OrderID and average quantity of items in that order:
SELECT SalesOrderID, AVG(OrderQty) AS AverageQuantity
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID;

--14.For each order, get the OrderID, minimum quantity, and maximum quantity:
SELECT SalesOrderID, MIN(OrderQty) AS MinQuantity, MAX(OrderQty) AS MaxQuantity
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID;

--15.Get a list of all managers and total number of employees who report to them:
SELECT
    P.FirstName AS ManagerFirstName,
    P.LastName AS ManagerLastName,
    COUNT(E.BusinessEntityID) AS NumberOfEmployeesReporting
FROM
    HumanResources.Employee AS E
JOIN
    HumanResources.Employee AS M ON E.OrganizationNode.GetAncestor(1) = M.OrganizationNode -- Links employee to their direct manager
JOIN
    Person.Person AS P ON M.BusinessEntityID = P.BusinessEntityID -- Gets the manager's name
GROUP BY
    P.FirstName,
    P.LastName
ORDER BY
    NumberOfEmployeesReporting DESC;


--16.  Get the OrderID and the total quantity for each order that has a total quantity greater than 300:
SELECT SOD.SalesOrderID, SUM(SOD.OrderQty) AS TotalQuantity
FROM Sales.SalesOrderDetail AS SOD
GROUP BY SOD.SalesOrderID
HAVING SUM(SOD.OrderQty) > 300;

--17. List of all orders placed on or after 1996-12-31:
SELECT *
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '1996-12-31';

--18.List of all orders shipped to Canada:
SELECT SOH.*
FROM Sales.SalesOrderHeader AS SOH
JOIN Person.Address AS A ON SOH.ShipToAddressID = A.AddressID
WHERE A.StateProvinceID IN (SELECT StateProvinceID FROM Person.StateProvince WHERE CountryRegionCode = 'CA');

--19. List of all orders with order total > 200:
SELECT *
FROM Sales.SalesOrderHeader
WHERE TotalDue > 200;

--20.List of countries and sales made in each country:
SELECT CR.Name AS CountryName, SUM(SOH.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader AS SOH
JOIN Person.Address AS A ON SOH.ShipToAddressID = A.AddressID
JOIN Person.StateProvince AS SP ON A.StateProvinceID = SP.StateProvinceID
JOIN Person.CountryRegion AS CR ON SP.CountryRegionCode = CR.CountryRegionCode
GROUP BY CR.Name;

--21.List of Customer ContactName and number of orders they placed:
SELECT C.CustomerID, COUNT(SOH.SalesOrderID) AS TotalOrders
FROM Sales.Customer AS C
JOIN Sales.SalesOrderHeader AS SOH ON C.CustomerID = SOH.CustomerID
GROUP BY C.CustomerID;

--22. List of customer contact names who have placed more than 3 orders:
SELECT C.CustomerID, COUNT(SOH.SalesOrderID) AS TotalOrders
FROM Sales.Customer AS C
JOIN Sales.SalesOrderHeader AS SOH ON C.CustomerID = SOH.CustomerID
GROUP BY C.CustomerID
HAVING COUNT(SOH.SalesOrderID) > 3;

--23.List of discontinued products ordered between 1/1/1997 and 1/1/1998:
SELECT P.Name AS ProductName, SOD.SalesOrderID
FROM Production.Product AS P
JOIN Sales.SalesOrderDetail AS SOD ON P.ProductID = SOD.ProductID
WHERE P.DiscontinuedDate IS NOT NULL
AND SOD.ModifiedDate BETWEEN '1997-01-01' AND '1998-01-01';

--24. List of employee FirstName, LastName, Supervisor FirstName, LastName:
SELECT
    P.FirstName AS EmployeeFirstName,
    P.LastName AS EmployeeLastName,
    SP.FirstName AS SupervisorFirstName,
    SP.LastName AS SupervisorLastName
FROM
    HumanResources.Employee AS E
JOIN
    Person.Person AS P ON E.BusinessEntityID = P.BusinessEntityID -- Get employee's name
LEFT JOIN
    HumanResources.Employee AS S ON E.OrganizationNode.GetAncestor(1) = S.OrganizationNode -- Link employee to their direct supervisor
LEFT JOIN
    Person.Person AS SP ON S.BusinessEntityID = SP.BusinessEntityID -- Get supervisor's name
ORDER BY
    EmployeeLastName, EmployeeFirstName;

--25.List of Employees ID and total sale conducted by employee:
SELECT SOH.SalesPersonID, SUM(SOH.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader AS SOH
GROUP BY SOH.SalesPersonID;

--26.List of employees whose FirstName contains the character 'a':
SELECT
    P.BusinessEntityID AS EmployeeID,
    P.FirstName,
    P.LastName
FROM
    Person.Person AS P
JOIN
    HumanResources.Employee AS E ON P.BusinessEntityID = E.BusinessEntityID -- Ensure we only select actual employees
WHERE
    P.FirstName LIKE '%a%';


--27.List of managers who have more than four people reporting to them:
SELECT
    M.BusinessEntityID AS ManagerID,
    P.FirstName AS ManagerFirstName,
    P.LastName AS ManagerLastName,
    COUNT(E.BusinessEntityID) AS NumberOfReports
FROM
    HumanResources.Employee AS E
JOIN
    HumanResources.Employee AS M ON E.OrganizationNode.GetAncestor(1) = M.OrganizationNode -- This identifies the direct manager
JOIN
    Person.Person AS P ON M.BusinessEntityID = P.BusinessEntityID -- Get manager's name
GROUP BY
    M.BusinessEntityID, P.FirstName, P.LastName
HAVING
    COUNT(E.BusinessEntityID) > 4;


--28.List of Orders and Product Names:
SELECT SOD.SalesOrderID, P.Name AS ProductName
FROM Sales.SalesOrderDetail AS SOD
JOIN Production.Product AS P ON SOD.ProductID = P.ProductID;

--29.  List of orders placed by the best customer:
SELECT TOP 1 SOH.CustomerID, COUNT(SOH.SalesOrderID) AS TotalOrders
FROM Sales.SalesOrderHeader AS SOH
GROUP BY SOH.CustomerID
ORDER BY TotalOrders DESC;

--30.List of orders placed by customers who do not have a Fax number:
SELECT
    SOH.SalesOrderID,
    SOH.OrderDate,
    C.CustomerID
FROM
    Sales.SalesOrderHeader AS SOH
JOIN
    Sales.Customer AS C ON SOH.CustomerID = C.CustomerID
JOIN
    Person.Person AS P ON C.PersonID = P.BusinessEntityID 
LEFT JOIN
    Person.PersonPhone AS PP ON P.BusinessEntityID = PP.BusinessEntityID 
WHERE
    PP.PhoneNumber IS NULL;


--31.List of Postal codes where the product Tofu was shipped:
SELECT DISTINCT A.PostalCode
FROM Sales.SalesOrderDetail AS SOD
JOIN Production.Product AS P ON SOD.ProductID = P.ProductID
JOIN Sales.SalesOrderHeader AS SOH ON SOD.SalesOrderID = SOH.SalesOrderID
JOIN Person.Address AS A ON SOH.ShipToAddressID = A.AddressID
WHERE P.Name = 'Tofu';

--32. List of Product Names that were shipped to France:
SELECT DISTINCT P.Name AS ProductName
FROM Sales.SalesOrderDetail AS SOD
JOIN Production.Product AS P ON SOD.ProductID = P.ProductID
JOIN Sales.SalesOrderHeader AS SOH ON SOD.SalesOrderID = SOH.SalesOrderID
JOIN Person.Address AS A ON SOH.ShipToAddressID = A.AddressID
JOIN Person.StateProvince AS SP ON A.StateProvinceID = SP.StateProvinceID
JOIN Person.CountryRegion AS CR ON SP.CountryRegionCode = CR.CountryRegionCode
WHERE CR.Name = 'France';


--33.List of ProductNames and Categories for the supplier 'Specialty Biscuits, Ltd.'
SELECT
    P.Name AS ProductName,
    PC.Name AS CategoryName
FROM
    Purchasing.Vendor AS V
JOIN
    Purchasing.PurchaseOrderHeader AS POH ON V.BusinessEntityID = POH.VendorID
JOIN
    Purchasing.PurchaseOrderDetail AS POD ON POH.PurchaseOrderID = POD.PurchaseOrderID
JOIN
    Production.Product AS P ON POD.ProductID = P.ProductID
JOIN
    Production.ProductSubcategory AS PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
JOIN
    Production.ProductCategory AS PC ON PS.ProductCategoryID = PC.ProductCategoryID
WHERE
    V.Name = 'Specialty Biscuits, Ltd.';


--34.List of products that were never ordered
SELECT
    P.Name AS ProductName
FROM
    Production.Product AS P
LEFT JOIN
    Sales.SalesOrderDetail AS SOD ON P.ProductID = SOD.ProductID
WHERE
    SOD.ProductID IS NULL;


--35. List of products where units in stock is less than 10 and units on order are 0
SELECT
    P.Name AS ProductName
FROM
    Production.Product AS P
JOIN
    Production.ProductInventory AS PI ON P.ProductID = PI.ProductID
WHERE
    PI.Quantity < 10;



--36.List of top 10 countries by sales
SELECT TOP 10
    ST.CountryRegionCode,
    SUM(SOH.TotalDue) AS TotalSales
FROM
    Sales.SalesOrderHeader AS SOH
JOIN
    Sales.SalesTerritory AS ST ON SOH.TerritoryID = ST.TerritoryID
GROUP BY
    ST.CountryRegionCode
ORDER BY
    TotalSales DESC;

--37.Number of orders each employee has taken for customers with CustomerIDs between A and AO


--38.Orderdate of most expensive order
SELECT TOP 1
    OrderDate
FROM
    Sales.SalesOrderHeader
ORDER BY
    TotalDue DESC;

--39.Product name and total revenue from that product
SELECT
    P.Name AS ProductName,
    SUM(SOD.OrderQty * SOD.UnitPrice) AS TotalRevenue
FROM
    Production.Product AS P
JOIN
    Sales.SalesOrderDetail AS SOD ON P.ProductID = SOD.ProductID
GROUP BY
    P.Name
ORDER BY
    TotalRevenue DESC;

--40.SupplierId and number of products offered
SELECT
    V.BusinessEntityID AS SupplierID,
    COUNT(DISTINCT POD.ProductID) AS NumberOfProductsOffered
FROM
    Purchasing.Vendor AS V
JOIN
    Purchasing.PurchaseOrderHeader AS POH ON V.BusinessEntityID = POH.VendorID
JOIN
    Purchasing.PurchaseOrderDetail AS POD ON POH.PurchaseOrderID = POD.PurchaseOrderID
GROUP BY
    V.BusinessEntityID
ORDER BY
    NumberOfProductsOffered DESC;

--41.Top ten customers based on their business
SELECT TOP 10
    C.CustomerID,
    P.FirstName,
    P.LastName,
    SUM(SOH.TotalDue) AS TotalBusiness
FROM
    Sales.Customer AS C
JOIN
    Person.Person AS P ON C.PersonID = P.BusinessEntityID -- Assuming PersonID in Customer links to BusinessEntityID in Person
JOIN
    Sales.SalesOrderHeader AS SOH ON C.CustomerID = SOH.CustomerID
GROUP BY
    C.CustomerID, P.FirstName, P.LastName
ORDER BY
    TotalBusiness DESC;
    
--42.what is the total revnue of company
SELECT
    SUM(TotalDue) AS TotalCompanyRevenue
FROM
    Sales.SalesOrderHeader;



































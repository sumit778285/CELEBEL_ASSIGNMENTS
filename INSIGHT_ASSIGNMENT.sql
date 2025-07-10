CREATE TABLE dim_product (
    Stock_Item_Id INT PRIMARY KEY,
    Stock_Item_Name VARCHAR(255),
    Stock_ItemColor VARCHAR(100),
    Stock_Item_Size VARCHAR(100),
    Item_Size VARCHAR(100),
    Stock_ItemPrice DECIMAL(10, 2),
    Description VARCHAR(500)
);

CREATE TABLE dim_customer (
    Customer_Id INT PRIMARY KEY,
    CustomerName VARCHAR(255),
    CustomerCategory VARCHAR(100),
    CustomerContactName VARCHAR(255),
    CustomerPostalCode VARCHAR(50),
    CustomerContactNumber VARCHAR(50)
);

CREATE TABLE dim_employee (
    employee_Id INT PRIMARY KEY,
    EmployeeFirstName VARCHAR(100),
    EmployeeLastName VARCHAR(100),
    Is_Salesperson BOOLEAN
);

CREATE TABLE dim_geography (
    City_ID INT PRIMARY KEY,
    City VARCHAR(100),
    State_Province VARCHAR(100),
    Country VARCHAR(100),
    Continent VARCHAR(100),
    Region VARCHAR(100),
    Subregion VARCHAR(100),
    Sales_Territory VARCHAR(100),
    Latest_Recorded_Population BIGINT
);

CREATE TABLE fact_sales (
    InvoiceId INT,
    Stock_Item_Id INT,
    Customer_Id INT,
    employee_Id INT,
    City_ID INT,
    Quantity INT,
    Unit_Price DECIMAL(10, 2),
    Tax_Rate DECIMAL(5, 2),
    Tax_Amount DECIMAL(10, 2),
    Profit DECIMAL(10, 2),
    Total_Excluding_Tax DECIMAL(10, 2),
    Total_Including_Tax DECIMAL(10, 2),
    PRIMARY KEY (InvoiceId, Stock_Item_Id),
    FOREIGN KEY (Stock_Item_Id) REFERENCES dim_product(Stock_Item_Id),
    FOREIGN KEY (Customer_Id) REFERENCES dim_customer(Customer_Id),
    FOREIGN KEY (employee_Id) REFERENCES dim_employee(employee_Id),
    FOREIGN KEY (City_ID) REFERENCES dim_geography(City_ID)
);

INSERT INTO dim_product
SELECT DISTINCT
    Stock_Item_Id,
    Stock_Item_Name,
    Stock_ItemColor,
    Stock_Item_Size,
    Item_Size,
    Stock_ItemPrice,
    Description
FROM Insignia_staging;

INSERT INTO dim_customer
SELECT DISTINCT
    Customer_Id,
    CustomerName,
    CustomerCategory,
    CustomerContactName,
    CustomerPostalCode,
    CustomerContactNumber
FROM Insignia_staging;

INSERT INTO dim_employee
SELECT DISTINCT
    employee_Id,
    EmployeeFirstName,
    EmployeeLastName,
    Is_Salesperson
FROM Insignia_staging;


INSERT INTO dim_geography
SELECT DISTINCT
    City_ID,
    City,
    State_Province,
    Country,
    Continent,
    Region,
    Subregion,
    Sales_Territory,
    Latest_Recorded_Population
FROM Insignia_staging;

INSERT INTO fact_sales
SELECT
    InvoiceId,
    Stock_Item_Id,
    Customer_Id,
    employee_Id,
    City_ID,
    Quantity,
    Unit_Price,
    Tax_Rate,
    Tax_Amount,
    Profit,
    Total_Excluding_Tax,
    Total_Including_Tax
FROM Insignia_staging;

    
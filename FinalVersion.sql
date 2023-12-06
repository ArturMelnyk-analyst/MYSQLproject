## Creating TABLE Products
CREATE TABLE Products (
  ProductKey INT PRIMARY KEY,
  Product VARCHAR(255),
  StandardCost DECIMAL(10,2),
  Color VARCHAR(50),
  Subcategory VARCHAR(50),
  Category VARCHAR(50),
  BackgroundColorFormat CHAR(7),
  FontColorFormat CHAR(7)
);

## Creating TABLE Employees
CREATE TABLE Employees (
  EmployeeKey INT PRIMARY KEY,
  EmployeeID INT UNIQUE,
  Salesperson VARCHAR(255),
  Title VARCHAR(255),
  UPN VARCHAR(255)
);

## Creating TABLE Regions
CREATE TABLE Regions (
  SalesTerritoryKey INT PRIMARY KEY,
  Region VARCHAR(50),
  Country VARCHAR(50),
  `Group` VARCHAR(50)
);

## Creating TABLE Targets
CREATE TABLE Targets (
  EmployeeID INT,
  Target DECIMAL(10,2),
  TargetMonth DATE,
  FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);

## Creating TABLE SalesPersonRegion
CREATE TABLE SalesPersonRegion (
  EmployeeKey INT,
  SalesTerritoryKey INT,
  FOREIGN KEY (EmployeeKey) REFERENCES Employees(EmployeeKey),
  FOREIGN KEY (SalesTerritoryKey) REFERENCES Regions(SalesTerritoryKey)
);

## Creating TABLE Resellers
CREATE TABLE Resellers (
  ResellerKey INT PRIMARY KEY,
  BusinessType VARCHAR(50),
  Reseller VARCHAR(255),
  City VARCHAR(50),
  StateProvince VARCHAR(50),
  CountryRegion VARCHAR(50)
);

## Creating TABLE Sales
CREATE TABLE Sales (
  SalesOrderNumber VARCHAR(50),
  OrderDate DATE,
  ProductKey INT,
  ResellerKey INT,
  EmployeeKey INT,
  SalesTerritoryKey INT,
  Quantity INT,
  UnitPrice DECIMAL(10,2),
  Sales DECIMAL(10,2),
  Cost DECIMAL(10,2),
  FOREIGN KEY (ProductKey) REFERENCES Products(ProductKey),
  FOREIGN KEY (ResellerKey) REFERENCES Resellers(ResellerKey),
  FOREIGN KEY (EmployeeKey) REFERENCES Employees(EmployeeKey),
  FOREIGN KEY (SalesTerritoryKey) REFERENCES Regions(SalesTerritoryKey)
);

## Loading data from csv file products on my computer to mysql TABLE products
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv' 
INTO TABLE products 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS 
(ProductKey, Product, @StandardCost, Color, Subcategory, Category, @BackgroundColorFormat, @FontColorFormat)
SET StandardCost = REPLACE(REPLACE(@StandardCost, '$', ''), ',', ''),
    BackgroundColorFormat = NULLIF(@BackgroundColorFormat,''),
    FontColorFormat = NULLIF(@FontColorFormat,'');

## Loading data from csv file employees on my computer to mysql TABLE employees
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/employees.csv' 
INTO TABLE Employees 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS 
(EmployeeKey, EmployeeID, Salesperson, Title, UPN);

## Loading data from csv file regions on my computer to mysql TABLE regions
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/regions.csv' 
INTO TABLE Regions 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS 
(SalesTerritoryKey, Region, Country, `Group`);

## Loading data from csv file targets on my computer to mysql TABLE targets
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/targets.csv'
INTO TABLE Targets
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(EmployeeID, @TargetValue, @TargetMonth)
SET Target = REPLACE(REPLACE(@TargetValue, '$', ''), ',', ''),
    TargetMonth = STR_TO_DATE(@TargetMonth, '%W, %M %d, %Y');

## Loading data from csv file sales_person_region on my computer to mysql TABLE salespersonregion
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sales_person_region.csv' 
INTO TABLE SalesPersonRegion 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS 
(EmployeeKey, SalesTerritoryKey);

## Loading data from csv file resellers on my computer to mysql TABLE resellers
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/resellers.csv' 
INTO TABLE Resellers 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS 
(ResellerKey, BusinessType, Reseller, City, StateProvince, CountryRegion);

## Loading data from csv file sales on my computer to mysql TABLE sales
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sales.csv' 
INTO TABLE Sales 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS 
(SalesOrderNumber, @OrderDate, ProductKey, ResellerKey, EmployeeKey, SalesTerritoryKey, Quantity, @UnitPrice, @Sales, @Cost)
SET OrderDate = STR_TO_DATE(@OrderDate, '%W, %M %d, %Y'),
    UnitPrice = REPLACE(REPLACE(@UnitPrice, '$', ''), ',', ''),
    Sales = REPLACE(REPLACE(@Sales, '$', ''), ',', ''),
    Cost = REPLACE(REPLACE(@Cost, '$', ''), ',', '');

## Top 3 selling products in each Region
SELECT 
    main.Region, 
    main.Product, 
    main.TotalSales
FROM 
    (SELECT 
        R.Region, 
        P.Product, 
        SUM(S.Sales) AS TotalSales,
        RANK() OVER (PARTITION BY R.Region ORDER BY SUM(S.Sales) DESC) as SalesRank
     FROM 
        Sales S
     JOIN 
        Products P ON S.ProductKey = P.ProductKey
     JOIN 
        Regions R ON S.SalesTerritoryKey = R.SalesTerritoryKey
     GROUP BY 
        R.Region, P.Product
    ) AS main
WHERE 
    main.SalesRank <= 3;

## Analyzing sales performance
SELECT 
    E.EmployeeKey,
    E.Salesperson,
    SUM(CASE WHEN S.Sales < 500 THEN 1 ELSE 0 END) AS Sales_LessThan_500,
    SUM(CASE WHEN S.Sales BETWEEN 500 AND 1000 THEN 1 ELSE 0 END) AS Sales_500_To_1000,
    SUM(CASE WHEN S.Sales > 1000 THEN 1 ELSE 0 END) AS Sales_MoreThan_1000
FROM 
    Sales S
JOIN 
    Employees E ON S.EmployeeKey = E.EmployeeKey
GROUP BY 
    E.EmployeeKey, E.Salesperson;
 
 ##Identifying to which reseller salespeople are related and in which country resellers are operating
    SELECT 
    E.EmployeeKey,
    E.EmployeeID,
    E.Salesperson,
    R.ResellerKey,
    R.Reseller,
    REG.Region
FROM 
    Sales S
JOIN 
    Employees E ON S.EmployeeKey = E.EmployeeKey
JOIN 
    Resellers R ON S.ResellerKey = R.ResellerKey
JOIN 
    SalesPersonRegion SPR ON S.EmployeeKey = SPR.EmployeeKey
JOIN 
    Regions REG ON SPR.SalesTerritoryKey = REG.SalesTerritoryKey
GROUP BY 
    E.EmployeeKey, E.EmployeeID, E.Salesperson, R.ResellerKey, R.Reseller, REG.Region;
    
##Identifying Total Number of Resellers
SELECT 
    COUNT(*) AS NumberOfResellers
FROM 
    Resellers;


##Identifying top 3 resellers in each region
SELECT 
    RankedResellers.Region,
    RankedResellers.Reseller,
    RankedResellers.TotalSales
FROM (
    SELECT 
        REG.Region,
        R.Reseller,
        SUM(S.Sales) AS TotalSales,
        RANK() OVER (PARTITION BY REG.Region ORDER BY SUM(S.Sales) DESC) AS ResellerRank
    FROM 
        Sales S
    JOIN 
        Resellers R ON S.ResellerKey = R.ResellerKey
    JOIN 
        Regions REG ON S.SalesTerritoryKey = REG.SalesTerritoryKey
    GROUP BY 
        REG.Region, R.Reseller
) AS RankedResellers
WHERE 
    RankedResellers.ResellerRank <= 3;

  
## Comparing total sales per employee in region to total sales in a region performed
SELECT 
    E.Salesperson,
    E.EmployeeKey,
    R.Region,
    employeeRegionalSales.TotalSalesForEmployee,
    regionSales.TotalSalesInRegion,
    (employeeRegionalSales.TotalSalesForEmployee / regionSales.TotalSalesInRegion) * 100 AS SalesPercentageInRegion
FROM 
    Employees E
JOIN 
    SalesPersonRegion SPR ON E.EmployeeKey = SPR.EmployeeKey
JOIN 
    Regions R ON SPR.SalesTerritoryKey = R.SalesTerritoryKey
INNER JOIN 
    (SELECT 
        S.EmployeeKey, 
        S.SalesTerritoryKey,
        SUM(S.Sales) AS TotalSalesForEmployee 
     FROM 
        Sales S
     GROUP BY 
        S.EmployeeKey, S.SalesTerritoryKey
    ) AS employeeRegionalSales ON E.EmployeeKey = employeeRegionalSales.EmployeeKey AND SPR.SalesTerritoryKey = employeeRegionalSales.SalesTerritoryKey
LEFT JOIN 
    (SELECT 
        SPR.SalesTerritoryKey, 
        SUM(S.Sales) AS TotalSalesInRegion 
     FROM 
        Sales S
     JOIN 
        SalesPersonRegion SPR ON S.SalesTerritoryKey = SPR.SalesTerritoryKey
     GROUP BY 
        SPR.SalesTerritoryKey
    ) AS regionSales ON SPR.SalesTerritoryKey = regionSales.SalesTerritoryKey;




    
## Creating SalesSummary table for creating storing procedure
CREATE TABLE SalesSummary (
    ProductKey INT,
    TotalSales DECIMAL(10,2),
    TotalUnitsSold INT,
    PRIMARY KEY (ProductKey),
    FOREIGN KEY (ProductKey) REFERENCES Products(ProductKey)
);

## Creating Storing Procedure to insert sales records and update summary
DELIMITER //

CREATE PROCEDURE InsertSaleAndUpdateSummary(
    IN _SalesOrderNumber VARCHAR(50),
    IN _OrderDate DATE,
    IN _ProductKey INT,
    IN _ResellerKey INT,
    IN _EmployeeKey INT,
    IN _SalesTerritoryKey INT,
    IN _Quantity INT,
    IN _UnitPrice DECIMAL(10,2),
    IN _Sales DECIMAL(10,2),
    IN _Cost DECIMAL(10,2)
)
BEGIN
    -- Inserting the new sale record
    INSERT INTO Sales (SalesOrderNumber, OrderDate, ProductKey, ResellerKey, EmployeeKey, SalesTerritoryKey, Quantity, UnitPrice, Sales, Cost) 
    VALUES (_SalesOrderNumber, _OrderDate, _ProductKey, _ResellerKey, _EmployeeKey, _SalesTerritoryKey, _Quantity, _UnitPrice, _Sales, _Cost);

    -- Updating the Sales Summary
    -- Check if the product already has an entry in the summary table
    IF EXISTS (SELECT * FROM SalesSummary WHERE ProductKey = _ProductKey) THEN
        -- Update existing summary
        UPDATE SalesSummary 
        SET TotalSales = TotalSales + _Sales, 
            TotalUnitsSold = TotalUnitsSold + _Quantity
        WHERE ProductKey = _ProductKey;
    ELSE
        -- Insert new summary record
        INSERT INTO SalesSummary (ProductKey, TotalSales, TotalUnitsSold) 
        VALUES (_ProductKey, _Sales, _Quantity);
    END IF;
END //

DELIMITER ;

## Creating table SalesAuditLog for creatin trigger which will indicate 2 sales of 5000 or more
CREATE TABLE SalesAuditLog (
    LogID INT AUTO_INCREMENT PRIMARY KEY,
    SalesOrderNumber VARCHAR(50),
    Quantity INT,
    UnitPrice DECIMAL(10,2),
    DetectedAt DATETIME,
    Reason VARCHAR(255)
);

DELIMITER //

## Creating Trigger for quanity of sales >=2 and price>=5000 if this happens than this info will be added in TABLE salesauditlog
CREATE TRIGGER LogUnrealisticSales
BEFORE INSERT ON Sales
FOR EACH ROW
BEGIN
    -- Check for unrealistic sales values
    IF NEW.Quantity >= 2 AND NEW.UnitPrice > 5000 THEN
        -- Insert a log record for review
        INSERT INTO SalesAuditLog (SalesOrderNumber, Quantity, UnitPrice, DetectedAt, Reason)
        VALUES (NEW.SalesOrderNumber, NEW.Quantity, NEW.UnitPrice, NOW(), 'Unrealistic sale value detected');
    END IF;
END //

DELIMITER ;

## Before creating indexes showing table performance
EXPLAIN SELECT * FROM Sales
JOIN Employees ON Sales.EmployeeKey = Employees.EmployeeKey
WHERE OrderDate = '2017-08-25';

## EXPLAIN Update Summary:
## Employees Table: Full scan (type: ALL), acceptable due to small size (18 rows), no index needed.
## Sales Table: Using composite index idx_employeekey_orderdate (type: ref), significantly reduced row scan to 20, enhancing efficiency.
## Outcome: Composite index effectively optimizes join and WHERE clause, improving query speed, especially beneficial as data volume increases.


## Adding index to table employees
ALTER TABLE Employees ADD INDEX idx_title (Title);

## Analyzing results after adding index
EXPLAIN SELECT Employees.*, Sales.*
FROM Employees
JOIN Sales ON Employees.EmployeeKey = Sales.EmployeeKey
WHERE Employees.Title = 'Sales Representative'
AND Sales.OrderDate = '2017-08-25';

## EXPLAIN Analysis: 
## 1. Employees Table: Full table scan (type: ALL), no index used, scans 18 rows. Suggest indexing columns used in frequent queries.
## 2. Sales Table: Efficient join (type: ref) using EmployeeKey index, 1 row per join. Index on Sales.EmployeeKey is effective.
## Recommendation: Index Sales.EmployeeKey for joins; consider indexing Employees columns like EmployeeID or Title for query efficiency.


## Adding INDEX to TABLE Sales
ALTER TABLE Sales ADD INDEX idx_employeekey (EmployeeKey);

## To analyze results of adding INDEX to TABLE Sales run EXPLAIN statement
EXPLAIN SELECT *
FROM Sales
INNER JOIN Employees ON Sales.EmployeeKey = Employees.EmployeeKey
WHERE Sales.OrderDate = '2017-08-25';

## EXPLAIN Analysis Post-Indexing:
## 1. Sales Table: Full table scan (type: ALL) with index idx_employeekey not utilized. Consider index selectivity and WHERE clause usage.
## 2. Employees Table: Efficient join (type: eq_ref) using PRIMARY key, 1 row per join indicates good index use.
## Recommendation: Assess full table scan on Sales; explore composite index on EmployeeKey and OrderDate, considering column selectivity and query patterns.

## Adding INDEX to Sales Table
ALTER TABLE Sales ADD INDEX idx_employeekey_orderdate (EmployeeKey, OrderDate);

## To analyze result of adding INDEX to TABLE Sales run explain statement
EXPLAIN SELECT Sales.*, Employees.*
FROM Sales
JOIN Employees ON Sales.EmployeeKey = Employees.EmployeeKey
WHERE Sales.OrderDate = '2017-08-25';

## EXPLAIN Output Analysis:
## 1. Employees Table: Full table scan (type: ALL) due to small size (18 rows), index use not beneficial.
## 2. Sales Table: Efficient lookup using composite index idx_employeekey_orderdate (type: ref), reduced row scan to 20 from 57,684.
## Observation: Composite index on EmployeeKey and OrderDate improves efficiency, particularly in join operations and WHERE clause filtering.

## Creating a view to simplify complex query
CREATE VIEW SalesSummaryView AS
SELECT 
    P.Product,
    SUM(S.Quantity) AS TotalQuantity,
    SUM(S.Sales) AS TotalSales
FROM 
    Sales S
JOIN 
    Products P ON S.ProductKey = P.ProductKey
GROUP BY 
    P.Product;

-- Querying the view
SELECT * FROM SalesSummaryView WHERE TotalSales > 10000;

## Calculating Year-over-Year sales growth for each product
SELECT 
    YEAR(OrderDate) AS Year,
    P.Product,
    SUM(S.Sales) AS TotalSales,
    LAG(SUM(S.Sales)) OVER (PARTITION BY P.Product ORDER BY YEAR(OrderDate)) AS PreviousYearSales,
    ((SUM(S.Sales) - LAG(SUM(S.Sales)) OVER (PARTITION BY P.Product ORDER BY YEAR(OrderDate))) / LAG(SUM(S.Sales)) OVER (PARTITION BY P.Product ORDER BY YEAR(OrderDate))) * 100 AS YoYGrowth
FROM 
    Sales S
JOIN 
    Products P ON S.ProductKey = P.ProductKey
GROUP BY 
    YEAR(OrderDate), P.Product
ORDER BY 
    P.Product, YEAR(OrderDate);
    
## Calculating year-over-year  growth for each region
    SELECT 
    YEAR(OrderDate) AS Year,
    R.Region,
    SUM(S.Sales) AS TotalSales,
    LAG(SUM(S.Sales)) OVER (PARTITION BY R.Region ORDER BY YEAR(OrderDate)) AS PreviousYearSales,
    ((SUM(S.Sales) - LAG(SUM(S.Sales)) OVER (PARTITION BY R.Region ORDER BY YEAR(OrderDate))) / LAG(SUM(S.Sales)) OVER (PARTITION BY R.Region ORDER BY YEAR(OrderDate))) * 100 AS YoYGrowth
FROM 
    Sales S
JOIN 
    Regions R ON S.SalesTerritoryKey = R.SalesTerritoryKey
GROUP BY 
    YEAR(OrderDate), R.Region
ORDER BY 
    R.Region, YEAR(OrderDate);
    
## Calculating year-over-year growth of all sales
    SELECT 
    YEAR(OrderDate) AS Year,
    SUM(S.Sales) AS TotalSales,
    LAG(SUM(S.Sales)) OVER (ORDER BY YEAR(OrderDate)) AS PreviousYearSales,
    ((SUM(S.Sales) - LAG(SUM(S.Sales)) OVER (ORDER BY YEAR(OrderDate))) / LAG(SUM(S.Sales)) OVER (ORDER BY YEAR(OrderDate))) * 100 AS YoYGrowth
FROM 
    Sales S
GROUP BY 
    YEAR(OrderDate)
ORDER BY 
    YEAR(OrderDate);

## Calculating year-over-year sales growth for each sales person
SELECT 
     YEAR(OrderDate) AS Year,
     E.Salesperson,
     E.EmployeeKey,
     SUM(S.Sales) AS TotalSales,
     LAG(SUM(S.Sales)) OVER (PARTITION BY E.EmployeeKey ORDER BY YEAR(OrderDate)) AS PreviousYearSales,
     ((SUM(S.Sales) - LAG(SUM(S.Sales)) OVER (PARTITION BY E.EmployeeKey ORDER BY YEAR(OrderDate))) / LAG(SUM(S.Sales)) OVER (PARTITION BY E.EmployeeKey ORDER BY YEAR(OrderDate))) * 100 AS YoYGrowth
FROM 
     Sales S
JOIN 
     Employees E ON S.EmployeeKey = E.EmployeeKey
GROUP BY 
     YEAR(OrderDate), E.Salesperson, E.EmployeeKey
ORDER BY 
     E.Salesperson, YEAR(OrderDate);

    
## Identifying if sales person met his/ her targets for a year
SELECT 
    YEAR(S.OrderDate) AS Year,
    E.EmployeeKey,
    E.Salesperson,
    REG.Region,
    SUM(S.Sales) AS TotalSales,
    T.Target,
    CASE 
        WHEN SUM(S.Sales) >= T.Target THEN 'Met'
        ELSE 'Not Met'
    END AS TargetMet
FROM 
    Sales S
JOIN 
    Employees E ON S.EmployeeKey = E.EmployeeKey
JOIN 
    Targets T ON E.EmployeeID = T.EmployeeID
JOIN 
    Regions REG ON S.SalesTerritoryKey = REG.SalesTerritoryKey
WHERE 
    YEAR(S.OrderDate) = YEAR(T.TargetMonth)
GROUP BY 
    YEAR(S.OrderDate), E.EmployeeKey, E.Salesperson, REG.Region, T.Target
ORDER BY 
    Year, E.EmployeeKey;
    
## Identifying Year where most salespeople didn't meet their target    
SELECT 
    Year,
    COUNT(*) AS NumberOfSalespeopleNotMeetingTarget
FROM (
    SELECT 
        YEAR(S.OrderDate) AS Year,
        E.EmployeeKey,
        SUM(S.Sales) AS TotalSales,
        T.Target,
        CASE 
            WHEN SUM(S.Sales) < T.Target THEN 1
            ELSE 0
        END AS NotMetTarget
    FROM 
        Sales S
    JOIN 
        Employees E ON S.EmployeeKey = E.EmployeeKey
    JOIN 
        Targets T ON E.EmployeeID = T.EmployeeID
    WHERE 
        YEAR(S.OrderDate) = YEAR(T.TargetMonth)
    GROUP BY 
        YEAR(S.OrderDate), E.EmployeeKey, T.Target
) AS YearlyTargets
WHERE 
    NotMetTarget = 1
GROUP BY 
    Year
ORDER BY 
    NumberOfSalespeopleNotMeetingTarget DESC
LIMIT 1;


## 1st Determine the total number of salespeople in each region for 2020. 
## 2nd Determine the total number of salespeople who didn't meet their targets in each region in 2020.
## 3rd Calculate the percentage based on these figures.
## 4th Select the top 3 regions based on the highest percentage in 2020   
SELECT 
    TotalSalespeoplePerRegion.Region,
    TotalSalespeoplePerRegion.TotalSalespeople,
    IFNULL(SalespeopleNotMeetingTargets.NumSalespeopleNotMet, 0) AS SalespeopleNotMeetingTargets,
    IFNULL((SalespeopleNotMeetingTargets.NumSalespeopleNotMet / TotalSalespeoplePerRegion.TotalSalespeople) * 100, 0) AS PercentageNotMeetingTargets
FROM (
    SELECT 
        REG.Region,
        COUNT(DISTINCT E.EmployeeKey) AS TotalSalespeople
    FROM 
        Employees E
    INNER JOIN 
        SalesPersonRegion SPR ON E.EmployeeKey = SPR.EmployeeKey
    INNER JOIN 
        Regions REG ON SPR.SalesTerritoryKey = REG.SalesTerritoryKey
    GROUP BY 
        REG.Region
) AS TotalSalespeoplePerRegion
LEFT JOIN (
    SELECT 
        REG.Region,
        COUNT(DISTINCT E.EmployeeKey) AS NumSalespeopleNotMet
    FROM 
        Employees E
    INNER JOIN 
        SalesPersonRegion SPR ON E.EmployeeKey = SPR.EmployeeKey
    INNER JOIN 
        Regions REG ON SPR.SalesTerritoryKey = REG.SalesTerritoryKey
    INNER JOIN 
        Targets T ON E.EmployeeID = T.EmployeeID AND YEAR(T.TargetMonth) = 2020
    LEFT JOIN (
        SELECT 
            S.EmployeeKey,
            SUM(S.Sales) AS TotalSales
        FROM 
            Sales S
        WHERE 
            YEAR(S.OrderDate) = 2020
        GROUP BY 
            S.EmployeeKey
    ) AS ST ON E.EmployeeKey = ST.EmployeeKey
    WHERE 
        COALESCE(ST.TotalSales, 0) < T.Target
    GROUP BY 
        REG.Region
) AS SalespeopleNotMeetingTargets ON TotalSalespeoplePerRegion.Region = SalespeopleNotMeetingTargets.Region
ORDER BY 
    PercentageNotMeetingTargets DESC
LIMIT 3;

### YOY Growth Analysis for Resellers
SELECT 
    YEAR(S.OrderDate) AS Year,
    R.ResellerKey,
    R.Reseller,
    REG.Region,
    S.EmployeeKey,
    SUM(S.Sales) AS TotalSales,
    LAG(SUM(S.Sales)) OVER (PARTITION BY R.ResellerKey, S.EmployeeKey ORDER BY YEAR(S.OrderDate)) AS PreviousYearSales,
    ((SUM(S.Sales) - LAG(SUM(S.Sales)) OVER (PARTITION BY R.ResellerKey, S.EmployeeKey ORDER BY YEAR(S.OrderDate))) / LAG(SUM(S.Sales)) OVER (PARTITION BY R.ResellerKey, S.EmployeeKey ORDER BY YEAR(S.OrderDate))) * 100 AS YoYGrowth
FROM 
    Sales S
JOIN 
    Resellers R ON S.ResellerKey = R.ResellerKey
JOIN 
    Regions REG ON S.SalesTerritoryKey = REG.SalesTerritoryKey
GROUP BY 
    YEAR(S.OrderDate), R.ResellerKey, R.Reseller, REG.Region, S.EmployeeKey
ORDER BY 
    R.ResellerKey, S.EmployeeKey, YEAR(S.OrderDate);
    








    
   










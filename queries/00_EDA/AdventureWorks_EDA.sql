-- EXPLORATORY DATA ANALYSIS
-- Dataset: AdventureWorks 2022

-- -------------------------------------------------------------------
-- 1. sales Date Range
-- -------------------------------------------------------------------
-- Findings: The Sales Data spans from May 31 2011 to June 30 2014.
-- Roughly 3 years and 1 of sales data.

SELECT
    MIN(OrderDate) AS MininumOrderDate,
    MAX(OrderDate) AS MaximumOrderDate,
    DATEDIFF(DAY, MIN(OrderDate), MAX(OrderDate)) AS TotalDays,
    DATEDIFF(YEAR, MIN(OrderDate), MAX(OrderDate)) AS TotalYears,
    DATEDIFF(MONTH, MIN(OrderDate), MAX(OrderDate)) % 12 AS RemainingMonths,
    DATEDIFF(DAY, MIN(OrderDate), MAX(OrderDate)) % 30 AS RemainingDays
FROM sales.SalesOrderHeader


-- -------------------------------------------------------------------
-- 2. total number of orders in the sales Date Range.
-- -------------------------------------------------------------------
-- Findings: There were 31,465 orders made from May 31 2011 to June 30 2014.

SELECT
    COUNT(SalesOrderID) AS TotalOrderCount
FROM sales.SalesOrderHeader


-- -------------------------------------------------------------------
-- 3. total online orders
-- -------------------------------------------------------------------
-- Findings: Out of 31,465 total orders, 27,659 orders were Online 

SELECT
    COUNT(SalesOrderID) AS TotalOnlineOrdesCount
FROM sales.SalesOrderHeader
WHERE OnlineOrderFlag = 1


-- -------------------------------------------------------------------
-- 4. total in-store orders
-- -------------------------------------------------------------------
-- Findings: Out of 31,465 total orders, 3806 orders were in-store orders

SELECT
    COUNT(SalesOrderID) AS TotalStoreOrdesCount
FROM sales.SalesOrderHeader
WHERE OnlineOrderFlag = 0


-- -----------------------------------------------------------------------------------
-- 5. total revenue, average order value, maximum order value and minimum order value 
-- -----------------------------------------------------------------------------------
-- Findings: The Total Revenue generated in 3 year span was about 123,216,786.12.
-- The Average Order Value was about 3,916.
-- The Maximun Order value was about 187,487.83 while Mininum Order Value being 1.52

SELECT
    ROUND(SUM(TotalDue), 2)  AS TotalRevenue,
    ROUND(AVG(TotalDue), 2)  AS AverageOrderValue,
    ROUND(MAX(TotalDue), 2) AS MaximumOrderValue,
    ROUND(MIN(TotalDue), 2) AS MinimumOrderValue
FROM sales.SalesOrderHeader


-- ---------------------------------------------------------------
-- 6. Yearly total revenue and order count
-- ---------------------------------------------------------------
-- Findings: In 2011 the Total Revenue Generated was about 14,155,699.53.
-- In 2012 the Total Revenue generated was about 37,675,700.31.
-- In 2013 the Total Revenue generated was about 48,965,887.96.
-- In 2014 the Total Revenue generated was about 22,419,498.32.
-- 2013 was the year with the Maximum revenue amount generated making it the best year with the most order
-- count and revenue generated.

SELECT
    YEAR(OrderDate) AS Year,
    COUNT(SalesOrderID) AS YearlyOrderCount,
    ROUND(SUM(TotalDue), 2) AS TotalYearlyRevenue,
    ROUND(AVG(TotalDue), 2) AS AverageYearlyOrderValue,
    ROUND(MAX(TotalDue), 2) AS MaxOrderValuePerYear,
    ROUND(MIN(TotalDue), 2) AS MinOrderValuePerYear
FROM sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY YEAR(OrderDate)


-- ---------------------------------------------------------------
-- 8. revenue by online and in-store
-- ---------------------------------------------------------------
-- Findings: in-store order count was about 3,806 while Online oorder count was about 27,659.
-- Though the Order Count was much higher with Online Orders the In-Store orders made more revenue.
-- In-store Total Revenue 90,775,446.99.
-- Online Total Revenue 32,441,339.12.

SELECT
    CASE
        WHEN OnlineOrderFlag = 1 THEN 'Online'
        ELSE 'In-store'
    END AS OrderType,
    COUNT(SalesOrderID) AS OrderCount,
    ROUND(SUM(TotalDue), 2) AS TotalRevenueByOrderType,
    ROUND(AVG(TotalDue), 2) AS AverageRevenueByOrderType
FROM sales.SalesOrderHeader
GROUP BY OnlineOrderFlag
ORDER BY OrderType


-- --------------------------------------------------------------------------------
-- 9. total unique customers who made a purchase and total unique products purchased 
-- --------------------------------------------------------------------------------
-- Findings: There are 19,119 unique customer who made at least one order.
-- There are 266 unique products sold.

SELECT
    COUNT(DISTINCT oh.CustomerID) AS CustomerCount,
    COUNT(DISTINCT od.ProductID) AS totalProducts
FROM sales.SalesOrderHeader AS oh
    JOIN sales.SalesOrderDetail AS od
    ON od.SalesOrderID = oh.SalesOrderID


-- --------------------------------------------------
-- 10. Revenue by Territory
-- --------------------------------------------------
-- Findings: The top 5 Territories with the highest total revenue are-
-- 1. Southwest with 6,224 total order count and 27,150,594.59 total revenue generated.
-- 2. Canada with 4,067 total order count and 18,398,929.19 total revenue generated.
-- 3. Northwest with 4,594 total order count and 18,061,660.37 total revenue generated.
-- 4. Australia with 6,843 total order count and 11,814,376.10 total revenue generated.
-- 5. Central with 385 total order count and 8,913,299.25 total revenue generated.

SELECT
    Territory,
    OrderCount,
    TotalRevenue,
    Ranking
FROM(
    SELECT
        t.Name AS Territory,
        COUNT(soh.SalesOrderID) AS OrderCount,
        ROUND(SUM(soh.TotalDue), 2) AS TotalRevenue,
        DENSE_RANK() OVER(ORDER BY ROUND(SUM(soh.TotalDue), 2) DESC) AS Ranking
    FROM Sales.SalesOrderHeader soh
        JOIN Sales.SalesTerritory t ON t.TerritoryID = soh.TerritoryID
    GROUP BY t.Name
) t
WHERE Ranking <= 5


-- ---------------------------------------------------
-- 11. Null checks
-- ---------------------------------------------------
-- There are 0 nulls in customers column
-- 0 nulls in OrderDate column.
-- 0 nulls in TotalDue column.
-- There are 27,659 nulls in SalesPerson as there are no sales person representative for online orders

SELECT
    SUM(CASE
            WHEN CustomerID IS NULL THEN 1 
            ELSE 0
        END) AS CustomerNulls,
    SUM(CASE
            WHEN OrderDate IS NULL THEN 1 
            ELSE 0
        END) AS OrderDateNulls,
    SUM(CASE
            WHEN TotalDue IS NULL THEN 1 
            ELSE 0
        END) AS TotalDueNulls,
    SUM(CASE
            WHEN SalesPersonID IS NULL THEN 1 
            ELSE 0
        END) AS SalesPersonNulls
FROM sales.SalesOrderHeader








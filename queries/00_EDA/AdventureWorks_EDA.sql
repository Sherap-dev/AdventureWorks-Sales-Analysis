-- sales Date Range
SELECT
    MIN(OrderDate) AS MininumOrderDate,
    MAX(OrderDate) AS MaximumOrderDate,
    DATEDIFF(DAY, MIN(OrderDate), MAX(OrderDate)) AS TotalDays,
    DATEDIFF(YEAR, MIN(OrderDate), MAX(OrderDate)) AS TotalYears,
    DATEDIFF(MONTH, MIN(OrderDate), MAX(OrderDate)) % 12 AS RemainingMonths,
    DATEDIFF(DAY, MIN(OrderDate), MAX(OrderDate)) % 30 AS RemainingDays
FROM sales.SalesOrderHeader


-- total number of orders in the sales Date Range
SELECT
    COUNT(SalesOrderID) AS TotalOrderCount
FROM sales.SalesOrderHeader


-- total online orders
SELECT
    COUNT(SalesOrderID) AS TotalOnlineOrdesCount
FROM sales.SalesOrderHeader
WHERE OnlineOrderFlag = 1


-- total in-store orders
SELECT
    COUNT(SalesOrderID) AS TotalStoreOrdesCount
FROM sales.SalesOrderHeader
WHERE OnlineOrderFlag = 0


-- total revenue, average order value, maximum order value and minimum order value
SELECT
    ROUND(SUM(TotalDue), 2)  AS TotalRevenue,
    ROUND(AVG(TotalDue), 2)  AS AverageOrderValue,
    ROUND(MAX(TotalDue), 2) AS MaximumOrderValue,
    ROUND(MIN(TotalDue), 2) AS MinimumOrderValue
FROM sales.SalesOrderHeader



SELECT



SELECT
    *
FROM sales.SalesOrderHeader
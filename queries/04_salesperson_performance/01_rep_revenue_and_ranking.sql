WITH
EmployeeSalesCTE AS(
    SELECT 
    sp.BusinessEntityID,
    CONCAT(p.FirstName, ' ', ISNULL(p.MiddleName + ' ', ''), p.LastName) AS EmployeeName,
    e.JobTitle,
    COUNT(distinct oh.SalesOrderID) AS TotalOrdersFulfilled,
    DATEDIFF(DAY, MIN(oh.OrderDate), MAX(oh.OrderDate)) AS ActiveDays,
    ROUND(SUM(od.UnitPrice * od.OrderQty * (1 - od.UnitPriceDiscount)), 2) AS TotalSalesPerEmployee,
    ROUND(SUM(od.UnitPrice * od.OrderQty * (1 - od.UnitPriceDiscount)) / NULLIF(DATEDIFF(DAY, MIN(oh.OrderDate), MAX(oh.OrderDate)), 0), 2) AS SalesPerDay,
    ROUND(AVG(od.UnitPrice * od.OrderQty * (1 - od.UnitPriceDiscount)), 2) AS AvgSalesPerEmployee
FROM Person.Person AS p
JOIN Sales.SalesPerson sp
ON sp.BusinessEntityID = p.BusinessEntityID
JOIN HumanResources.Employee AS e
ON e.BusinessEntityID = sp.BusinessEntityID
JOIN Sales.SalesOrderHeader AS oh
ON oh.SalesPersonID = sp.BusinessEntityID
JOIN Sales.SalesOrderDetail AS od
ON od.SalesOrderID = oh.SalesOrderID
GROUP BY
    sp.BusinessEntityID,
    CONCAT(p.FirstName, ' ', ISNULL(p.MiddleName + ' ', ''), p.LastName),
    e.JobTitle
)

SELECT
    *,
    DENSE_RANK() OVER(ORDER BY TotalSalesPerEmployee DESC) AS EmployeeRanking,
    ROUND(TotalSalesPerEmployee * 100.0 / SUM(TotalSalesPerEmployee) OVER(), 2) AS RevenueContribution,
    ROUND(AVG(TotalSalesPerEmployee) OVER(), 2) AS CompanyAvgSales,
CASE
    WHEN TotalSalesPerEmployee > AVG(TotalSalesPerEmployee) OVER() THEN 'Above Average'
    ELSE 'Below Average'
END AS PerformanceVsAverage
FROM EmployeeSalesCTE














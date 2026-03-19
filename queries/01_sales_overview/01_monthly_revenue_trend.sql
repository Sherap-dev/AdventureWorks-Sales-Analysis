WITH
    RevenuePerMonth
    AS
    
    (
        SELECT
            DATETRUNC(MONTH, sh.OrderDate) AS SalesMonth,
            DATENAME(MONTH, DATETRUNC(MONTH, sh.OrderDate)) AS MonthName,
            COUNT(sh.SalesOrderID) AS OrderCount,
            SUM(sd.UnitPrice * sd.OrderQty * (1 - sd.UnitPriceDiscount)) AS TotalMonthlyRevenue
        FROM Sales.SalesOrderHeader AS sh
            JOIN Sales.SalesOrderDetail AS sd
            ON sd.SalesOrderID = sh.SalesOrderID
        GROUP BY DATETRUNC(MONTH, sh.OrderDate), DATENAME(MONTH, DATETRUNC(MONTH, sh.OrderDate))
    ),
    MonthOverMonthCTE
    AS
    
    (
        SELECT
            SalesMonth,
            MonthName,
            OrderCount,
            ROUND(TotalMonthlyRevenue, 2) TotalMonthlyRevenue,
            ROUND(LAG(TotalMonthlyRevenue, 1) OVER(ORDER BY SalesMonth), 2) AS previousMonthRevenue,
            ROUND((TotalMonthlyRevenue - LAG(TotalMonthlyRevenue, 1) OVER(ORDER BY SalesMonth)), 2) AS MonthOverMonthChange,
            ROUND((TotalMonthlyRevenue - LAG(TotalMonthlyRevenue, 1) OVER(ORDER BY SalesMonth)) / LAG(TotalMonthlyRevenue, 1) OVER(ORDER BY SalesMonth) * 100, 2)  AS MonthOverMonthGrowthPercent,
            ROUND(AVG(TotalMonthlyRevenue) OVER(ORDER BY SalesMonth ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS RollingAvg3Months
        FROM RevenuePerMonth
    )
SELECT
    *, 

FROM MonthOverMonthCTE

SELECT *
FROM sales.SalesOrderDetail
SELECT *
FROM sales.SalesOrderHeader
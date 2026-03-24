WITH
    OnlineInstoreSalesCTE AS(
        SELECT
            DATETRUNC(YEAR, sh.OrderDate) AS SalesYear,
            COUNT(DISTINCT sh.SalesOrderID) AS OrderCount,
            CASE
                WHEN sh.OnlineOrderFlag = 1 THEN 'online'
                WHEN sh.OnlineOrderFlag = 0 THEN 'in-store'
            END AS OrderFlag,
            SUM(sd.UnitPrice * sd.OrderQty * (1 - sd.UnitPriceDiscount)) AS TotalRevenue
        FROM Sales.SalesOrderHeader AS sh
        JOIN Sales.SalesOrderDetail AS sd
        ON sd.SalesOrderID = sd.SalesOrderID
        GROUP BY
            DATETRUNC(YEAR, sh.OrderDate),
            CASE
                WHEN sh.OnlineOrderFlag = 1 THEN 'online'
                WHEN sh.OnlineOrderFlag = 0 THEN 'in-store'
            END
    )

 SELECT * FROM sales.SalesOrderDetail
 SELECT * FROM sales.SalesOrderHeader
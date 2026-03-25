WITH
    CustomersCTE AS(
        SELECT
            c.CustomerID,
            CONCAT(p.FirstName, ' ', ISNULL(p.MiddleName + ' ', ''), p.LastName) AS CustomerName,
            CASE
                WHEN c.StoreID IS NOT NULL THEN 'Store'
                ELSE 'Individual'
            END AS CustomerType,
            Min(oh.OrderDate) AS MinOrderDate,
            MAX(oh.OrderDate) AS MaxOrderDate,
            DATEDIFF(DAY, MIN(oh.OrderDate), MAX(oh.OrderDate)) AS RelationshipDays,
            COUNT(DISTINCT oh.SalesOrderID) AS OrderCount,
            ROUND(SUM(od.UnitPrice * od.OrderQty * (1 - od.UnitPriceDiscount)), 2)  AS totalSpent
        FROM Sales.Customer AS c
        LEFT JOIN Person.Person AS p
        ON p.BusinessEntityID = c.PersonID
        JOIN Sales.SalesOrderHeader AS oh
        ON oh.CustomerID = c.CustomerID
        JOIN Sales.SalesOrderDetail AS od
        ON od.SalesOrderID = oh.SalesOrderID
        GROUP BY 
            c.CustomerID,
            CONCAT(p.FirstName, ' ', ISNULL(p.MiddleName + ' ', ''), p.LastName),
            CASE
                WHEN c.StoreID IS NOT NULL THEN 'Store'
                ELSE 'Individual'
            END
    ),
    CustomerSegmentationCTE AS(
        SELECT
            *,
            NTILE(4) OVER(PARTITION BY CustomerType ORDER BY totalSpent DESC) AS Segmentation,
            CASE
                WHEN NTILE(4) OVER(PARTITION BY CustomerType ORDER BY totalSpent DESC) = 1 THEN 'High Value'
                WHEN NTILE(4) OVER(PARTITION BY CustomerType ORDER BY totalSpent DESC) = 2 THEN 'Mid Value'
                WHEN NTILE(4) OVER(PARTITION BY CustomerType ORDER BY totalSpent DESC) = 3 THEN 'Low Value'
                WHEN NTILE(4) OVER(PARTITION BY CustomerType ORDER BY totalSpent DESC) = 4 THEN 'At risk'
            END AS CustomerSegmentation,
            CASE
                WHEN OrderCount = 1 THEN 'One-time Buyer'
                WHEN OrderCount > 1 and OrderCount < 5 then 'Returning Customer'
                WHEN OrderCount >= 5 THEN 'Loyal Customer'
            END AS CustomerRetention
        FROM CustomersCTE
    )

-- SELECT * FROM CustomerSegmentationCTE

-- SELECT
--     CustomerType,
--     CustomerSegmentation,
--     CustomerRetention,
--     COUNT(*) AS CustomerCount
-- FROM CustomerSegmentationCTE
-- GROUP BY CustomerType ,CustomerSegmentation, CustomerRetention
-- ORDER BY CustomerType, CustomerSegmentation, CustomerRetention

-- SELECT TOP 10
--     CustomerName,
--     CustomerType,
--     OrderCount,
--     RelationshipDays,
--     totalSpent,
--     CustomerSegmentation,
--     CustomerRetention
-- FROM CustomerSegmentationCTE
-- WHERE CustomerType = 'Individual'
-- ORDER BY totalSpent DESC

SELECT TOP 10
    CustomerName,
    CustomerType,
    OrderCount,
    RelationshipDays,
    totalSpent,
    CustomerSegmentation,
    CustomerRetention
FROM CustomerSegmentationCTE
WHERE CustomerType = 'Store'
ORDER BY totalSpent desc
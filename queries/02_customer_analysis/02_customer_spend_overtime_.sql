WITH
    CustomersCTE AS(
        SELECT
            c.CustomerID,
            CONCAT(p.FirstName, ' ', ISNULL(p.MiddleName + ' ', ''), p.LastName) AS CustomerName,
            CASE
                WHEN c.StoreID IS NOT NULL THEN 'Store'
                ELSE 'Individual'
            END AS CustomerType,
            COUNT(distinct oh.SalesOrderID) AS OrderCountPerMonth,
            DATETRUNC(MONTH, oh.OrderDate)  AS OrderDate,
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
            END,
            DATETRUNC(MONTH, oh.OrderDate) 
    ),
    BaseMoMCTE AS(
        SELECT
            *,
            COUNT(*) OVER(partition by CustomerID) AS TotalMonthsCustomerOrdered,
            LAG(totalSpent, 1) OVER(PARTITION BY CustomerID, CustomerType ORDER BY OrderDate) AS PreviousSpent
        FROM CustomersCTE
    ),
    CustomerSpentMoMCTE AS(
        SELECT
            CustomerID,
            CustomerName,
            CustomerType,
            OrderCountPerMonth,
            TotalMonthsCustomerOrdered,
            OrderDate,
            totalSpent,
            PreviousSpent,
            (totalSpent - PreviousSpent) AS MoMChange,
            ROUND(
                (totalSpent - PreviousSpent) / PreviousSpent * 100
            , 2) AS ChangePercent
        FROM BaseMoMCTE
    ),
    GoneSilentCTE AS(
        SELECT 
            CustomerID,
            CustomerName,
            CustomerType,
            MAX(OrderDate) AS LastOrderMonth,
            DATETRUNC(MONTH, l.LatestOrderDate) AS LastRecordedOrderDate,
            DATEDIFF(DAY, MAX(OrderDate), l.LatestOrderDate) AS daysSinceLastOrder
        FROM CustomerSpentMoMCTE
        CROSS JOIN (
            SELECT 
                MAX(OrderDate) AS LatestOrderDate
            FROM Sales.SalesOrderHeader
        ) AS l
        GROUP BY
            CustomerID,
            CustomerName,
            CustomerType,
            l.LatestOrderDate
    ),
    CustomerStatusCTE AS(
        SELECT
            CustomerID,
            CustomerName,
            CustomerType,
            COUNT(CustomerID) OVER(partition by CustomerType) AS TotalCustomersInCustomeType,
        CASE
            WHEN daysSinceLastOrder > 360 THEN 'Gone Silent'
            WHEN daysSinceLastOrder > 180 THEN 'At Risk'
            ELSE 'Active'
        END AS CustomerStatus     
        FROM GoneSilentCTE
        GROUP BY
            CustomerID,
            CustomerName,
            CustomerType,
        CASE
            WHEN daysSinceLastOrder > 360 THEN 'Gone Silent'
            WHEN daysSinceLastOrder > 180 THEN 'At Risk'
            ELSE 'Active'
        END
    )

SELECT
    * 
FROM CustomerSpentMoMCTE
WHERE TotalMonthsCustomerOrdered >= 3
ORDER BY CustomerID, OrderDate

SELECT
    CustomerType,
    CustomerStatus,
    TotalCustomersInCustomeType,
    COUNT(*) AS CustomerStatusCount,
    ROUND(COUNT(*) * 100 / TotalCustomersInCustomeType, 2) AS PercentFromTotal
FROM CustomerStatusCTE
GROUP BY CustomerType, CustomerStatus, TotalCustomersInCustomeType
ORDER BY CustomerType




    





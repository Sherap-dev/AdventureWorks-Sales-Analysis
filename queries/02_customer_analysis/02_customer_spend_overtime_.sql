WITH
    CustomersCTE AS(
        SELECT
            c.CustomerID,
            CASE
                WHEN c.StoreID IS NOT NULL THEN s.Name
                ELSE CONCAT(p.FirstName, ' ', ISNULL(p.MiddleName + ' ', ''), p.LastName)
            END AS CustomerName,
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
        LEFT JOIN Sales.Store AS s
        ON s.BusinessEntityID = c.StoreID
        JOIN Sales.SalesOrderHeader AS oh
        ON oh.CustomerID = c.CustomerID
        JOIN Sales.SalesOrderDetail AS od
        ON od.SalesOrderID = oh.SalesOrderID
        GROUP BY 
            c.CustomerID,
            CASE
                WHEN c.StoreID IS NOT NULL THEN s.Name
                ELSE CONCAT(p.FirstName, ' ', ISNULL(p.MiddleName + ' ', ''), p.LastName)
            END,
            CASE
                WHEN c.StoreID IS NOT NULL THEN 'Store'
                ELSE 'Individual'
            END,
            DATETRUNC(MONTH, oh.OrderDate) 
    ),
    BaseMoMCTE AS(
        SELECT
            *,
            COUNT(*) OVER(PARTITION BY CustomerID) AS TotalMonthsCustomerOrdered,
            LAG(totalSpent, 1) OVER(PARTITION BY CustomerID ORDER BY OrderDate) AS PreviousSpent
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
                CASE 
                    WHEN PreviousSpent = 0 OR PreviousSpent IS NULL THEN NULL
                    ELSE (totalSpent - PreviousSpent) * 100.0 / PreviousSpent 
                END
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
            DATEDIFF(MONTH, MAX(OrderDate), DATETRUNC(MONTH, l.LatestOrderDate)) AS MonthsSinceLastOrder
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
            COUNT(CustomerID) OVER(partition by CustomerType) AS TotalCustomersInCustomerType,
        CASE
            WHEN MonthsSinceLastOrder > 12 THEN 'Gone Silent'
            WHEN MonthsSinceLastOrder > 6 THEN 'At Risk'
            ELSE 'Active'
        END AS CustomerStatus     
        FROM GoneSilentCTE
    ),
    CustomerTrendCTE AS (
    SELECT
        CustomerID,
        CustomerType,
        AVG(ChangePercent) AS AvgChangePercent
    FROM CustomerSpentMoMCTE
    WHERE TotalMonthsCustomerOrdered >= 3
      AND ChangePercent IS NOT NULL
    GROUP BY CustomerID, CustomerType
)
-- ====================================================
-- QUERY 1: Customer Month Over Month Spend Trend.
-- ====================================================
-- Findings:
-- This query provides the monthly spend trend for customers with
-- 3 or more months where the ordered at least once. The Key insights
-- will be derived from the helper queries below.
-- See helper query 1 for average Month over month trend.
-- See helper query 2 for total customers who ordered in at least 3 months.
-- See helper query 3 for Growing vs Declining customer count.

-- SELECT
--     * 
-- FROM CustomerSpentMoMCTE
-- WHERE TotalMonthsCustomerOrdered >= 3
-- ORDER BY CustomerID, OrderDate

-- =====================================================================================
-- QUERY 2: Customer Status Percentage from Total Individual and Store customer count.
-- =====================================================================================
-- Findings:
--  INDIVIDUAL-
--      1. There are 18,484 total customers in the Individual Customer Type.

--      2. Out of total customers 11,342 are Active customers or customers who
--       are frequently ordering products. These customers make about 61.36% 
--       of the total.

--      3. There are 6,619 customers who are At Risk or customers who have not
--       made any orders for 6 months since their last order month. These customers
--       make about 35.81% of the total.

--      4. There are 523 customers who have Gone Silent or have not made any orders
--       for 360 days since their last order date. These customers make about 2.83%
--       of the total.

--  STORE-
--      1. There are 635 total customers in the Store Customer Type.

--      2. There are 462 customers who are Active and makes about 72.76% of the total.

--      3. There are 146 customers who are At Risk and makes about 22.99% of the total.

--      4. There are only 27 customers who have Gone Silent making about 4.25% of the total.

-- SELECT
--     CustomerType,
--     CustomerStatus,
--     TotalCustomersInCustomerType,
--     COUNT(*) AS CustomerStatusCount,
--     ROUND(COUNT(*) * 100.0 / TotalCustomersInCustomerType, 2) AS PercentFromTotal
-- FROM CustomerStatusCTE
-- GROUP BY CustomerType, CustomerStatus, TotalCustomersInCustomerType
-- ORDER BY CustomerType


-- ====================================================
--                  HELPER QUERIES
-- ====================================================
-- HELPER 1:
--  Findings:
--      The Average Total Spent of a Store Type Customer was about 
--      21,621.88. The Average Change was about -448.32 and the Average
--      Change Percent was 496.45%. This implies on Average the Store
--      customer type is consistently growing.

--      The Average Total Spent of an Individual Customer Type was about
--      1,295.46. The Average Change was about -190.75 and the Average Change
--      Percent was about 44.97. We can see much less growth in the Individual customer
--      type compare to store mostly due to Store spending much more in every order
--      or buying in bulk.

-- (NOTE: Analysis was done where Number of months Customer ordered was more or equal to 3.)

-- SELECT
--     CustomerType,
--     ROUND(AVG(totalSpent), 2) AS AvgTotalSpent,
--     ROUND(AVG(MoMChange), 2) AS AvgMoMChange,
--     ROUND(AVG(ChangePercent), 2) AS AvgMoMChangePercent
-- FROM CustomerSpentMoMCTE
-- WHERE TotalMonthsCustomerOrdered >=3 AND ChangePercent IS NOT NULL
-- GROUP BY CustomerType


-- HELPER 2:
-- Findings:
-- The analysis was done where the customers in both customer type had ordered in at least 3
--  or more months.

-- 1. There are 585 store customers who bought in at least 3 or more months and there are 1,276 individual
-- customer who also bought in at least 3 months.

-- SELECT
--     CustomerType,
--     COUNT(CustomerID) AS CustomerCount
-- FROM CustomerTrendCTE
-- GROUP BY CustomerType


-- HELPER 3:
-- Findings:
-- 1. Out of 1,276 individual customers 561 showed Decline and 715 showed Growth.

-- 2. Out of 585 store customers 135 showed Decline and 449 showed Growth while 1 
-- customer remain flat or the customer spent same amount of money.

-- SELECT
--     CustomerType,
--     CASE
--         WHEN AvgChangePercent > 0 THEN 'Growing'
--         WHEN AvgChangePercent < 0 THEN 'Declining'
--         ELSE 'Flat'
--     END AS SpendTrend,
--     COUNT(*) AS CustomerCount
-- FROM CustomerTrendCTE
-- GROUP BY 
--     CustomerType,
--     CASE
--         WHEN AvgChangePercent > 0 THEN 'Growing'
--         WHEN AvgChangePercent < 0 THEN 'Declining'
--         ELSE 'Flat'
--     END
-- ORDER BY CustomerType, SpendTrend;
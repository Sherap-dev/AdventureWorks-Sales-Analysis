-- ================================================
-- Online vs In-Store Year Over Year Growth
-- Dataset: Adventure Works 2022
-- ================================================
-- Business Questions:
-- 1. How has online and in-store revenue grown 
--    year over year?
-- 2. Which channel is growing faster?
-- 3. How does order volume compare year over year
--    between channels?
-- ================================================

WITH
    OnlineInstoreSalesCTE AS(
        SELECT
            YEAR(sh.OrderDate) AS SalesYear,
            CASE
                WHEN sh.OnlineOrderFlag = 1 THEN 'online'
                WHEN sh.OnlineOrderFlag = 0 THEN 'in-store'
            END AS OrderFlag,
            COUNT(DISTINCT sh.SalesOrderID) AS OrderCount,
            ROUND(SUM(sd.UnitPrice * sd.OrderQty * (1 - sd.UnitPriceDiscount)), 2)  AS TotalRevenue
        FROM Sales.SalesOrderHeader AS sh
        JOIN Sales.SalesOrderDetail AS sd
        ON sd.SalesOrderID = sh.SalesOrderID
        GROUP BY
            YEAR(sh.OrderDate),
            CASE
                WHEN sh.OnlineOrderFlag = 1 THEN 'online'
                WHEN sh.OnlineOrderFlag = 0 THEN 'in-store'
            END
    ),
    OnlineInstoreYoYCTE AS(
        SELECT 
            *,
            LAG(TotalRevenue, 1) OVER(PARTITION BY OrderFlag ORDER BY SalesYear) AS PreviousYearRevenue,
            (TotalRevenue - LAG(TotalRevenue, 1) OVER(PARTITION BY OrderFlag ORDER BY SalesYear)) AS YoYChange,
            ROUND((TotalRevenue - LAG(TotalRevenue, 1) OVER(PARTITION BY OrderFlag ORDER BY SalesYear))
            / LAG(TotalRevenue, 1) OVER(PARTITION BY OrderFlag ORDER BY SalesYear) * 100, 2) AS ChangePercent,
            ROUND(AVG(TotalRevenue) OVER(PARTITION BY OrderFlag ORDER BY SalesYear ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2)  AS YearlyRollingAvg
        FROM OnlineInstoreSalesCTE
    )

-- ====================================================
--  QUERY 1: In-store vs Online Year Over Year Trend.
-- ====================================================
-- Findings:
-- 1. In both In-store and Online consistent growth can be seen.
--  The Yearly Rolling Average confirms that as, In-store Revenue grew
--  from approx. 8M in 2011 to approx. 23M in 2014 and Online revenue grew
--  from approx. 3M in 2011 to 8M in 2014.
-- 2. Total Online Order Count - 27,659.
--  Total in-store Order Count - 3,806. As we can see online order count was
--  much higher than in-store, the in-store still dominates in total revenue
--  generation with approx. 80M total revenue. The Online only generated about 29M. 
-- 3. For In-store the highest growth was seen in 2012 with 209.09% and the highest decline
--  being 64.47% seen in 2014.
--  For Online the highest growth was seen in 2013 with 67.93% and the highest decline being 
--  21.98% seen in 2014. This indicates that the in-store sales are volatile in nature and online 
--  is much consistent.

-- (NOTE: 2011 and 2014 have incomplete data so YoY comparisons
--  are most reliable between 2012 and 2013.)

-- SELECT
--     *,
--     CASE
--         WHEN ChangePercent > 0 THEN 'Growth'
--         WHEN ChangePercent < 0 THEN 'Decline'
--         ELSE 'No Data'
--     END AS GrowthInfo
-- FROM OnlineInstoreYoYCTE

-- ====================================================
--                 HELPER QUERIES
-- ====================================================

-- Helper 1: Total Online and In-Store Order Count.
-- SELECT
--     OrderFlag,
--     SUM(OrderCount) AS TotalORderCount
-- FROM OnlineInstoreSalesCTE
-- GROUP BY OrderFlag

-- Helper 2: Total Online and In-Store Revenue.
-- SELECT
--     OrderFlag,
--     SUM(TotalRevenue) AS TotalRevenue
-- FROM OnlineInstoreSalesCTE
-- GROUP BY OrderFlag
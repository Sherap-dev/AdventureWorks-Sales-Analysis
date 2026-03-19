-- =====================================
-- MONTHLY REVENUE TREND ANALYSIS
-- Dataset: AdventureWorks 2022
-- =====================================
-- Business Questions:
-- How was revenue trending month over month?
-- Are we growing or declining?
-- What Months and Years performs bbest?

WITH 
RevenuePerMonth AS(
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
RevenuePerYear AS(
    SELECT 
        YEAR(SalesMonth) AS SalesYear,
        SUM(TotalMonthlyRevenue) AS yearlyRevenue
    FROM RevenuePerMonth
    GROUP BY YEAR(SalesMonth)
),
MonthOverMonthCTE AS(
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
),
RevenueRankingCTE AS(
    SELECT 
        YEAR(SalesMonth) AS SalesYear,
        SalesMonth,
        MonthName,
        OrderCount,
        TotalMonthlyRevenue,
        DENSE_RANK() OVER(PARTITION BY YEAR(SalesMonth) ORDER BY TotalMonthlyRevenue DESC) AS RevenueRankingPerYear
    FROM RevenuePerMonth
)

-- ================================================
-- QUERY 1: Month Over Month Revenue Trend
-- ================================================
-- FINDINGS: 
-- - Out of 37 moonths, 20 showed growth and 17 showed decline confirming overall monthly growth was consistent throughout.
-- - The heighest growth month was January 2012 with 203.13% growth.
-- - The heighest deline month was August 2013 with 31.90% decline. 

-- (NOTE: Oct 2011 had the heighest growth percentage of 813.96% and June 2014 had the heighest decline with 99.08%
-- since these years have incomplete data, metrics from these years are not presented for the above finding.)
-- - Rolling average confirms steady upward trend 2011-2014.

-- SELECT
--     *,
--     CASE
--         WHEN MonthOverMonthGrowthPercent > 0 THEN 'Growth'
--         WHEN MonthOverMonthGrowthPercent < 0 THEN 'Decline'
--         ELSE 'No Data'
--     END AS GrowthInfo
-- FROM MonthOverMonthCTE


-- ==========================================
--  QUERY 2: Best Performing Month Per Year
-- ==========================================
-- FINDINGS:
-- - 2011 the best performing Month was October with 4,588,761.8161
-- total monthly revenue generated with 2083 total Orders.
-- - 2012 the best performing month was June with 4,099,354.3573 
-- total monthly revenue generated with 3215 total orders.
-- - 2013 the best performing month was June with 5,081,069.1355
-- toal monthly revenue generated with 5210 total orders.
-- - 2014 the best performing month was March with 7,217,531.0932
-- total monthly revenue generated with 9955 total orders.
-- Among complete years, June appears twice as the best performing month in both 
-- 2012 and 2013 suggesting a mid year seasonal peak in sales.

-- (NOTE: 2011 and 2014 not taken into comparison since they have incomplete data).

-- SELECT 
--     *
-- FROM RevenueRankingCTE
-- WHERE RevenueRankingPerYear = 1

-- =======================================
-- QUERY 3: Year Over Year Revenue Trend
-- =======================================
-- FINDINGS: Revenue grew from 33,524,301.33 in 2012 to 43,622,479.07 in 2013
-- representing approximately 30.12% Year Over Year Growth.
-- Year over year change of 10,098,177.74 show strong growth in business.
-- Order count grew from 3915 in 2012 to 14,182 in 2013 confirming
-- growth is driven by customer demand

-- (NOTE: 2011 and 2014 not included for comparison due to incomplete data)

-- SELECT
--     SalesYear,
--     o.YearlyOrderCount,
--     ROUND(yearlyRevenue, 2) AS YearlyRevenue,
--     ROUND(LAG(yearlyRevenue, 1) OVER(ORDER BY SalesYear), 2) AS PreviousYearRevenue,
--     ROUND((yearlyRevenue - LAG(yearlyRevenue, 1) OVER(ORDER BY SalesYear)), 2)  AS YearOverYearChange,
--     ROUND(
--         (yearlyRevenue - LAG(yearlyRevenue, 1) OVER(ORDER BY SalesYear)) / LAG(yearlyRevenue, 1) OVER(ORDER BY SalesYear) * 100,
--     2) AS YearOverYearGrowthPercent,
--     ROUND(AVG(yearlyRevenue) OVER(ORDER BY SalesYear rows between 2 preceding and current row), 2) AS RollingAvg2Years
-- FROM RevenuePerYear as r
-- JOIN(
--     SELECT
-- YEAR(OrderDate) AS year,
-- count(SalesOrderID) AS YearlyOrderCount
-- FROM sales.SalesOrderHeader
-- GROUP BY YEAR(OrderDate)
-- ) AS o
-- ON o.year = r.SalesYear

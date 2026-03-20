-- ========================================
-- Online Vs In-Store Trend Analysis
-- Dataset: Adventure Works 2022
-- ========================================
-- Business Questions:
-- 1. What is the Online and Instore Month Over Month 
--   revenue trend?
-- 2. What is the Monthly difference between Online and 
--   in-store sales revenue?
-- 3. What is the difference between total Online and 
--   In-store sales revenue?
-- 4. Which channel generates higher average order value?
--   online or in-store?

WITH
    OnlineInStoreCTE AS(
        SELECT 
            DATETRUNC(MONTH, sh.OrderDate) AS SalesMonth,
            CASE
                WHEN sh.OnlineOrderFlag = 1 THEN 'online'
                WHEN sh.OnlineOrderFlag = 0 THEN 'in-store'
            END AS OrderFlag,
            COUNT(DISTINCT sh.SalesOrderID) AS OrderCount,
            ROUND(SUM(so.UnitPrice * so.OrderQty * (1 - so.UnitPriceDiscount)), 2)  AS RevenuePerMonth
        FROM Sales.SalesOrderHeader AS sh
        JOIN Sales.SalesOrderDetail AS so
        ON so.SalesOrderID = sh.SalesOrderID
        -- WHERE sh.OnlineOrderFlag = 1
        GROUP BY DATETRUNC(MONTH, sh.OrderDate), CASE
                WHEN sh.OnlineOrderFlag = 1 THEN 'online'
                WHEN sh.OnlineOrderFlag = 0 THEN 'in-store'
            END
    ),
    MomOnlineInStoreGrowthCTE AS(
        SELECT
            SalesMonth,
            OrderFlag,
            OrderCount,
            RevenuePerMonth,
            LAG(RevenuePerMonth, 1) OVER(PARTITION BY OrderFlag ORDER BY SalesMonth) AS PreviousMonthSales,
            (RevenuePerMonth - LAG(RevenuePerMonth, 1) OVER(PARTITION BY OrderFlag ORDER BY SalesMonth)) AS MomChange,
            ROUND(
                (RevenuePerMonth - LAG(RevenuePerMonth, 1) OVER(PARTITION BY OrderFlag ORDER BY SalesMonth))
           / LAG(RevenuePerMonth, 1) OVER(PARTITION BY OrderFlag ORDER BY SalesMonth) * 100, 2)  AS MomGrowthPercent,
            ROUND(AVG(RevenuePerMonth) OVER(PARTITION BY OrderFlag ORDER BY SalesMonth ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2)  AS ThreeMonthRollingAvg
        FROM OnlineInStoreCTE
    ),
    OnlineInStoreComparisonCTE AS(
        SELECT
            SalesMonth,
            DATENAME(MONTH, SalesMonth) AS MonthName,
            SUM(CASE WHEN OrderFlag = 'online' THEN RevenuePerMonth ELSE 0 END) AS OnlineRevenue,
            SUM(CASE WHEN OrderFlag = 'in-store' THEN RevenuePerMonth ELSE 0 END) AS InStoreRevenue,
            SUM(CASE WHEN OrderFlag = 'online' THEN OrderCount ELSE 0 END) AS OnlineOrders,
            SUM(CASE WHEN OrderFlag = 'in-store' THEN OrderCount ELSE 0 END) AS InStoreOrders
        FROM OnlineInStoreCTE
        GROUP BY SalesMonth
    )

-- ======================================================
-- QUERY 1: Online sales Month Over Month revenue trend
-- ======================================================
-- Findings: 
--  1. The maximum month over month Online growth rate was 54.69%
--    seen in November of 2012.
--  2. Maximum decline rate being 29.87% seen in August of 2012.
--  3. Out of 37 months 23 months saw growth and 14 saw decline in 
--    month over month growth percent suggesting consistent growth in Online revenue generation.
--  4. Three months rolling average grew from 649,714.77 to 1,126,841.03 between 2012 and 2013.

-- (NOTE: The maximun month over month Online growth rate was seen in June of 2011 with 3069.85% and
--  maximum decline was seen in June of 2014 with 97.48%. These metrics are not included in the findings
--  as 2011 and 2014 have incomplete data.)

-- SELECT
--     SalesMonth,
--     DATENAME(MONTH, SalesMonth) AS MonthName,
--     OrderFlag,
--     OrderCount,
--     RevenuePerMonth,
--     PreviousMonthSales,
--     MomChange,
--     MomGrowthPercent,
--     ThreeMonthRollingAvg,
--     CASE
--         WHEN MomGrowthPercent > 0 THEN 'Growth'
--         WHEN MomGrowthPercent < 0 THEN 'Decline'
--         ELSE 'No Data'
--     END AS GrowthInfo
-- FROM MomOnlineInStoreGrowthCTE
-- WHERE OrderFlag = 'online'


-- ======================================================
-- QUERY 2: In-store sales Month Over Month revenue trend
-- ======================================================
-- Findings: 
--  1. The maximum month over month in-store growth rate was 370.61%
--    seen in January of 2012 and Maximum decline rate being 73.69% 
--    seen in February of 2012 which shows high volatility with high 
--    revenue swing range. 
--    The alternating Growth and decline months throughout the period
--    also suggests high volatility.
--  2. Out of 33 months 19 months saw growth and 14 saw decline indecating
--    overall positive momentum for in-store sales.
--  3. Despite monthly volatility the Three months rolling average shows 
--    a consistent underlying upward trend from 2011 - 2013 growing from
--    489,328.58 to 2,958,741.40.
 
-- (NOTE: 2014 in-store data shows a suspecious alternating pattern where every even months
--  February and April recorded near zero orders while odd months January, March and May had 100+
--  orders making the order volume normal. This alternating anomaly suggest missing or incomplete data for
-- 2014.)

-- (NOTE: The maximun month over month in-store growth rate was seen in May of 2014 with 265739.48% and
--  maximum decline was seen in April of 2014 with 99.97%. These metrics are not included in the findings
--  as 2011 and 2014 have incomplete data.)

-- SELECT
--     SalesMonth,
--     DATENAME(MONTH, SalesMonth) AS MonthName,
--     OrderFlag,
--     OrderCount,
--     RevenuePerMonth,
--     PreviousMonthSales,
--     MomChange,
--     MomGrowthPercent,
--     ThreeMonthRollingAvg,
--     CASE
--         WHEN MomGrowthPercent > 0 THEN 'Growth'
--         WHEN MomGrowthPercent < 0 THEN 'Decline'
--         ELSE 'No Data'
--     END AS GrowthInfo
-- FROM MomOnlineInStoreGrowthCTE
-- WHERE OrderFlag = 'in-store'


-- ===================================================================
-- QUERY 3: monthly comparison between online and in-store revenue.
--===================================================================
-- Findings:
-- 1. Revenue Difference shows that in-store orders consistently generate more revenue
--   with the max in-store revenue difference was 3,465,398.86 recorded in October 2011
--   while minimum being 25,774.69 recorded in November 2013 excluding months with zero
--   in-store orders.
-- 2. The max average monthly order value for online order peaked at about 3,255.64 in early
--   2012 and significantly declined to 541 by July 2013 as the oorder volume grew substancially.
--   The max average monthly order value for in-store order was about 33,245.69 roughly 10x higher
--   than the online peak.
-- 3. The revenue difference in percent confirms in-store generating more revenue with 97.04%
--   being the highest difference percentage recorded in May of 2011 and the lowest being 1.54%
--   recorded November of 2013.
-- 4. Online orders receivs higher volumer in orders but generates less revenue
--   while in-store receive comparatively lower order volumer but higher revenue generated,
--   suggesting in-store customers tend to purchase high value items while online customer place
--   more frequent orders but lower value orders.

-- (NOTE: June, September and November of 2011, recorded zero in-store orders
--  resulting in negative revenue difference as online revenue exceeded in-store for those months.
--  This may indicate potential store closure during those period. Negative value in February and April of 2014
--  due to abnormal near zero in-store orders suggesting inconsistent missing data in 2014, 2014 data not considered 
--  for comparison.)

-- SELECT
--     SalesMonth,
--     MonthName,
--     OnlineOrders,
--     InStoreOrders,
--     OnlineRevenue,
--     InStoreRevenue,
--     ROUND(InStoreRevenue - OnlineRevenue, 2) AS RevenueDifference,
--     ROUND(OnlineRevenue / NULLIF(OnlineOrders, 0), 2) AS AvgMonthlyOnlineOrderValue,
--     ROUND(InStoreRevenue / NULLIF(InStoreOrders, 0), 2) AS AvgMonthlyInStoreOrderValue,
--     ROUND((InStoreRevenue - OnlineRevenue) / NULLIF(InStoreRevenue, 0)  * 100, 2)  AS RevenueDifferencePercentage
-- FROM OnlineInStoreComparisonCTE
-- ORDER BY SalesMonth

-- ========================================================
-- QUERY 4: Total online and in-store revenue comparison.
-- ========================================================
-- Findings:
-- 1. Online received massively more orders compared to in-store with 27,659 total online orders and 3,806 total in-store orders.
-- 2. Even though the order count of in-store was much lower than online, the total revenue generated by in-store was much higher with
--   80.5M total revenue. The online total revenue came around 29.4M. The total in-store revenue difference was about
--   51.2M and the total in store revenue exceeded online by 63.52% of total in-store revenue
-- 3. The in-store average order value was about 21,147.58 compared to online average order value of 1061.45 confirming
--   that in-store customers consistently purchase higher value items.

-- SELECT
--     SUM(OnlineOrders) TotalOnlineOrders,
--     SUM(InStoreOrders) TotalInStoreOrders,
--     SUM(OnlineRevenue) TotalOnlineRevenue,
--     SUM(InStoreRevenue) TotalInstoreRevenue,
--     ROUND(SUM(InStoreRevenue) - SUM(OnlineRevenue), 2) TootalInStoreRevenueDifference,
--     ROUND(SUM(OnlineRevenue) / NULLIF(SUM(OnlineOrders), 0), 2) AvgOnlineOrderValue,
--     ROUND(SUM(InStoreRevenue) / NULLIF(SUM(InStoreOrders), 0), 2) AvgInStoreOrderValue,
--     ROUND((SUM(InStoreRevenue) - SUM(OnlineRevenue)) / NULLIF(SUM(InStoreRevenue), 0)  * 100, 2) TotalInStoreRevenueDifferencePercentage
-- FROM OnlineInStoreComparisonCTE

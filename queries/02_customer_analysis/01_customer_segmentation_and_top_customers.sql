-- ========================================
-- Customer Segmentation and Top Customers
-- Dataset: Adventure Works 2022
-- ========================================
-- Business Questions:
-- 1. Who are our most valuable customers?
-- 2. How are our customers segmented by 
--    spending behavior?
-- 3. Are we retaining our customers or 
--    losing them?
-- 4. Who are our top 10 individual and 
--    store customers?
-- ========================================

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

-- ====================================================
-- QUERY 1: Customer Segmentation and Retention.
-- ----------------------------------------------------
-- Findings:
-- --------------------------------------------------------
-- 1. Individual Customers -
-- --------------------------------------------------------
--      1a. The average relationship days was 157 days and the average spent was 1588.33.

--      1b. The Highest number of Relationship days comes from Customer Albert R Alvarez with 1089 days
--         with 2 order count during the realtionship days with 5,938.25 spent.

--      1c. The highest number of order count comes from 4 customers with 7 orders namely Lisa Cai
--         Lacey C Zheng, Jordan C Turner and Larry Munoz. The highest number of realtionship days
--         was 441 days by Customer Larry Munoz. The highest spent was 11,469.19 by Customer Lisa Cai.
-- --------------------------------------------------------
-- 2. Store -
-- --------------------------------------------------------
--      2a. The average realtionshipdays was 492 and the average spent was 126752.29.

--      2b. The Highest number of relationship days comes from 21 customers with 1005 days and the 
--        highest spending with long term relationship was 73,0798.71 by customer Robin M. McGuigan.

--      2c. The highest number of order count was 12 coming from 64 customer.

-- SELECT
--     *,
--     AVG(RelationshipDays) OVER(PARTITION BY CustomerType) AS averageRelationshipDays,
--     ROUND(AVG(totalSpent) OVER(PARTITION BY CustomerType), 2) AS AverageSpent
-- FROM CustomerSegmentationCTE

-- =====================================================
-- QUERY 2: Customer Segmentation and Retention Count.
-- ----------------------------------------------------
-- Findings: 
-- 1. There are 18,484 Individual customers and 635 Store.
-- --------------------------------------------------------
-- 2. Individual Customers -
-- --------------------------------------------------------
--      2a. There are 309 Individual Customers who are high value
--        and One-time Buyer compared to other segments with the 
--        highest number of One-time Buyers coming from the At Risk
--        segment with 4,419 customers, Mid value segment coming at second
--        position with 3,819 customers and Low value segment coming at third
--        with 3072 customers. In total there are 11619 Individual One-time buyer from all
--        segments making about 62% of total Individual customers suggesting a significant
--        retention problem.

--      2b. Most number of Loyal Individual customers (customers with order count more than 5)
--        come from the Mid value section with 56 customers. The Low value segment comes 
--        second with 21 customer and high value segment comes last with only 18 customers while
--        there and no loyal customers in the At Risk segment suggesting potential future growth
--        in the Mid Value segment.
--        (-- NOTE: High Value segment is based on total spend not order frequency
--              so a customer spending heavily in one order ranks as High Value
--              but may still be a One-time buyer.)

--      2c. The High Value segment has the most returning customers with 4,294
--        customers. This is interesting because High Value is determined by 
--        total spend not order frequency. This means these customers spend 
--        heavily per order and keep coming back making them the most promising 
--        segment for conversion to Loyal customers in the future.
-- 
-- --------------------------------------------------------
-- 3. Store -
-- --------------------------------------------------------
--      3a. There no One-time Buyer in the High value, Mid value and Low value
--        segment with only 30 One-time buyer in the At-risk segment suggesting
--        us that the customers in other segments are consistently buying.

--      3b. Most number of Loyal customers come from the High Value segment with 116
--        customers, while 87 and 74 come from the low and mid value segment respectively 
--        suggesting growing numbers of Loyal customers in low and mid value segment.

-- SELECT
--     CustomerType,
--     CustomerSegmentation,
--     CustomerRetention,
--     COUNT(*) AS CustomerCount
-- FROM CustomerSegmentationCTE
-- GROUP BY CustomerType ,CustomerSegmentation, CustomerRetention
-- ORDER BY CustomerType, CustomerSegmentation, CustomerRetention


-- =====================================================
-- QUERY 3: Top 10 Individual Customers.
-- -----------------------------------------------------
-- Findings:
-- 1. All of the top 10 Individual customers come from the High Value
--  segment and are all Loyal Customers.

-- 2. The top spending customer is Nichole Nara with 13,295.38 total
--  spent with 5 orders in the span of 925 relationship days.

-- 3. The lowest spending customer is Maurice M Shan with 12909.67 total
--  spent with 6 orders in the span of 286 relationship days.

-- 4. The customer with the longest relationship days is Brandi D Gill
--  with 982 days in relationship days and the total spent was 13,195.64 with
--  5 orders.

-- 5. The average spent by our top 10 customer was 13,202.64 and average relationship
--  days was 861 days.

-- SELECT 
--     *,
--     ROUND(AVG(totalSpent) OVER(), 2)  AS AverageSpent,
--     AVG(RelationshipDays) OVER() AS averageRelationshipDays
-- FROM(
--     SELECT TOP 10
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
-- ) AS Top10

-- =====================================================
-- QUERY 4: Top 10 Store Customers.
-- -----------------------------------------------------
-- Findings:
-- 1. All of our Store Customers come from the High Value segment
--  and are all Loyal Customer.

-- 2. Our Top spending customer was Roger Harui with 877,107.19 total
--  spend with 12 orders in the span of 1004 relationship days.

-- 3. The Lowerst spending customer was Stacey M. Cereghino with 
--  727,272.65 with 12 orders and 1005 in relationship days.

-- 4. The shortest relationship days and smallest order count comes from
-- Kirk DeGrasse with 639 days and 8 orders and the total spent was 746,317.53.

-- 5. The longest relationships comes at 1005 days by three customers namely
-- Ryan Calafato, Robin M. McGuigan and Stacey M. Cereghino. All of these customers
-- have the same number of order count of 12. The highest spender among the three 
-- was Ryan Calafato with 799,277.90 total spend, second is Robin M. McGuigan with
-- 73,0798.71 and Stacey M. Cereghino as the third customer with 727,272.65 total spent.

-- 6. The average spent by store was 792,204.64 and the average relationship days was 967 days.

-- (NOTE: Top 10 store customers average spend of 797,204.64 dwarfs top 10 individual average of
-- 13,202.64 confirming that stores spend approximately 60x more than individuals making store customer
-- retention the highest business priority.)

-- SELECT
--     *,
--     ROUND(AVG(totalSpent) OVER(), 2)  AS AverageSpent,
--     AVG(RelationshipDays) OVER() AS averageRelationshipDays
-- FROM(
--     SELECT TOP 10
--     CustomerName,
--     CustomerType,
--     OrderCount,
--     RelationshipDays,
--     totalSpent,
--     CustomerSegmentation,
--     CustomerRetention
-- FROM CustomerSegmentationCTE
-- WHERE CustomerType = 'Store'
-- ORDER BY totalSpent desc
-- ) AS Top10Store


-- =====================================================
--                  HELPER QUERIES
-- =====================================================
-- QUERY 1: Counts individual and store customers.
-- -----------------------------------------------------

-- SELECT
--     CustomerType,
--     COUNT(CustomerType) AS customerTypeCount
-- FROM CustomerSegmentationCTE
-- GROUP BY CustomerType

-- ===========================================================
-- QUERY 2: Calculates the customer retention from the total.
-- -----------------------------------------------------------
-- (example- Individual One-time buyer are 62% of the total Individual customers.)

-- SELECT
--     CustomerType,
--     CustomerRetention,
--     COUNT(*) AS CustomerCount,
--     ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER(PARTITION BY CustomerType), 2) AS PercentFromTotal
-- FROM CustomerSegmentationCTE
-- GROUP BY CustomerType, CustomerRetention
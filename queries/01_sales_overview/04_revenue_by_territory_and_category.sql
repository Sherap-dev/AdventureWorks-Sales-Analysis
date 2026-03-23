-- ========================================
-- Territory and Category Revenue Analysis
-- Dataset: Adventure Works 2022
-- ========================================
-- Business Questions:
-- 1. Which territories generate the most revenue 
--    for in-store and online channels?
-- 2. Which product categories drive the most revenue
--    across all territories?
-- 3. Which territories dominate sales for each 
--    product category?
-- 4. What is the top performing product category
--    per territory for both channels?
-- ========================================

WITH
    OnlineInStorePerTerritoryPerProductCategorySalesCTE AS(
        SELECT 
            st.TerritoryID,
            st.Name AS TerritoryName,
            st.CountryRegionCode,
            st.[Group],
            pc.ProductCategoryID,
            pc.Name AS CategoryName,
        CASE
            WHEN sh.OnlineOrderFlag = 1 THEN 'online'
            WHEN sh.OnlineOrderFlag = 0 THEN 'in-store'
        END AS OrderFlag,
            COUNT(DISTINCT sd.SalesOrderID) AS OrderCount,
            ROUND(SUM(sd.UnitPrice * sd.OrderQty * (1 - sd.UnitPriceDiscount)), 2)  AS TerritoryRevenue
        FROM Sales.SalesOrderHeader AS sh
        JOIN Sales.SalesOrderDetail AS sd
        ON sd.SalesOrderID = sh.SalesOrderID
        JOIN Sales.SalesTerritory AS st
        ON st.TerritoryID = sh.TerritoryID
        JOIN Production.Product AS p
        ON p.ProductID = sd.ProductID
        LEFT JOIN Production.ProductSubcategory AS ps
        ON ps.ProductSubcategoryID = p.ProductSubcategoryID
        LEFT JOIN Production.ProductCategory AS pc
        ON pc.ProductCategoryID = ps.ProductCategoryID
        GROUP BY 
            st.TerritoryID,
            st.Name,
            st.CountryRegionCode,
            st.[Group],
            pc.ProductCategoryID,
            pc.Name,
        CASE
            WHEN sh.OnlineOrderFlag = 1 THEN 'online'
            WHEN sh.OnlineOrderFlag = 0 THEN 'in-store'
        END
    ),
    TerritorySalesCTE AS(
        SELECT
            st.TerritoryID,
            st.Name,
            st.CountryRegionCode,
            st.[Group],
            CASE
                WHEN sh.OnlineOrderFlag = 1 THEN 'online'
                WHEN sh.OnlineOrderFlag = 0 THEN 'in-store'
            END AS OrderFlag,
            COUNT(distinct sh.SalesOrderID) AS TotalOrderCount,
            ROUND(SUM(sd.UnitPrice * sd.OrderQty *(1 - sd.UnitPriceDiscount)), 2) AS TotalRevenue
        FROM sales.SalesOrderHeader AS sh
        JOIN Sales.SalesOrderDetail AS sd
        ON sd.SalesOrderID = sh.SalesOrderID
        JOIN sales.SalesTerritory AS st
        ON st.TerritoryID = sh.TerritoryID
        GROUP BY 
            st.TerritoryID,
            st.Name,
            st.CountryRegionCode,
            st.[Group],
            CASE
                WHEN sh.OnlineOrderFlag = 1 THEN 'online'
                WHEN sh.OnlineOrderFlag = 0 THEN 'in-store'
            END
    )

-- ======================================================================
--     TERRITORY RANKING PER PRODUCT CATEGORY IN-STORE AND ONLINE.
-- ----------------------------------------------------------------------
-- QUERY 1. In-store Territory Ranking Per Product Category.
-- ----------------------------------------------------------------------
-- Findings: 
-- 1. In-store, the product categories being sold are Bikes, Components, Clothing and
--  Accessories.
-- 2. For Terrtories the North America Group namely the Southwest, Canada and Northwest
--  territories dominates in all product category becoming the top 3 territories that sells
--  the product from each category the most. 
--  While North America dominates, the Europe and Pacific territories consistently rank as the 
--  bottom 3 suggesting untapped market potential.

-- SELECT
--     *,
--     DENSE_RANK() OVER(PARTITION BY ProductCategoryID ORDER BY TerritoryRevenue DESC) AS TerritoryRankingPerProductCategory
-- FROM OnlineInStorePerTerritoryPerProductCategorySalesCTE
-- WHERE OrderFlag = 'in-store'

-- -----------------------------------------------------------
-- QUERY 2. Online Territory Ranking Per Product Category.
-- -----------------------------------------------------------
-- Findings: 
-- 1. Online, the product categories being sold are Bikes, Clothing, and Accessories. This signifies
--  Components are in-store only in-store sold items.
-- 2. Australia, Southwest and Northwest from the Pacific and North America Group respectively are the 
--  top 3 dominating territories accorss all online product categories, while Southeast, Northeast and Central
--  from the North America Group are the bottom 3 ranking territores. 

-- SELECT
--     *,
--     DENSE_RANK() OVER(PARTITION BY ProductCategoryID ORDER BY TerritoryRevenue DESC) AS TerritoryRankingPerProductCategory
-- FROM OnlineInStorePerTerritoryPerProductCategorySalesCTE
-- WHERE OrderFlag = 'online'


-- ======================================================================
--              TERRITORY RANKING IN-STORE AND ONLINE.
-- ======================================================================
-- QUERY 1: In-store Territory Ranking.
-- ----------------------------------------------------------------------
-- Findings:
-- 1. The North America Group namely the Southwest, Canada and Northwest are the top 3 in-store Territories.
--  The Europe And Pacific Group namely the United Kingdom, Germany and Australia respectively are the bottom 3
--  in-store territories.
-- 2. The Southwest territory leads the territory ranking with the highest total order count of 751 and total revenue of
--  approx. 18M with Canada following as the 2nd best territory with 692 total orders and total revenue of
--  approx. 14M.
-- 3. The bottom 3 territories had total order count less than 200 with United Kingdom with the most orders of 188 total
--  orders and approx. 4M in revenue. Australia was the worst performing with only 125 total orders and approx. 1M in revenue.

-- SELECT
--     *,
--     DENSE_RANK() OVER(ORDER BY TotalRevenue DESC) AS TerritoryRanking
-- FROM TerritorySalesCTE
-- WHERE OrderFlag = 'in-store'

-- ----------------------------------------------------------------------
-- QUERY 2: Online Territory Ranking.
-- ----------------------------------------------------------------------
-- Findings:
-- 1. The Pacific and North America Group namely Australia, Soouthwest and Northwest are the top 3 Online Territories.
--  The North American Territories namely the Southeast, Northeast and Central and the bottom 3 Online Territories.
-- 2. Australia comes on top as the best performing territory with 6718 total order count and approx. 9M in revenue.
-- Southwest territory from the North America group comes as the close second with 5473 total order count and approx. 
-- 5M in total revenue.
-- 3. From the bottom 3 territories Southeast had the most orders of 17 total orders and 12,238.85 in Total revenue.
-- Central was the worst performing online territory with just 9 orders and 3,000.83 in revenue.

-- SELECT
--     *,
--     DENSE_RANK() OVER(ORDER BY TotalRevenue DESC) AS TerritoryRanking
-- FROM TerritorySalesCTE
-- WHERE OrderFlag = 'online'


-- =======================================================================
--          TOP CATEGORY PER TERRITORY IN-STORE AND ONLINE.
-- =======================================================================
-- QUERY 1: Top Category In-store.
-- -----------------------------------------------------------------------
-- Findings:
-- 1. In-store, the categories being sold are Bikes, Components, Clothing and Accessories.
-- 2. Bkies was the Top Category accross all Territories with the total in-store bike orders of 3163, approx. 66M
--  of total revenue. Southwest had the most Bikes ordered with 653 orders and the highest revenue generated from Bikes
--  with 15M in revenue making Southwest the best Bikes selling Territory.
-- 3. Accessories was the worst performing categories accross all territories with 1316 total in-store orders and approx.
-- 5M in total revenue. 285 was the highest total order count coming from the Southwest territory with the highest 
-- revenue of 108,694.43. 

-- SELECT 
--     *,
--     DENSE_RANK() OVER(PARTITION BY TerritoryID ORDER BY TerritoryRevenue DESC) AS TopProductCategoryPerTerritory
-- FROM OnlineInStorePerTerritoryPerProductCategorySalesCTE
-- WHERE OrderFlag = 'in-store'


-- -----------------------------------------------------------------------
-- QUERY 2: Top Category Online.
-- -----------------------------------------------------------------------
-- Findings:
-- 1. Bikes was the Top Category accross all territories with 15,205 Total Orders and approx. 28M
--  in Total revenue. Clothing was the worst Category accross all territories with 7461 total orders and 
--  approx. 339,772.61 in total revenue.
-- 2. Australia was the best Online territory for Bikes with 4472 orders and 8M in revenue.
-- 3. Australia was the territory with the highest order for clothing with 1554 orders which generated 70259.95
--  in revenue while the territory with the lowest order for clothing was tied between Northeast and central
--  with 4 orders with 105.97 and 156.96 respectively in revenue.
-- 4. Accessories came on top for the highest order volume with the order count of 18208 orders beating Bkies
--  by 3003 orders. Despite Bikes generating significantly more revenue at approx. 28M vs Accessories 7M.
--  This confirms that high order volume is not equal to higher revenue.
-- 5. Northeast, Central and Southeast are the worst performing territories with order count hardly crossing 10
--  with 11,405.94 being the highes revenue, generated Southeast.

-- SELECT 
--     *,
--     DENSE_RANK() OVER(PARTITION BY TerritoryID ORDER BY TerritoryRevenue DESC) AS TopProductCategoryPerTerritory
-- FROM OnlineInStorePerTerritoryPerProductCategorySalesCTE
-- WHERE OrderFlag = 'online'


-- ---------------------------------------------------------
--                  HELPER QUERIES
-- ---------------------------------------------------------
-- 1. Total orders online/in-store
-- SELECT
--     CategoryName,
--     SUM(OrderCount) AS TotalOrders
-- FROM OnlineInStorePerTerritoryPerProductCategorySalesCTE
-- WHERE OrderFlag = 'online' <==(CHANGE TO 'in-store' TO CHECK THE TOTAL IN-STORE ORDER COUNT)
-- GROUP BY CategoryName
-- ORDER BY TotalOrders DESC

-- 2. Total revenue online/in-store
-- SELECT
--     CategoryName,
--     SUM(TerritoryRevenue) AS TotalRevenue
-- FROM OnlineInStorePerTerritoryPerProductCategorySalesCTE
-- WHERE OrderFlag = 'online' <==(CHANGE TO 'in-store' TO CHECK THE TOTAL IN-STORE REVENUE)
-- GROUP BY CategoryName
-- ORDER BY TotalOrders DESC
WITH
    OnlineInStorePerTerritoryPerProductCategorySalesCTE AS(
        SELECT 
            st.TerritoryID,
            st.Name,
            st.CountryRegionCode,
            st.[Group],
            pc.ProductCategoryID,
            pc.Name AS CategoryName,
        CASE
            WHEN sh.OnlineOrderFlag = 1 THEN 'online'
            WHEN sh.OnlineOrderFlag = 0 THEN 'in-store'
        END AS OrderFlag,
            COUNT(DISTINCT sd.SalesOrderID) AS OrderCountPerTerritoryPerProductCategory,
            ROUND(SUM(sd.UnitPrice * sd.OrderQty * (1 - sd.UnitPriceDiscount)), 2)  AS TerritoryRevenuePerMonth
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
            COUNT(distinct sh.SalesOrderID) ordercount,
            SUM(sd.UnitPrice * sd.OrderQty *(1 - sd.UnitPriceDiscount)) AS TotalTerritoryRevenue
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


SELECT
    *,
    DENSE_RANK() OVER(PARTITION BY ProductCategoryID ORDER BY TerritoryRevenuePerMonth DESC) CategoryRankingPerTerritory
FROM OnlineInStorePerTerritoryPerProductCategorySalesCTE
WHERE OrderFlag = 'in-store'


-- SELECT
--     *,
--     DENSE_RANK() OVER(PARTITION BY ProductCategoryID ORDER BY TerritoryRevenuePerMonth DESC) CategoryRankingInTerritory
-- FROM OnlineInStorePerTerritoryPerProductCategorySalesCTE
-- WHERE OrderFlag = 'online'


-- SELECT
--     *,
--     DENSE_RANK() OVER(ORDER BY TotalTerritoryRevenue DESC) AS TerritoryRanking
-- FROM TerritorySalesCTE
-- WHERE OrderFlag = 'in-store'


-- SELECT
--     *,
--     DENSE_RANK() OVER(ORDER BY TotalTerritoryRevenue DESC) AS TerritoryRanking
-- FROM TerritorySalesCTE
-- WHERE OrderFlag = 'online'
























    


SELECT * FROM Production.Product;
select * FROM Production.ProductModel
SELECT * FROM Production.Productcategory;
SELECT * FROM Production.Productcategory
SELECT * FROM Sales.SalesOrderDetail
SELECT * from sales.SalesOrderHeader
SELECT * from Purchasing.PurchaseOrderDetail
SELECT * FROM Sales.Customer
SELECT * from Sales.Store
SELECT * FROM sales.SalesTerritory






 DENSE_RANK() OVER(PARTITION BY OrderFlag ORDER BY SUM(sd.UnitPrice * sd.OrderQty *(1 - sd.UnitPriceDiscount)) DESC) AS TerritoryRanking









































































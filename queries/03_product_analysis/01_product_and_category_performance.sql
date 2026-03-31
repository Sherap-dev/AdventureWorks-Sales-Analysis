WITH 
    BaseProductCTE AS(
    SELECT
        pg.ProductCategoryID,
        pg.Name AS Category,
        ps.ProductSubcategoryID,
        ps.Name AS SubCategory,
        p.ProductID,
        p.Name AS ProductName,
        SUM(od.OrderQty) AS OrderQuantity,
        ROUND(SUM(od.UnitPrice * od.OrderQty * (1 - od.UnitPriceDiscount)), 2)  AS ProductSales
    FROM Production.Product AS p
    JOIN Production.ProductSubcategory AS ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    JOIN Production.ProductCategory AS pg
    ON pg.ProductCategoryID = ps.ProductCategoryID
    JOIN Sales.SalesOrderDetail AS od
    ON od.ProductID = p.ProductID
    GROUP BY
        pg.ProductCategoryID,
        pg.Name,
        ps.ProductSubcategoryID,
        ps.Name,
        p.ProductID,
        p.Name
), 
CategoryCTE AS(
    SELECT
        ProductCategoryID,
        Category,
        SUM(OrderQuantity) AS TotalUnitsSold,
        SUM(ProductSales) AS CategorySales
    FROM BaseProductCTE
    GROUP BY ProductCategoryID, Category
),
SubCategoryCTE AS(
    SELECT
        ProductCategoryID,
        Category,
        ProductSubcategoryID,
        SubCategory,
        SUM(OrderQuantity) AS UnitsSold,
        SUM(ProductSales) AS SubCategorySales
    FROM BaseProductCTE
    GROUP BY 
        ProductCategoryID,
        Category,
        ProductSubcategoryID,
        SubCategory
)       

-- SELECT
--     *,
--     DENSE_RANK() OVER(ORDER BY CategorySales DESC) AS CategoryRanking,
--     ROUND(CategorySales * 100.0 / SUM(CategorySales) OVER(), 2) AS ContributionPercentage
-- FROM categoryCTE
-- ORDER BY CategorySales DESC

-- SELECT
--     *,
--     DENSE_RANK() OVER(PARTITION BY Category ORDER BY SubCategorySales DESC) AS SubCategoryRanking
-- FROM SubCategoryCTE
-- ORDER BY Category, SubCategorySales DESC

-- SELECT
--     *,
--     DENSE_RANK() OVER(PARTITION BY SubCategory ORDER BY ProductSales DESC) AS SubCategoryRanking
-- FROM BaseProductCTE
-- ORDER BY Category, SubCategory, ProductSales DESC

















WITH ProductTrendBaseCTE AS(
    SELECT
        pg.ProductCategoryID,
        pg.Name AS Category,
        ps.ProductSubcategoryID,
        ps.Name AS SubCategory,
        p.ProductID,
        p.Name AS ProductName,
        COUNT(DISTINCT oh.SalesOrderID) AS ProductOrderCount,
        DATETRUNC(MONTH, oh.OrderDate) AS OrderMonth,
        SUM(od.OrderQty) AS OrderQuantity,
        ROUND(SUM(od.UnitPrice * od.OrderQty * (1 - od.UnitPriceDiscount)), 2)  AS ProductSales
    FROM Production.Product AS p
    JOIN Production.ProductSubcategory AS ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    JOIN Production.ProductCategory AS pg
    ON pg.ProductCategoryID = ps.ProductCategoryID
    JOIN Sales.SalesOrderDetail AS od
    ON od.ProductID = p.ProductID
    JOIN Sales.SalesOrderHeader AS oh
    ON oh.SalesOrderID = od.SalesOrderID
    GROUP BY
        pg.ProductCategoryID,
        pg.Name,
        ps.ProductSubcategoryID,
        ps.Name,
        p.ProductID,
        p.Name,
        DATETRUNC(MONTH, oh.OrderDate)
),
BaseProductCategoryCTE AS(
    SELECT
        ProductCategoryID AS CategoryId,
        Category,
        OrderMonth,
        SUM(ProductOrderCount) AS TotalOrderCountPerCategory,
        SUM(OrderQuantity) AS TotalUnitsSold,
        SUM(ProductSales) AS MonthlyCategorySales
    FROM ProductTrendBaseCTE
    GROUP BY ProductCategoryID, Category, OrderMonth
),
BaseProductCategoryMoMTrendCTE AS(
    SELECT 
        *,
        LAG(MonthlyCategorySales, 1) OVER(PARTITION BY CategoryId ORDER BY OrderMonth) AS PreviousMonthSales
    FROM BaseProductCategoryCTE
),
CategoryMoMTrendCTE AS(
    SELECT
        *,
        MonthlyCategorySales - PreviousMonthSales AS MoMChange,
        ROUND((MonthlyCategorySales - PreviousMonthSales) / PreviousMonthSales * 100, 2) AS MoMchangePercent,
        AVG(MonthlyCategorySales) OVER(PARTITION BY CategoryId ORDER BY OrderMonth ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS RollingAvg
    FROM BaseProductCategoryMoMTrendCTE
)

SELECT *
from CategoryMoMTrendCTE


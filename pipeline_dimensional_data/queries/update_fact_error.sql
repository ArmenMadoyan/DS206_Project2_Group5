DECLARE @DatabaseName NVARCHAR(255) = 'ORDER_DDS';
DECLARE @SchemaName NVARCHAR(255) = 'dbo';
DECLARE @FactErrorTableName NVARCHAR(255) = 'FactOrdersError';

DECLARE @OrdersTable NVARCHAR(255) = 'staging_raw_orders';
DECLARE @OrderDetailsTable NVARCHAR(255) = 'staging_raw_order_details';

DECLARE @StartDate DATE = '{StartDate}';
DECLARE @EndDate DATE = '{EndDate}';

DECLARE @SQL NVARCHAR(MAX);

SET @SQL = N'

INSERT INTO ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@FactErrorTableName) + N' (

    order_id_nk,
    product_id_nk,

    customer_id_nk,
    employee_id_nk,
    shipper_id_nk,
    territory_id_nk,

    order_date,
    required_date,
    shipped_date,

    unit_price,
    quantity,
    discount,
    freight,

    error_reason,

    snapshot_date,

    sor_sk_orders,
    staging_raw_id_orders,

    sor_sk_details,
    staging_raw_id_details

)

SELECT

    o.OrderID,
    od.ProductID,

    o.CustomerID,
    o.EmployeeID,
    o.ShipVia,
    o.TerritoryID,

    o.OrderDate,
    o.RequiredDate,
    o.ShippedDate,

    od.UnitPrice,
    od.Quantity,
    od.Discount,

    o.Freight,

    CASE
        WHEN dc.customer_sk IS NULL THEN ''Missing Customer Key''
        WHEN de.employee_sk IS NULL THEN ''Missing Employee Key''
        WHEN dp.product_sk IS NULL THEN ''Missing Product Key''
        WHEN ds.shipper_sk IS NULL THEN ''Missing Shipper Key''
        WHEN dt.territory_sk IS NULL THEN ''Missing Territory Key''
        ELSE ''Unknown Error''
    END,

    CAST(GETDATE() AS DATE),

    sor_orders.SOR_SK,
    o.staging_raw_id_sk,

    sor_details.SOR_SK,
    od.staging_raw_id_sk

FROM ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@OrdersTable) + N' o

INNER JOIN ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@OrderDetailsTable) + N' od
    ON o.OrderID = od.OrderID

LEFT JOIN ' + QUOTENAME(@SchemaName) + N'.DimCustomers dc
    ON dc.customer_id_nk = o.CustomerID
    AND dc.is_current = 1

LEFT JOIN ' + QUOTENAME(@SchemaName) + N'.DimEmployees de
    ON de.employee_id_nk = o.EmployeeID

LEFT JOIN ' + QUOTENAME(@SchemaName) + N'.DimProducts dp
    ON dp.product_id_nk = od.ProductID
    AND dp.is_current = 1

LEFT JOIN ' + QUOTENAME(@SchemaName) + N'.DimShippers ds
    ON ds.shipper_id_nk = o.ShipVia

LEFT JOIN ' + QUOTENAME(@SchemaName) + N'.DimTerritories dt
    ON dt.territory_id_nk = o.TerritoryID

JOIN ' + QUOTENAME(@SchemaName) + N'.Dim_SOR sor_orders
    ON sor_orders.Staging_Table_Name = ''staging_raw_orders''

JOIN ' + QUOTENAME(@SchemaName) + N'.Dim_SOR sor_details
    ON sor_details.Staging_Table_Name = ''staging_raw_order_details''

WHERE o.OrderDate BETWEEN @StartDate AND @EndDate

AND (
       dc.customer_sk IS NULL
    OR de.employee_sk IS NULL
    OR dp.product_sk IS NULL
    OR ds.shipper_sk IS NULL
    OR dt.territory_sk IS NULL
);

';

EXEC sp_executesql
    @SQL,
    N'@StartDate DATE, @EndDate DATE',
    @StartDate,
    @EndDate;
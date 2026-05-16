DECLARE @DatabaseName NVARCHAR(255) = 'ORDER_DDS';
DECLARE @SchemaName NVARCHAR(255) = 'dbo';
DECLARE @FactTableName NVARCHAR(255) = 'FactOrders';

DECLARE @OrdersTable NVARCHAR(255) = 'staging_raw_orders';
DECLARE @OrderDetailsTable NVARCHAR(255) = 'staging_raw_order_details';

DECLARE @SQL NVARCHAR(MAX);

SET @SQL = N'

MERGE ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@FactTableName) + N' AS Target

USING (

    SELECT
        o.OrderID,
        od.ProductID,

        dc.customer_sk,
        de.employee_sk,
        dp.product_sk,

        od.Quantity,
        od.UnitPrice,
        od.Discount,

        o.Freight,

        CAST(GETDATE() AS DATE) AS snapshot_date,

        sor_orders.SOR_SK AS sor_sk_orders,
        o.staging_raw_id_sk AS staging_raw_id_orders,

        sor_details.SOR_SK AS sor_sk_details,
        od.staging_raw_id_sk AS staging_raw_id_details

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

    JOIN ' + QUOTENAME(@SchemaName) + N'.Dim_SOR sor_orders
        ON sor_orders.Staging_Table_Name = ''staging_raw_orders''

    JOIN ' + QUOTENAME(@SchemaName) + N'.Dim_SOR sor_details
        ON sor_details.Staging_Table_Name = ''staging_raw_order_details''

) AS Source

ON Target.order_id_nk = Source.OrderID
AND Target.product_id_nk = Source.ProductID
AND Target.snapshot_date = Source.snapshot_date

WHEN MATCHED THEN

UPDATE SET

    customer_sk = Source.customer_sk,
    employee_sk = Source.employee_sk,
    product_sk = Source.product_sk,

    quantity = Source.Quantity,
    unit_price = Source.UnitPrice,
    discount = Source.Discount,
    freight = Source.Freight,

    sor_sk_orders = Source.sor_sk_orders,
    staging_raw_id_orders = Source.staging_raw_id_orders,

    sor_sk_details = Source.sor_sk_details,
    staging_raw_id_details = Source.staging_raw_id_details

WHEN NOT MATCHED THEN

INSERT (

    order_id_nk,
    product_id_nk,

    customer_sk,
    employee_sk,
    product_sk,

    quantity,
    unit_price,
    discount,
    freight,

    snapshot_date,

    sor_sk_orders,
    staging_raw_id_orders,

    sor_sk_details,
    staging_raw_id_details

)

VALUES (

    Source.OrderID,
    Source.ProductID,

    Source.customer_sk,
    Source.employee_sk,
    Source.product_sk,

    Source.Quantity,
    Source.UnitPrice,
    Source.Discount,
    Source.Freight,

    Source.snapshot_date,

    Source.sor_sk_orders,
    Source.staging_raw_id_orders,

    Source.sor_sk_details,
    Source.staging_raw_id_details

);

';

EXEC sp_executesql @SQL;
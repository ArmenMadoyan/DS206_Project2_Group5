MERGE dbo.DimProducts AS target
USING (
    SELECT
        s.*,
        sor.SOR_SK
    FROM dbo.staging_raw_products s
    JOIN dbo.Dim_SOR sor
        ON sor.Staging_Table_Name = 'staging_raw_products'
) AS source
ON target.product_id_nk = source.ProductID
AND target.is_current = 1

WHEN MATCHED AND (
       ISNULL(target.product_name,'') <> ISNULL(source.ProductName,'')
    OR ISNULL(target.unit_price,0) <> ISNULL(source.UnitPrice,0)
)
THEN
UPDATE SET
    expiration_date = GETDATE(),
    is_current = 0

WHEN NOT MATCHED BY TARGET
THEN
INSERT (
    product_id_nk,
    product_name,
    supplier_id_nk,
    category_id_nk,
    quantity_per_unit,
    unit_price,
    units_in_stock,
    units_on_order,
    reorder_level,
    discontinued,
    effective_date,
    expiration_date,
    is_current,
    is_deleted,
    sor_sk,
    staging_raw_id_nk
)
VALUES (
    source.ProductID,
    source.ProductName,
    source.SupplierID,
    source.CategoryID,
    source.QuantityPerUnit,
    source.UnitPrice,
    source.UnitsInStock,
    source.UnitsOnOrder,
    source.ReorderLevel,
    source.Discontinued,
    GETDATE(),
    NULL,
    1,
    0,
    source.SOR_SK,
    source.staging_raw_id_sk
);
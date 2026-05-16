MERGE dbo.DimCategories AS target
USING (
    SELECT
        s.*,
        sor.SOR_SK
    FROM dbo.staging_raw_categories s
    JOIN dbo.Dim_SOR sor
        ON sor.Staging_Table_Name = 'staging_raw_categories'
) AS source
ON target.category_id_nk = source.CategoryID

WHEN MATCHED THEN
UPDATE SET
    category_name = source.CategoryName,
    description = source.Description

WHEN NOT MATCHED THEN
INSERT (
    category_id_nk,
    category_name,
    description,
    sor_sk,
    staging_raw_id_nk
)
VALUES (
    source.CategoryID,
    source.CategoryName,
    source.Description,
    source.SOR_SK,
    source.staging_raw_id_sk
);


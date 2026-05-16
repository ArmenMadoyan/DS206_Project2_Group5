MERGE dbo.DimShippers AS target
USING (
    SELECT
        s.*,
        sor.SOR_SK
    FROM dbo.staging_raw_shippers s
    JOIN dbo.Dim_SOR sor
        ON sor.Staging_Table_Name = 'staging_raw_shippers'
) AS source
ON target.shipper_id_nk = source.ShipperID

WHEN MATCHED THEN
UPDATE SET
    company_name = source.CompanyName,
    phone = source.Phone,
    is_deleted = 0

WHEN NOT MATCHED THEN
INSERT (
    shipper_id_nk,
    company_name,
    phone,
    is_deleted,
    sor_sk,
    staging_raw_id_nk
)
VALUES (
    source.ShipperID,
    source.CompanyName,
    source.Phone,
    0,
    source.SOR_SK,
    source.staging_raw_id_sk
);
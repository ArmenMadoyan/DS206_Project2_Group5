MERGE dbo.DimTerritories AS target
USING (
    SELECT
        s.*,
        sor.SOR_SK
    FROM dbo.staging_raw_territories s
    JOIN dbo.Dim_SOR sor
        ON sor.Staging_Table_Name = 'staging_raw_territories'
) AS source
ON target.territory_id_nk = source.TerritoryID

WHEN MATCHED THEN
UPDATE SET
    territory_description = source.TerritoryDescription,
    territory_code = source.TerritoryCode,
    region_id_nk = source.RegionID

WHEN NOT MATCHED THEN
INSERT (
    territory_id_nk,
    territory_description,
    territory_code,
    region_id_nk,
    sor_sk,
    staging_raw_id_nk
)
VALUES (
    source.TerritoryID,
    source.TerritoryDescription,
    source.TerritoryCode,
    source.RegionID,
    source.SOR_SK,
    source.staging_raw_id_sk
);
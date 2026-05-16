-- DimTerritories = SCD4 for Group 5.
-- Step 1: snapshot any DimTerritories rows whose tracked attributes are about to
--         change into DimTerritoriesHistory (close out the old version).
-- Step 2: MERGE staging into DimTerritories (overwrite current row + insert new).

INSERT INTO dbo.DimTerritoriesHistory (
    territory_id_nk,
    territory_description,
    territory_code,
    region_id_nk,
    valid_to,
    is_current,
    sor_sk,
    staging_raw_id_nk
)
SELECT
    dt.territory_id_nk,
    dt.territory_description,
    dt.territory_code,
    dt.region_id_nk,
    SYSUTCDATETIME(),
    0,
    dt.sor_sk,
    dt.staging_raw_id_nk
FROM dbo.DimTerritories dt
JOIN dbo.staging_raw_territories s
    ON dt.territory_id_nk = s.TerritoryID
WHERE
       ISNULL(dt.territory_description,'') <> ISNULL(s.TerritoryDescription,'')
    OR ISNULL(dt.territory_code,'')        <> ISNULL(s.TerritoryCode,'')
    OR ISNULL(dt.region_id_nk, -1)         <> ISNULL(s.RegionID, -1);


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
    territory_code        = source.TerritoryCode,
    region_id_nk          = source.RegionID

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

-- DimRegion = SCD4 for Group 5.
-- Step 1: snapshot any DimRegion rows whose tracked attributes are about to change
--         into DimRegionHistory (close out the old version).
-- Step 2: MERGE staging into DimRegion (overwrite current row + insert new).

INSERT INTO dbo.DimRegionHistory (
    region_id_nk,
    region_description,
    region_category,
    region_importance,
    valid_to,
    is_current,
    sor_sk,
    staging_raw_id_nk
)
SELECT
    dr.region_id_nk,
    dr.region_description,
    dr.region_category,
    dr.region_importance,
    SYSUTCDATETIME(),
    0,
    dr.sor_sk,
    dr.staging_raw_id_nk
FROM dbo.DimRegion dr
JOIN dbo.staging_raw_region s
    ON dr.region_id_nk = s.RegionID
WHERE
       ISNULL(dr.region_description,'') <> ISNULL(s.RegionDescription,'')
    OR ISNULL(dr.region_category,'')    <> ISNULL(s.RegionCategory,'')
    OR ISNULL(dr.region_importance,'')  <> ISNULL(s.RegionImportance,'');


MERGE dbo.DimRegion AS target
USING (
    SELECT
        s.*,
        sor.SOR_SK
    FROM dbo.staging_raw_region s
    JOIN dbo.Dim_SOR sor
        ON sor.Staging_Table_Name = 'staging_raw_region'
) AS source
ON target.region_id_nk = source.RegionID

WHEN MATCHED THEN
UPDATE SET
    region_description = source.RegionDescription,
    region_category    = source.RegionCategory,
    region_importance  = source.RegionImportance

WHEN NOT MATCHED THEN
INSERT (
    region_id_nk,
    region_description,
    region_category,
    region_importance,
    sor_sk,
    staging_raw_id_nk
)
VALUES (
    source.RegionID,
    source.RegionDescription,
    source.RegionCategory,
    source.RegionImportance,
    source.SOR_SK,
    source.staging_raw_id_sk
);

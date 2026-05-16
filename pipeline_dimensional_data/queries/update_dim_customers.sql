MERGE dbo.DimCustomers AS target
USING (
    SELECT
        s.*,
        sor.SOR_SK
    FROM dbo.staging_raw_customers s
    JOIN dbo.Dim_SOR sor
        ON sor.Staging_Table_Name = 'staging_raw_customers'
) AS source
ON target.customer_id_nk = source.CustomerID
AND target.is_current = 1

WHEN MATCHED AND (
       ISNULL(target.company_name,'') <> ISNULL(source.CompanyName,'')
    OR ISNULL(target.contact_name,'') <> ISNULL(source.ContactName,'')
    OR ISNULL(target.city,'') <> ISNULL(source.City,'')
    OR ISNULL(target.country,'') <> ISNULL(source.Country,'')
)
THEN
UPDATE SET
    expiration_date = GETDATE(),
    is_current = 0

WHEN NOT MATCHED BY TARGET
THEN
INSERT (
    customer_id_nk,
    company_name,
    contact_name,
    contact_title,
    address,
    city,
    region,
    postal_code,
    country,
    phone,
    fax,
    effective_date,
    expiration_date,
    is_current,
    sor_sk,
    staging_raw_id_nk
)
VALUES (
    source.CustomerID,
    source.CompanyName,
    source.ContactName,
    source.ContactTitle,
    source.Address,
    source.City,
    source.Region,
    source.PostalCode,
    source.Country,
    source.Phone,
    source.Fax,
    GETDATE(),
    NULL,
    1,
    source.SOR_SK,
    source.staging_raw_id_sk
);
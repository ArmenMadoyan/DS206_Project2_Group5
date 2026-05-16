MERGE dbo.DimSuppliers AS target
USING (
    SELECT
        s.*,
        sor.SOR_SK
    FROM dbo.staging_raw_suppliers s
    JOIN dbo.Dim_SOR sor
        ON sor.Staging_Table_Name = 'staging_raw_suppliers'
) AS source
ON target.supplier_id_nk = source.SupplierID

WHEN MATCHED THEN
UPDATE SET
    company_name = source.CompanyName,
    contact_name = source.ContactName,
    contact_title = source.ContactTitle,
    address = source.Address,
    city = source.City,
    region = source.Region,
    postal_code = source.PostalCode,
    country = source.Country,
    phone = source.Phone,
    fax = source.Fax,
    home_page = source.HomePage

WHEN NOT MATCHED THEN
INSERT (
    supplier_id_nk,
    company_name,
    contact_name,
    contact_title,
    address,
    city,
    region,
    postal_code,
    country,
    previous_country,
    country_changed_at,
    phone,
    fax,
    home_page,
    sor_sk,
    staging_raw_id_nk
)
VALUES (
    source.SupplierID,
    source.CompanyName,
    source.ContactName,
    source.ContactTitle,
    source.Address,
    source.City,
    source.Region,
    source.PostalCode,
    source.Country,
    NULL,
    NULL,
    source.Phone,
    source.Fax,
    source.HomePage,
    source.SOR_SK,
    source.staging_raw_id_sk
);
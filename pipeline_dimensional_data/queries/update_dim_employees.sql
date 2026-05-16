MERGE dbo.DimEmployees AS target
USING (
    SELECT
        s.*,
        sor.SOR_SK
    FROM dbo.staging_raw_employees s
    JOIN dbo.Dim_SOR sor
        ON sor.Staging_Table_Name = 'staging_raw_employees'
) AS source
ON target.employee_id_nk = source.EmployeeID

WHEN MATCHED THEN
UPDATE SET
    last_name = source.LastName,
    first_name = source.FirstName,
    title = source.Title,
    title_of_courtesy = source.TitleOfCourtesy,
    birth_date = source.BirthDate,
    hire_date = source.HireDate,
    address = source.Address,
    city = source.City,
    region = source.Region,
    postal_code = source.PostalCode,
    country = source.Country,
    home_phone = source.HomePhone,
    extension = source.Extension,
    notes = source.Notes,
    reports_to = source.ReportsTo,
    photo_path = source.PhotoPath,
    is_deleted = 0

WHEN NOT MATCHED THEN
INSERT (
    employee_id_nk,
    last_name,
    first_name,
    title,
    title_of_courtesy,
    birth_date,
    hire_date,
    address,
    city,
    region,
    postal_code,
    country,
    home_phone,
    extension,
    notes,
    reports_to,
    photo_path,
    is_deleted,
    sor_sk,
    staging_raw_id_nk
)
VALUES (
    source.EmployeeID,
    source.LastName,
    source.FirstName,
    source.Title,
    source.TitleOfCourtesy,
    source.BirthDate,
    source.HireDate,
    source.Address,
    source.City,
    source.Region,
    source.PostalCode,
    source.Country,
    source.HomePhone,
    source.Extension,
    source.Notes,
    source.ReportsTo,
    source.PhotoPath,
    0,
    source.SOR_SK,
    source.staging_raw_id_sk
);
USE ORDER_DDS;

CREATE TABLE Dim_SOR (
    SOR_SK INT IDENTITY(1,1) PRIMARY KEY,
    Staging_Table_Name NVARCHAR(255) NOT NULL UNIQUE
);


INSERT INTO Dim_SOR (Staging_Table_Name) VALUES
    ('staging_raw_categories'),
    ('staging_raw_customers'),
    ('staging_raw_employees'),
    ('staging_raw_order_details'),
    ('staging_raw_orders'),
    ('staging_raw_products'),
    ('staging_raw_region'),
    ('staging_raw_shippers'),
    ('staging_raw_suppliers'),
    ('staging_raw_territories');


CREATE TABLE DimCategories (
    category_sk INT IDENTITY(1,1) PRIMARY KEY,
    category_id_nk INT NOT NULL,
    category_name NVARCHAR(100),
    description NVARCHAR(MAX),
    sor_sk INT NOT NULL,
    staging_raw_id_nk INT NOT NULL,
    CONSTRAINT uq_dimcategories_nk UNIQUE (category_id_nk),
    CONSTRAINT fk_dimcategories_sor FOREIGN KEY (sor_sk) REFERENCES Dim_SOR(SOR_SK)
);


CREATE TABLE DimCustomers (
    customer_sk INT IDENTITY(1,1) PRIMARY KEY,
    customer_id_nk NVARCHAR(10) NOT NULL,
    company_name NVARCHAR(100),
    contact_name NVARCHAR(100),
    contact_title NVARCHAR(100),
    address NVARCHAR(255),
    city NVARCHAR(100),
    region NVARCHAR(100),
    postal_code NVARCHAR(20),
    country NVARCHAR(100),
    phone NVARCHAR(30),
    fax NVARCHAR(30),
    effective_date DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
    expiration_date DATETIME2(0) NULL,
    is_current BIT NOT NULL DEFAULT 1,
    sor_sk INT NOT NULL,
    staging_raw_id_nk INT NOT NULL,
    CONSTRAINT fk_dimcustomers_sor FOREIGN KEY (sor_sk) REFERENCES Dim_SOR(SOR_SK)
);


CREATE NONCLUSTERED INDEX ix_dimcustomers_nk_current
    ON DimCustomers (customer_id_nk, is_current);


CREATE TABLE DimEmployees (
    employee_sk INT IDENTITY(1,1) PRIMARY KEY,
    employee_id_nk INT NOT NULL,
    last_name NVARCHAR(100),
    first_name NVARCHAR(100),
    title NVARCHAR(100),
    title_of_courtesy NVARCHAR(50),
    birth_date DATETIME2(0),
    hire_date DATETIME2(0),
    address NVARCHAR(255),
    city NVARCHAR(100),
    region NVARCHAR(100),
    postal_code NVARCHAR(20),
    country NVARCHAR(100),
    home_phone NVARCHAR(30),
    extension NVARCHAR(10),
    notes NVARCHAR(MAX),
    reports_to INT,
    photo_path NVARCHAR(255),
    is_deleted BIT NOT NULL DEFAULT 0,
    sor_sk INT NOT NULL,
    staging_raw_id_nk INT NOT NULL,
    CONSTRAINT uq_dimemployees_nk UNIQUE (employee_id_nk),
    CONSTRAINT fk_dimemployees_sor FOREIGN KEY (sor_sk) REFERENCES Dim_SOR(SOR_SK)
);


CREATE TABLE DimProducts (
    product_sk INT IDENTITY(1,1) PRIMARY KEY,
    product_id_nk INT NOT NULL,
    product_name NVARCHAR(100),
    supplier_id_nk INT,
    category_id_nk INT,
    quantity_per_unit NVARCHAR(100),
    unit_price DECIMAL(19,4),
    units_in_stock SMALLINT,
    units_on_order SMALLINT,
    reorder_level SMALLINT,
    discontinued BIT,
    effective_date DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
    expiration_date DATETIME2(0) NULL,
    is_current BIT NOT NULL DEFAULT 1,
    is_deleted BIT NOT NULL DEFAULT 0,
    sor_sk INT NOT NULL,
    staging_raw_id_nk INT NOT NULL,
    CONSTRAINT fk_dimproducts_sor FOREIGN KEY (sor_sk) REFERENCES Dim_SOR(SOR_SK)
);


CREATE NONCLUSTERED INDEX ix_dimproducts_nk_current
    ON DimProducts (product_id_nk, is_current);


CREATE TABLE DimRegion (
    region_sk INT IDENTITY(1,1) PRIMARY KEY,
    region_id_nk INT NOT NULL,
    region_description NVARCHAR(100),
    region_category NVARCHAR(100),
    region_importance NVARCHAR(100),
    sor_sk INT NOT NULL,
    staging_raw_id_nk INT NOT NULL,
    CONSTRAINT uq_dimregion_nk UNIQUE (region_id_nk),
    CONSTRAINT fk_dimregion_sor FOREIGN KEY (sor_sk) REFERENCES Dim_SOR(SOR_SK)
);


CREATE TABLE DimRegionHistory (
    region_history_sk INT IDENTITY(1,1) PRIMARY KEY,
    region_id_nk INT NOT NULL,
    region_description NVARCHAR(100),
    region_category NVARCHAR(100),
    region_importance NVARCHAR(100),
    valid_from DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
    valid_to DATETIME2(0) NULL,
    is_current BIT NOT NULL DEFAULT 1,
    sor_sk INT NOT NULL,
    staging_raw_id_nk INT NOT NULL,
    CONSTRAINT fk_dimregionhistory_sor FOREIGN KEY (sor_sk) REFERENCES Dim_SOR(SOR_SK)
);


CREATE TABLE DimShippers (
    shipper_sk INT IDENTITY(1,1) PRIMARY KEY,
    shipper_id_nk INT NOT NULL,
    company_name NVARCHAR(100),
    phone NVARCHAR(30),
    is_deleted BIT NOT NULL DEFAULT 0,
    sor_sk INT NOT NULL,
    staging_raw_id_nk INT NOT NULL,
    CONSTRAINT uq_dimshippers_nk UNIQUE (shipper_id_nk),
    CONSTRAINT fk_dimshippers_sor FOREIGN KEY (sor_sk) REFERENCES Dim_SOR(SOR_SK)
);


CREATE TABLE DimSuppliers (
    supplier_sk INT IDENTITY(1,1) PRIMARY KEY,
    supplier_id_nk INT NOT NULL,
    company_name NVARCHAR(100),
    contact_name NVARCHAR(100),
    contact_title NVARCHAR(100),
    address NVARCHAR(255),
    city NVARCHAR(100),
    region NVARCHAR(100),
    postal_code NVARCHAR(20),
    country NVARCHAR(100),
    previous_country NVARCHAR(100) NULL,
    country_changed_at DATETIME2(0) NULL,
    phone NVARCHAR(30),
    fax NVARCHAR(30),
    home_page NVARCHAR(MAX),
    sor_sk INT NOT NULL,
    staging_raw_id_nk INT NOT NULL,
    CONSTRAINT uq_dimsuppliers_nk UNIQUE (supplier_id_nk),
    CONSTRAINT fk_dimsuppliers_sor FOREIGN KEY (sor_sk) REFERENCES Dim_SOR(SOR_SK)
);


CREATE TABLE DimTerritories (
    territory_sk INT IDENTITY(1,1) PRIMARY KEY,
    territory_id_nk INT NOT NULL,
    territory_description NVARCHAR(100),
    territory_code NVARCHAR(20),
    region_id_nk INT,
    sor_sk INT NOT NULL,
    staging_raw_id_nk INT NOT NULL,
    CONSTRAINT uq_dimterritories_nk UNIQUE (territory_id_nk),
    CONSTRAINT fk_dimterritories_sor FOREIGN KEY (sor_sk) REFERENCES Dim_SOR(SOR_SK)
);


CREATE TABLE DimTerritoriesHistory (
    territory_history_sk INT IDENTITY(1,1) PRIMARY KEY,
    territory_id_nk INT NOT NULL,
    territory_description NVARCHAR(100),
    territory_code NVARCHAR(20),
    region_id_nk INT,
    valid_from DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
    valid_to DATETIME2(0) NULL,
    is_current BIT NOT NULL DEFAULT 1,
    sor_sk INT NOT NULL,
    staging_raw_id_nk INT NOT NULL,
    CONSTRAINT fk_dimterritorieshistory_sor FOREIGN KEY (sor_sk) REFERENCES Dim_SOR(SOR_SK)
);


CREATE TABLE FactOrders (
    fact_order_sk BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id_nk INT NOT NULL,
    product_id_nk INT NOT NULL,
    customer_sk INT,
    employee_sk INT,
    product_sk INT,
    shipper_sk INT,
    territory_sk INT,
    order_date DATE,
    required_date DATE,
    shipped_date DATE,
    quantity SMALLINT,
    unit_price DECIMAL(19,4),
    discount DECIMAL(5,4),
    freight DECIMAL(19,4),
    sales_amount AS (CAST(unit_price * quantity * (1 - ISNULL(discount,0)) AS DECIMAL(19,4))) PERSISTED,
    snapshot_date DATE NOT NULL,
    sor_sk_orders INT NOT NULL,
    staging_raw_id_orders INT NOT NULL,
    sor_sk_details INT NOT NULL,
    staging_raw_id_details INT NOT NULL,
    CONSTRAINT uq_factorders_snapshot UNIQUE (order_id_nk, product_id_nk, snapshot_date),
    CONSTRAINT fk_factorders_customer  FOREIGN KEY (customer_sk)  REFERENCES DimCustomers(customer_sk),
    CONSTRAINT fk_factorders_employee  FOREIGN KEY (employee_sk)  REFERENCES DimEmployees(employee_sk),
    CONSTRAINT fk_factorders_product   FOREIGN KEY (product_sk)   REFERENCES DimProducts(product_sk),
    CONSTRAINT fk_factorders_shipper   FOREIGN KEY (shipper_sk)   REFERENCES DimShippers(shipper_sk),
    CONSTRAINT fk_factorders_territory FOREIGN KEY (territory_sk) REFERENCES DimTerritories(territory_sk),
    CONSTRAINT fk_factorders_sor_o     FOREIGN KEY (sor_sk_orders)  REFERENCES Dim_SOR(SOR_SK),
    CONSTRAINT fk_factorders_sor_d     FOREIGN KEY (sor_sk_details) REFERENCES Dim_SOR(SOR_SK)
);


CREATE NONCLUSTERED INDEX ix_factorders_orderdate
    ON FactOrders (order_date);


CREATE TABLE FactOrdersError (
    fact_order_error_sk BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id_nk INT,
    product_id_nk INT,
    customer_id_nk NVARCHAR(10),
    employee_id_nk INT,
    shipper_id_nk INT,
    territory_id_nk INT,
    order_date DATETIME2(0),
    required_date DATETIME2(0),
    shipped_date DATETIME2(0),
    unit_price DECIMAL(19,4),
    quantity SMALLINT,
    discount DECIMAL(5,4),
    freight DECIMAL(19,4),
    error_reason NVARCHAR(500),
    snapshot_date DATE,
    sor_sk_orders INT,
    staging_raw_id_orders INT,
    sor_sk_details INT,
    staging_raw_id_details INT,
    created_at DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
);

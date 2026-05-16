Use ORDER_DDS;


CREATE TABLE dbo.staging_raw_categories (
    staging_raw_id_sk INT IDENTITY(1,1) PRIMARY KEY,
    CategoryID INT,
    CategoryName NVARCHAR(100),
    Description NVARCHAR(MAX),
);

CREATE TABLE dbo.staging_raw_customers (
    staging_raw_id_sk INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID NVARCHAR(10),
    CompanyName NVARCHAR(100),
    ContactName NVARCHAR(100),
    ContactTitle NVARCHAR(100),
    Address NVARCHAR(255),
    City NVARCHAR(100),
    Region NVARCHAR(100),
    PostalCode NVARCHAR(20),
    Country NVARCHAR(100),
    Phone NVARCHAR(30),
    Fax NVARCHAR(30),
);


CREATE TABLE dbo.staging_raw_employees (
    staging_raw_id_sk INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT,
    LastName NVARCHAR(100),
    FirstName NVARCHAR(100),
    Title NVARCHAR(100),
    TitleOfCourtesy NVARCHAR(50),
    BirthDate DATETIME,
    HireDate DATETIME,
    Address NVARCHAR(255),
    City NVARCHAR(100),
    Region NVARCHAR(100),
    PostalCode NVARCHAR(20),
    Country NVARCHAR(100),
    HomePhone NVARCHAR(30),
    Extension NVARCHAR(10),
    Notes NVARCHAR(MAX),
    ReportsTo INT,
    PhotoPath NVARCHAR(255),
);


CREATE TABLE dbo.staging_raw_orders (
    staging_raw_id_sk INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT,
    CustomerID NVARCHAR(10),
    EmployeeID INT,
    OrderDate DATETIME,
    RequiredDate DATETIME,
    ShippedDate DATETIME,
    ShipVia INT,
    Freight DECIMAL(18,2),
    ShipName NVARCHAR(100),
    ShipAddress NVARCHAR(255),
    ShipCity NVARCHAR(100),
    ShipRegion NVARCHAR(100),
    ShipPostalCode NVARCHAR(20),
    ShipCountry NVARCHAR(100),
    TerritoryID NVARCHAR(20),
);

CREATE TABLE dbo.staging_raw_order_details (
    staging_raw_id_sk INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT,
    ProductID INT,
    UnitPrice DECIMAL(18,2),
    Quantity INT,
    Discount DECIMAL(5,2),
);

CREATE TABLE dbo.staging_raw_products (
    staging_raw_id_sk INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT,
    ProductName NVARCHAR(100),
    SupplierID INT,
    CategoryID INT,
    QuantityPerUnit NVARCHAR(100),
    UnitPrice DECIMAL(18,2),
    UnitsInStock INT,
    UnitsOnOrder INT,
    ReorderLevel INT,
    Discontinued BIT,
);


CREATE TABLE dbo.staging_raw_region (
    staging_raw_id_sk INT IDENTITY(1,1) PRIMARY KEY,
    RegionID INT,
    RegionDescription NVARCHAR(100),
    RegionCategory NVARCHAR(100),
    RegionImportance NVARCHAR(100),
);

CREATE TABLE dbo.staging_raw_shippers (
    staging_raw_id_sk INT IDENTITY(1,1) PRIMARY KEY,
    ShipperID INT,
    CompanyName NVARCHAR(100),
    Phone NVARCHAR(30),
);

CREATE TABLE dbo.staging_raw_suppliers (
    staging_raw_id_sk INT IDENTITY(1,1) PRIMARY KEY,
    SupplierID INT,
    CompanyName NVARCHAR(100),
    ContactName NVARCHAR(100),
    ContactTitle NVARCHAR(100),
    Address NVARCHAR(255),
    City NVARCHAR(100),
    Region NVARCHAR(100),
    PostalCode NVARCHAR(20),
    Country NVARCHAR(100),
    Phone NVARCHAR(30),
    Fax NVARCHAR(30),
    HomePage NVARCHAR(MAX),
);


CREATE TABLE dbo.staging_raw_territories (
    staging_raw_id_sk INT IDENTITY(1,1) PRIMARY KEY,
    TerritoryID NVARCHAR(20),
    TerritoryDescription NVARCHAR(100),
    TerritoryCode NVARCHAR(20),
    RegionID INT,
);


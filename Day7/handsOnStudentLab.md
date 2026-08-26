Setup Script (Run in SSMS):

```SQL
-- Cleanup existing lab tables if present
IF OBJECT_ID('dbo.InventoryUpdates', 'U') IS NOT NULL DROP TABLE dbo.InventoryUpdates;
IF OBJECT_ID('dbo.Products', 'U') IS NOT NULL DROP TABLE dbo.Products;
IF OBJECT_ID('dbo.ArchivedProducts', 'U') IS NOT NULL DROP TABLE dbo.ArchivedProducts;
IF OBJECT_ID('dbo.CategoryDiscounts', 'U') IS NOT NULL DROP TABLE dbo.CategoryDiscounts;

-- Create main Products master table
CREATE TABLE dbo.Products (
    ProductID INT IDENTITY(101,1) PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    Category VARCHAR(50) NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    StockQuantity INT NOT NULL DEFAULT 0,
    IsActive BIT DEFAULT 1,
    CreatedDate DATE DEFAULT GETDATE()
);

-- Seed initial records into Products
INSERT INTO dbo.Products (ProductName, Category, UnitPrice, StockQuantity, IsActive) VALUES
('Wireless Mouse', 'Electronics', 25.50, 150, 1),
('Mechanical Keyboard', 'Electronics', 89.99, 45, 1),
('Ergonomic Chair', 'Furniture', 249.00, 12, 1),
('Standing Desk', 'Furniture', 499.50, 8, 1),
('USB-C Hub', 'Electronics', 35.00, 0, 0),
('27-inch Monitor', 'Electronics', 299.99, 25, 1),
('Office Notebook', 'Stationery', 5.99, 200, 1),
('Gel Pens (10-pack)', 'Stationery', 12.49, 0, 0);

-- Create Category Discounts helper table
CREATE TABLE dbo.CategoryDiscounts (
    Category VARCHAR(50) PRIMARY KEY,
    DiscountPercentage DECIMAL(4,2) NOT NULL
);

INSERT INTO dbo.CategoryDiscounts VALUES
('Electronics', 0.15),  -- 15% discount
('Furniture', 0.10),    -- 10% discount
('Stationery', 0.05);   -- 5% discount

-- Create Staging table for Inventory Syncing
CREATE TABLE dbo.InventoryUpdates (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100),
    Category VARCHAR(50),
    UnitPrice DECIMAL(10,2),
    StockQuantity INT
);

INSERT INTO dbo.InventoryUpdates VALUES
(101, 'Wireless Mouse', 'Electronics', 22.00, 50),     -- Price change & stock shipment
(102, 'Mechanical Keyboard', 'Electronics', 89.99, 30),-- Stock shipment
(109, 'Webcam HD 1080p', 'Electronics', 59.99, 100);    -- Brand new product
```

---

### Student Tasks:

#### Task 1 (DDL Table Creation):

Write a DDL query to create a table named `dbo.ArchivedProducts` with the following column specification:

- `ProductID` (INT, NOT NULL, PRIMARY KEY)
- `ProductName` (VARCHAR(100), NOT NULL)
- `Category` (VARCHAR(50), NOT NULL)
- `UnitPrice` (DECIMAL(10,2), NOT NULL)
- `ArchiveDate` (DATE, default value set to current date `GETDATE()`)

---

#### Task 2 (Single & Multi-Row INSERT):

Write an `INSERT INTO` statement to add two new products into `dbo.Products`:

1. `Desk Lamp` in category `'Furniture'` with unit price `45.00` and stock quantity `60` (active).
2. `Noise Canceling Headphones` in category `'Electronics'` with unit price `199.99` and stock quantity `20` (active).

---

#### Task 3 (Safe UPDATE with Transaction):

Write an explicit transaction (`BEGIN TRANSACTION` / `COMMIT`) to update all active products in the `'Furniture'` category in `dbo.Products`:

- Increase their `StockQuantity` by `10`.
- Verify your changes with a `SELECT` statement before committing the transaction.

---

#### Task 4 (UPDATE with JOIN):

Write an `UPDATE` query that joins `dbo.Products` with `dbo.CategoryDiscounts` to apply the discount to `UnitPrice` for all active products:

- `UnitPrice = UnitPrice * (1 - DiscountPercentage)`
- Verify that `Wireless Mouse` (15% off $25.50) and `Ergonomic Chair` (10% off $249.00) reflect the updated prices.

---

#### Task 5 (INSERT INTO ... SELECT):

Write a query to insert all discontinued/inactive products (`IsActive = 0`) from `dbo.Products` into `dbo.ArchivedProducts`.

---

#### Task 6 (DELETE vs. TRUNCATE):

1. Write a `DELETE` query to remove all inactive products (`IsActive = 0`) from `dbo.Products`.
2. Write a `TRUNCATE` command to completely wipe out the `dbo.InventoryUpdates` staging table.

---

#### Task 7 (Upserting with MERGE):

Write a `MERGE` statement to synchronize `dbo.InventoryUpdates` (Source) into `dbo.Products` (Target) matching on `ProductID`:

- **WHEN MATCHED**: Update `Target.UnitPrice = Source.UnitPrice` and add `Source.StockQuantity` to `Target.StockQuantity`.
- **WHEN NOT MATCHED BY TARGET**: Insert the new product into `dbo.Products` (`ProductName`, `Category`, `UnitPrice`, `StockQuantity`, `IsActive = 1`).

---

---

### Solutions (For Instructor / Self-Assessment):

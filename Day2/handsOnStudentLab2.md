Setup Script (Run in SSMS):

```SQL
-- Create sample workspace
CREATE TABLE dbo.Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(50),
    Category VARCHAR(50),
    Price DECIMAL(6,2),
    StockQuantity INT,
    Rating DECIMAL(2,1)
);

INSERT INTO dbo.Products VALUES
(201, 'Wireless Mouse', 'Electronics', 29.99, 150, 4.5),
(202, 'Mechanical Keyboard', 'Electronics', 89.99, 45, 4.8),
(203, 'Desk Mat', 'Accessories', 19.99, 200, 4.2),
(204, 'Gaming Monitor', 'Electronics', 249.99, 15, 4.7),
(205, 'Ergonomic Chair', 'Furniture', 199.99, 8, 4.1),
(206, 'USB-C Cable', 'Accessories', 12.99, 300, 3.9);
```

Student Tasks:
Task 1: Write a query to select `ProductName`, `Price`, `StockQuantity`, and a calculated column multiplying `Price` by `StockQuantity`, aliasing the result as `[Total Inventory Value]`.

Task 2: Retrieve all products in either the `Electronics` or `Accessories` category that have a `Price` under `50.00` and a `Rating` of `4.0` or higher.

Task 3: Find all products whose `ProductName` starts with `Wireless` or whose `StockQuantity` is between `10` and `50`.

Task 4: Write a query to return the unique (`DISTINCT`) categories for products that cost more than `20.00`.

Task 5 (Hard): Retrieve `ProductName`, `Category`, `Price`, `StockQuantity`, and `Rating` for products that meet all of the following conditions:

- Are **NOT** in the `Furniture` category.
- Have a `Rating` of `4.5` or higher.
- Meet **at least one** of these criteria: have `StockQuantity` less than `50` OR have a `Price` of `100.00` or more.
  *(Hint: Remember operator precedence when combining `AND` and `OR` conditions).*

Task 6 (Hard): The company is running a 15% off discount campaign for high-inventory stock. Write a query to display:

- `ProductName`
- `Category`
- `Price` as `[Original Price]`
- Discounted unit price (`Price * 0.85`) as `[Discounted Price]`
- Projected total revenue from discounted stock (`Price * 0.85 * StockQuantity`) as `[Projected Revenue]`
- Total savings given to customers (`Price * 0.15 * StockQuantity`) as `[Customer Savings]`

**Filter the results** to only include products where:

- `StockQuantity` is greater than `100`
- The `ProductName` contains at least two words (i.e. contains a space using `LIKE '% %'`)
- The projected discounted revenue (`Price * 0.85 * StockQuantity`) is greater than `3000.00`.
  *(Note: Because of SQL processing order `FROM -> WHERE -> SELECT`, you must use the calculation in the `WHERE` clause rather than the alias).*

```SQL
-- Task 1 Solution
SELECT ProductName, Price, StockQuantity, Price * StockQuantity AS [Total Inventory Value]
FROM dbo.Products;

-- Task 2 Solution
SELECT ProductName, Category, Price, Rating
FROM dbo.Products
WHERE Category IN ('Electronics', 'Accessories')
  AND Price < 50.00
  AND Rating >= 4.0;

-- Task 3 Solution
SELECT *
FROM dbo.Products
WHERE ProductName LIKE 'Wireless%'
   OR StockQuantity BETWEEN 10 AND 50;

-- Task 4 Solution
SELECT DISTINCT Category
FROM dbo.Products
WHERE Price > 20.00;

-- Task 5 Solution
SELECT ProductName, Category, Price, StockQuantity, Rating
FROM dbo.Products
WHERE Category <> 'Furniture'
  AND Rating >= 4.5
  AND (StockQuantity < 50 OR Price >= 100.00);

-- Task 6 Solution
SELECT 
    ProductName,
    Category,
    Price AS [Original Price],
    Price * 0.85 AS [Discounted Price],
    Price * 0.85 * StockQuantity AS [Projected Revenue],
    Price * 0.15 * StockQuantity AS [Customer Savings]
FROM dbo.Products
WHERE StockQuantity > 100
  AND ProductName LIKE '% %'
  AND (Price * 0.85 * StockQuantity) > 3000.00;
```

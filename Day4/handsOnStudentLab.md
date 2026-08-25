Setup Script (Run in SSMS):

```SQL
-- Drop existing table if it exists
IF OBJECT_ID('dbo.Sales', 'U') IS NOT NULL
    DROP TABLE dbo.Sales;

-- Create sample workspace
CREATE TABLE dbo.Sales (
    SaleID INT PRIMARY KEY,
    SalesRep VARCHAR(50),
    Region VARCHAR(50),
    ProductCategory VARCHAR(50),
    UnitsSold INT,
    SaleAmount DECIMAL(10,2),
    SaleDate DATE,
    PaymentMethod VARCHAR(50)
);

INSERT INTO dbo.Sales VALUES
(1, 'Alice', 'East', 'Electronics', 5, 4500.00, '2024-01-05', 'Credit Card'),
(2, 'Bob', 'West', 'Furniture', 2, 1200.00, '2024-01-07', 'Bank Transfer'),
(3, 'Charlie', 'East', 'Electronics', 4, 3200.00, '2024-01-10', 'Credit Card'),
(4, 'Diana', 'North', 'Accessories', 12, 850.00, '2024-01-12', 'PayPal'),
(5, 'Alice', 'East', 'Furniture', 3, 2100.00, '2024-01-15', 'Credit Card'),
(6, 'Bob', 'West', 'Electronics', 6, 5400.00, '2024-01-18', 'Credit Card'),
(7, 'Evan', 'South', 'Accessories', 15, 950.00, '2024-01-20', 'PayPal'),
(8, 'Charlie', 'East', 'Furniture', 1, 900.00, '2024-01-22', 'Bank Transfer'),
(9, 'Diana', 'North', 'Electronics', 3, 2800.00, '2024-01-25', 'Credit Card'),
(10, 'Evan', 'South', 'Electronics', 4, 3600.00, '2024-01-28', 'Credit Card'),
(11, 'Alice', 'East', 'Electronics', 2, 1800.00, '2024-02-01', 'Bank Transfer'),
(12, 'Bob', 'West', 'Accessories', 8, 600.00, '2024-02-03', 'PayPal'),
(13, 'Charlie', 'East', 'Electronics', 5, 4200.00, '2024-02-05', 'Credit Card'),
(14, 'Diana', 'North', 'Furniture', 4, 3100.00, '2024-02-08', 'Bank Transfer'),
(15, 'Evan', 'South', 'Furniture', 2, 1400.00, '2024-02-10', 'Credit Card'),
(16, 'Alice', 'East', 'Accessories', 10, 750.00, '2024-02-12', 'PayPal'),
(17, 'Bob', 'West', 'Electronics', 3, 2900.00, '2024-02-15', 'Credit Card'),
(18, 'Diana', 'North', 'Accessories', 20, 1500.00, '2024-02-18', 'PayPal');
```

Student Tasks:

Task 1 (Table-Wide Aggregates): Write a single query to calculate overall summary metrics across the entire `dbo.Sales` table:

- Total number of transactions (`COUNT(*)`) aliased as `[Total Transactions]`
- Total revenue (`SUM`) aliased as `[Total Revenue]`
- Average sale amount (`AVG`) aliased as `[Average Sale]`
- Smallest transaction amount (`MIN`) aliased as `[Smallest Sale]`
- Largest transaction amount (`MAX`) aliased as `[Largest Sale]`
- Total units sold (`SUM`) aliased as `[Total Units Sold]`

Task 2 (Basic Grouping with GROUP BY): Write a query to analyze performance per sales representative.

- Display `SalesRep`
- Total deals closed as `[Total Deals]`
- Total revenue generated as `[Total Revenue]`
- Average deal amount as `[Average Deal Amount]`
- Sort the results by `[Total Revenue]` in descending order.

Task 3 (Multi-Column Grouping): Write a query to break down sales by both `Region` and `ProductCategory`.

- Display `Region`, `ProductCategory`, total number of transactions as `[Transaction Count]`, and total revenue as `[Category Revenue]`.
- Sort the results by `Region` alphabetically (A to Z), and then by `[Category Revenue]` in descending order.

Task 4 (Filtering Rows Before Aggregation with WHERE):
Write a query to calculate sales metrics specifically for the `'East'` region:

- Display `SalesRep`, total revenue generated in the East as `[East Revenue]`, and average transaction amount as `[Average East Deal]`.
- Filter using `WHERE` before grouping.
- Sort by `[East Revenue]` in descending order.

Task 5 (Filtering Aggregated Groups with HAVING):
Write a query to identify top-performing product categories:

- Group by `ProductCategory`.
- Display `ProductCategory`, total transaction count as `[Transaction Count]`, and total revenue as `[Total Revenue]`.
- Use `HAVING` to filter and only display categories that generated a `[Total Revenue]` greater than `10000.00` AND had more than `4` transactions.
- Sort by `[Total Revenue]` in descending order.

Task 6 (Conditional Logic with CASE WHEN):
Write a query to categorize individual sales into tiers:

- Select `SaleID`, `SalesRep`, `ProductCategory`, `SaleAmount`.
- Create a calculated column aliased as `[SaleTier]` using a `CASE WHEN` statement:
  - If `SaleAmount >= 3500.00` then `'High Value'`
  - If `SaleAmount BETWEEN 1500.00 AND 3499.99` then `'Medium Value'`
  - Otherwise `'Low Value'`
- Sort the output by `SaleAmount` in descending order.

Task 7 (Advanced - Conditional Aggregation):
Write a query grouping by `SalesRep` that computes:

- `SalesRep`
- Total overall revenue as `[Total Revenue]`
- Total revenue paid via `'Credit Card'` as `[Credit Card Revenue]` (using `SUM` with a `CASE` expression)
- Count of high-value transactions (`SaleAmount >= 3000.00`) as `[High Value Deals Count]` (using `COUNT` with a `CASE` expression)
- Sort by `[Total Revenue]` in descending order.

```SQL
```

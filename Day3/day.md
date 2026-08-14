# Day 3: Sorting Data & Result Set Pagination in SQL Server

---

## 1. Sorting Data: The `ORDER BY` Clause

In a relational database, data inside a table has **no inherent order**. Unless explicitly sorted with an `ORDER BY` clause, SQL Server may return records in any arbitrary order based on how the storage engine retrieves pages.

### Basic Syntax
```SQL
SELECT column1, column2, ...
FROM schema_name.table_name
ORDER BY sort_column1 [ASC | DESC], sort_column2 [ASC | DESC];
```

### A. Ascending (`ASC`) vs. Descending (`DESC`)
- `ASC` (Default): Sorts from lowest to highest (A to Z, 0 to 9, oldest date to newest date).
- `DESC`: Sorts from highest to lowest (Z to A, 9 to 0, newest date to oldest date).

```SQL
-- Sort employees by Salary in descending order (highest earners first)
SELECT EmployeeID, FirstName, LastName, Salary
FROM dbo.Employees
ORDER BY Salary DESC;
```

---

### B. Multi-Column Sorting (Tie-Breaking)
When multiple rows have identical values in the primary sorting column, secondary and tertiary sort columns act as tie-breakers.

```SQL
-- Sort by Department alphabetically, then by Salary highest to lowest within each department
SELECT Department, FirstName, LastName, Salary
FROM dbo.Employees
ORDER BY Department ASC, Salary DESC;
```

---

### C. Sorting by Column Aliases & Calculated Expressions
Unlike the `WHERE` clause, the `ORDER BY` clause evaluates **after** the `SELECT` clause in SQL's logical query processing order. Therefore, you **can** use column aliases in `ORDER BY`.

```SQL
-- Sorting using a calculated expression alias
SELECT ProductName, Price, StockQuantity, (Price * StockQuantity) AS [TotalInventoryValue]
FROM dbo.Products
ORDER BY [TotalInventoryValue] DESC;
```

---

### D. Sorting by Column Position (Index) — *Anti-Pattern*
SQL permits referencing columns by their 1-based numerical index in the `SELECT` list (e.g., `ORDER BY 2 DESC`), but this is **strongly discouraged** in production because modifying the `SELECT` column list silently breaks or changes the sort behavior. Always sort by column names or explicit expressions.

---

## 2. Restricting Row Counts: The `TOP` Clause (T-SQL)

SQL Server provides `TOP` to limit the number of rows returned in the result set.

### A. Basic `TOP (N)`
```SQL
-- Retrieve the top 5 highest paid employees
SELECT TOP (5) FirstName, LastName, Salary
FROM dbo.Employees
ORDER BY Salary DESC;
```

### B. Percentage of Rows (`TOP (N) PERCENT`)
```SQL
-- Retrieve the top 10% highest paid employees
SELECT TOP (10) PERCENT FirstName, LastName, Salary
FROM dbo.Employees
ORDER BY Salary DESC;
```

### C. Handling Equal Values with `TOP (N) WITH TIES`
If multiple rows tie for the last place (e.g., two employees tie for 5th place with the exact same salary), `TOP (5)` normally cuts off arbitrarily. Adding `WITH TIES` includes all rows that share the same sort values as the final row.
*(Note: `WITH TIES` requires an `ORDER BY` clause).*

```SQL
-- Returns 5 or more rows if there are ties for the 5th highest salary
SELECT TOP (5) WITH TIES FirstName, LastName, Salary
FROM dbo.Employees
ORDER BY Salary DESC;
```

---

## 3. Result Set Pagination: `OFFSET` and `FETCH NEXT`

Pagination is essential when building web applications, mobile apps, or reports where large datasets must be displayed across multiple pages (e.g., 10 or 20 records per page).

### SQL Server vs. MySQL / PostgreSQL
- **MySQL / PostgreSQL**: Uses `LIMIT <PageSize> OFFSET <OffsetRows>`
- **SQL Server (T-SQL 2012+ / ANSI Standard)**: Uses `OFFSET <OffsetRows> ROWS FETCH NEXT <PageSize> ROWS ONLY`

> [!IMPORTANT]
> In SQL Server, `OFFSET ... FETCH NEXT` **requires** an `ORDER BY` clause. Running `OFFSET` without `ORDER BY` will result in a syntax error.

---

### Basic Syntax
```SQL
SELECT column1, column2, ...
FROM dbo.TableName
ORDER BY sort_column ASC
OFFSET <number_of_rows_to_skip> ROWS
FETCH NEXT <number_of_rows_to_return> ROWS ONLY;
```

### Keyword Flexibility:
- `ROW` or `ROWS` can be used interchangeably.
- `FIRST` or `NEXT` can be used interchangeably.

---

### The Pagination Formula
To calculate how many rows to skip for any given page:

$$\text{OFFSET} = (\text{PageNumber} - 1) \times \text{PageSize}$$

| Page Number | Page Size | Formula: $(\text{Page} - 1) \times \text{Size}$ | T-SQL Clause |
| :--- | :--- | :--- | :--- |
| **Page 1** | 5 | $(1 - 1) \times 5 = 0$ | `OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY` |
| **Page 2** | 5 | $(2 - 1) \times 5 = 5$ | `OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY` |
| **Page 3** | 5 | $(3 - 1) \times 5 = 10$ | `OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY` |

---

### Code Examples

```SQL
-- Page 1: Retrieve the first 5 records (most expensive products)
SELECT ProductID, ProductName, Price
FROM dbo.Products
ORDER BY Price DESC, ProductID ASC
OFFSET 0 ROWS
FETCH NEXT 5 ROWS ONLY;

-- Page 2: Skip the first 5 records and fetch the next 5 (records 6 to 10)
SELECT ProductID, ProductName, Price
FROM dbo.Products
ORDER BY Price DESC, ProductID ASC
OFFSET 5 ROWS
FETCH NEXT 5 ROWS ONLY;

-- Skip the first 10 records and return all remaining records
SELECT ProductID, ProductName, Price
FROM dbo.Products
ORDER BY Price DESC, ProductID ASC
OFFSET 10 ROWS;
```

---

### Dynamic Pagination with Variables (Stored Procedure Pattern)
```SQL
DECLARE @PageNumber INT = 2;
DECLARE @PageSize INT = 5;

SELECT ProductID, ProductName, Price
FROM dbo.Products
ORDER BY Price DESC, ProductID ASC
OFFSET (@PageNumber - 1) * @PageSize ROWS
FETCH NEXT @PageSize ROWS ONLY;
```

---

## 4. Deterministic vs. Non-Deterministic Sorting

When paginating data, if the `ORDER BY` column has duplicate values (e.g. multiple products with `Price = 29.99`), rows with the same price may shift unpredictably between Page 1 and Page 2 across different query runs.

To ensure **deterministic (consistent) pagination**, always include a unique column (such as the Primary Key `ProductID`) as the final tie-breaker in the `ORDER BY` list:

```SQL
-- Deterministic sort: Primary Key (ProductID) acts as absolute tie-breaker
ORDER BY Price DESC, ProductID ASC
```

---

## 5. SQL Logical Query Processing Order

Understanding the order in which SQL Server processes clauses explains why aliases work in `ORDER BY` but not in `WHERE`:

```
1. FROM       -> Identify source tables & joins
2. WHERE      -> Filter rows before grouping
3. GROUP BY   -> Aggregate rows into groups
4. HAVING     -> Filter aggregated groups
5. SELECT     -> Select columns, evaluate expressions, assign aliases
6. DISTINCT   -> Eliminate duplicate output rows
7. ORDER BY   -> Sort the final result set (aliases are available here!)
8. TOP / OFFSET-FETCH -> Restrict row count / paginate
```

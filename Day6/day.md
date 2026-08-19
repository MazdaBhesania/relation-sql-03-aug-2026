# Day 6: Subqueries & Built-In Functions in Transact-SQL

---

## 1. Introduction to Subqueries & Execution Architecture

A **subquery** (also called an *inner query* or *nested query*) is a `SELECT` statement embedded within another Transact-SQL statement (known as the *outer query*). Subqueries enable you to break complex data retrieval problems down into modular, step-by-step logical operations.

```
+--------------------------------------------------------------------------------+
| OUTER QUERY: SELECT CustomerName, City FROM dbo.Customers WHERE CustomerID IN  |
|                                                                                |
|   +-----------------------------------------------------------------------+    |
|   | INNER SUBQUERY: (SELECT DISTINCT CustomerID FROM dbo.Orders           |    |
|   |                  WHERE OrderDate >= '2024-01-01')                     |    |
|   +-----------------------------------------------------------------------+    |
+--------------------------------------------------------------------------------+
```

### Logical Subquery Architecture & Rules

1. **Enclosure**: A subquery must always be enclosed within parentheses `(...)`.
2. **Placement**: Subqueries can be used wherever an expression is valid:
   - In the `SELECT` column list (computing computed/reference columns per row).
   - In the `WHERE` or `HAVING` clause (filtering rows or groups based on dynamically calculated criteria).
   - In the `FROM` clause (as a **derived table**).
   - In data modification statements (`INSERT`, `UPDATE`, `DELETE`).
3. **Nesting Depth**: T-SQL supports up to **32 levels** of nested subqueries, though in practice queries rarely exceed 2–3 levels for readability and performance.
4. **Column Count Restrictions**: 
   - Scalar and multi-valued comparison operators require the inner subquery to return **exactly one column**.
   - Returning multiple columns in a subquery causes a syntax error (e.g., `Only one expression can be specified in the select list when the subquery is not introduced with EXISTS`).
   - The only exception is the `EXISTS` predicate, where `SELECT *` or `SELECT 1` is standard.

---

## 2. Scalar Subqueries

A **scalar subquery** returns **exactly one row and one column** (a single value). Because its output is a single atomic value, it can be used anywhere a literal constant or single-valued expression is accepted.

### A. Scalar Subquery in the `WHERE` Clause

Find all products whose price is strictly greater than the overall average list price:

```SQL
SELECT ProductID, ProductName, UnitPrice
FROM dbo.Products
WHERE UnitPrice > (
    SELECT AVG(UnitPrice) 
    FROM dbo.Products
);
```

*Execution Mechanics:*
1. The inner query `(SELECT AVG(UnitPrice) FROM dbo.Products)` executes first and returns a single scalar value (e.g., `$305.50`).
2. The outer query evaluates `WHERE UnitPrice > 305.50` across all rows in `dbo.Products`.

### B. Scalar Subquery in the `SELECT` List

Benchmark each product's price directly against the catalog-wide maximum price:

```SQL
SELECT 
    ProductID,
    ProductName,
    UnitPrice,
    (SELECT MAX(UnitPrice) FROM dbo.Products) AS MaxCatalogPrice,
    (SELECT MAX(UnitPrice) FROM dbo.Products) - UnitPrice AS PriceDifferenceFromMax
FROM dbo.Products;
```

> [!IMPORTANT]
> **Handling NULL / Empty Sets in Scalar Subqueries**:
> If a scalar subquery matches zero rows, it evaluates to `NULL`. Ensure your outer query can gracefully handle `NULL` operands using functions like `ISNULL()` or `COALESCE()` to avoid unexpected computation errors.

---

## 3. Multi-Valued Subqueries

A **multi-valued subquery** returns a single column containing **zero, one, or multiple rows**. Because it produces a list of values, you cannot compare it using standard scalar operators (`= `, `>`, `<`); instead, you must use set-based operators like `IN` or `NOT IN`.

### A. The `IN` Operator

Retrieve all customers who have placed at least one order shipped to Seattle:

```SQL
SELECT CustomerID, CustomerName, City
FROM dbo.Customers
WHERE CustomerID IN (
    SELECT CustomerID
    FROM dbo.Orders
    WHERE ShipCity = 'Seattle'
);
```

### B. Subquery vs. `JOIN` Comparison

The query above can also be expressed using an `INNER JOIN`:

```SQL
SELECT DISTINCT c.CustomerID, c.CustomerName, c.City
FROM dbo.Customers AS c
INNER JOIN dbo.Orders AS o
    ON c.CustomerID = o.CustomerID
WHERE o.ShipCity = 'Seattle';
```

| Factor | Subquery with `IN` | `INNER JOIN` |
| :--- | :--- | :--- |
| **Output Columns** | Can only return columns from the **outer query** table. | Can project columns from **both** tables. |
| **Duplicate Handling** | Automatically handles duplicates without requiring `DISTINCT`. | If a customer has multiple orders, requires `DISTINCT` to eliminate duplicate customer rows. |
| **Query Optimizer** | Internally, SQL Server often converts simple `IN` subqueries into semi-joins, producing identical execution plans. |

> [!CAUTION]
> ### The Three-Valued Logic Trap with `NOT IN` and `NULL`
> In SQL, comparisons with `NULL` evaluate to `UNKNOWN`. If the dataset returned by a `NOT IN` subquery contains even a single `NULL` value, the entire `NOT IN` predicate evaluates to `UNKNOWN` or `FALSE` for every single outer row, resulting in **zero rows returned**!
>
> ```SQL
> -- DANGEROUS: If ANY CustomerID in Orders is NULL, this query returns ZERO rows!
> SELECT CustomerName 
> FROM dbo.Customers 
> WHERE CustomerID NOT IN (SELECT CustomerID FROM dbo.Orders);
> 
> -- SAFE ALTERNATIVE 1: Filter out NULLs explicitly in the subquery
> SELECT CustomerName 
> FROM dbo.Customers 
> WHERE CustomerID NOT IN (SELECT CustomerID FROM dbo.Orders WHERE CustomerID IS NOT NULL);
> 
> -- SAFE ALTERNATIVE 2 (Recommended): Use NOT EXISTS
> SELECT c.CustomerName
> FROM dbo.Customers AS c
> WHERE NOT EXISTS (
>     SELECT 1 FROM dbo.Orders AS o WHERE o.CustomerID = c.CustomerID
> );
> ```

---

## 4. Self-Contained vs. Correlated Subqueries

Subqueries are broadly classified into two operational types:

```
+-----------------------------------------------------------------------------+
|                          SUBQUERY CLASSIFICATION                            |
+------------------------------------+----------------------------------------+
| 1. Self-Contained (Independent)     | 2. Correlated (Dependent)              |
| - Has NO dependency on outer query | - References column(s) from outer query|
| - Can execute as a standalone query| - Cannot run independently             |
| - Evaluated ONCE by database engine| - Conceptually evaluated ONCE PER ROW  |
+------------------------------------+----------------------------------------+
```

### Correlated Subquery Example

Find the most expensive product within each product category:

```SQL
SELECT p1.CategoryID, p1.ProductID, p1.ProductName, p1.UnitPrice
FROM dbo.Products AS p1
WHERE p1.UnitPrice = (
    SELECT MAX(p2.UnitPrice)
    FROM dbo.Products AS p2
    WHERE p2.CategoryID = p1.CategoryID  -- Correlation predicate referencing outer p1
);
```

*How it works step-by-step:*
1. For every candidate row evaluated in outer table `p1`, SQL Server passes `p1.CategoryID` into the inner query.
2. The inner query computes `MAX(UnitPrice)` specifically for that category.
3. If `p1.UnitPrice` equals that category maximum, the row is included in the final result.

---

## 5. The `EXISTS` & `NOT EXISTS` Predicates

The `EXISTS` operator tests for the **existence** of any rows returned by a subquery. Instead of returning values or comparing data, it returns a boolean **`TRUE`** or **`FALSE`**.

```SQL
-- Find all customers who have placed at least one order
SELECT c.CustomerID, c.CustomerName, c.ContactEmail
FROM dbo.Customers AS c
WHERE EXISTS (
    SELECT 1 
    FROM dbo.Orders AS o
    WHERE o.CustomerID = c.CustomerID
);
```

### Why `EXISTS` is Preferred Over `COUNT(*) > 0`

Compare these two equivalent logical queries:

```SQL
-- Approach A: Inefficient COUNT(*)
SELECT c.CustomerName FROM dbo.Customers AS c
WHERE (SELECT COUNT(*) FROM dbo.Orders AS o WHERE o.CustomerID = c.CustomerID) > 0;

-- Approach B: High-Performance EXISTS (Semi-Join)
SELECT c.CustomerName FROM dbo.Customers AS c
WHERE EXISTS (SELECT 1 FROM dbo.Orders AS o WHERE o.CustomerID = c.CustomerID);
```

> [!TIP]
> **Short-Circuit Optimization:**
> - In Approach A, SQL Server must scan the entire orders table for that customer to count every matching row.
> - In Approach B, SQL Server uses **short-circuit evaluation**: the moment it encounters the *first* matching order for a customer, it immediately stops scanning and returns `TRUE`.
> - Furthermore, `NOT EXISTS` is completely immune to the `NULL` pitfalls that plague `NOT IN`.

---

## 6. Categorization of Built-In T-SQL Functions

Transact-SQL includes hundreds of built-in functions divided into five core functional categories:

```
+------------------------------------------------------------------------------------+
|                         T-SQL BUILT-IN FUNCTIONS TAXONOMY                          |
+-------------------+----------------------------------------------------------------+
| 1. Scalar         | Operates on individual values; returns a single atomic value.  |
| 2. Logical        | Evaluates boolean conditions / choices (IIF, CHOOSE, COALESCE).|
| 3. Ranking/Window | Calculates rankings & row partitions over subsets of data.     |
| 4. Rowset         | Returns a virtual table usable in the FROM clause (OPENJSON).  |
| 5. Aggregate      | Summarizes multiple rows into a single scalar summary value.   |
+-------------------+----------------------------------------------------------------+
```

---

## 7. In-Depth Built-In Scalar Functions

### A. Date and Time Functions

Date functions allow extracting parts, calculating intervals, shifting timestamps, and formatting dates:

```SQL
SELECT 
    GETDATE()                                AS [CurrentDateTime],
    SYSDATETIME()                            AS [HighPrecisionDateTime],
    YEAR(OrderDate)                          AS [OrderYear],
    MONTH(OrderDate)                         AS [OrderMonthNumber],
    DATENAME(month, OrderDate)               AS [OrderMonthName],
    DATENAME(weekday, OrderDate)             AS [DayOfWeekName],
    DATEPART(quarter, OrderDate)             AS [Quarter],
    DATEDIFF(day, OrderDate, GETDATE())      AS [DaysSinceOrderPlaced],
    DATEADD(day, 30, OrderDate)              AS [PaymentDueDate],
    EOMONTH(OrderDate)                       AS [EndOfMonthDate]
FROM dbo.Orders;
```

### B. String Manipulation Functions

```SQL
SELECT 
    CustomerName,
    UPPER(CustomerName)                      AS [UpperCase],
    LOWER(ContactEmail)                      AS [LowerCaseEmail],
    LEN(CustomerName)                        AS [CharacterCount],
    LEFT(CustomerName, 4)                    AS [First4Chars],
    RIGHT(CustomerName, 4)                   AS [Last4Chars],
    CHARINDEX('@', ContactEmail)             AS [AtSymbolPosition],
    SUBSTRING(ContactEmail, CHARINDEX('@', ContactEmail) + 1, LEN(ContactEmail)) AS [EmailDomain],
    REPLACE(CustomerName, 'Corp', 'Corporation') AS [ReplacedText],
    CONCAT(CustomerName, ' (', City, ', ', Country, ')') AS [FullCustomerLabel],
    CONCAT_WS(' - ', CustomerName, City, Country)        AS [DelimitedLabel],
    TRIM('   Cleaned String   ')             AS [TrimmedWhitespace]
FROM dbo.Customers;
```

### C. Mathematical Functions

```SQL
SELECT 
    UnitPrice,
    ROUND(UnitPrice, 1)                      AS [RoundTo1Decimal],
    ROUND(UnitPrice, 0)                      AS [RoundToNearestInt],
    FLOOR(UnitPrice)                         AS [FloorLargestInteger],
    CEILING(UnitPrice)                       AS [CeilingSmallestInteger],
    ABS(UnitPrice - 100.00)                  AS [AbsoluteDifferenceFrom100],
    POWER(2, 3)                              AS [TwoCubed], -- 8
    SQRT(144)                                AS [SquareRoot] -- 12
FROM dbo.Products;
```

### D. Data Type Conversion & Safe Casting

SQL Server provides standard `CAST()`, `CONVERT()`, and error-safe `TRY_` variants:

```SQL
-- Standard ANSI CAST
SELECT CAST('2024-05-15' AS DATE) AS [CastDate], CAST(49.95 AS INT) AS [CastInt];

-- T-SQL CONVERT with Style Codes (Style 101: mm/dd/yyyy, Style 103: dd/mm/yyyy, Style 120: yyyy-mm-dd hh:mi:ss)
SELECT CONVERT(VARCHAR(20), GETDATE(), 101) AS [US_DateStyle];
SELECT CONVERT(VARCHAR(20), GETDATE(), 103) AS [UK_DateStyle];
SELECT CONVERT(VARCHAR(20), GETDATE(), 120) AS [ISO_StandardStyle];

-- Safe Conversion (Returns NULL instead of raising query-terminating runtime errors on invalid input)
SELECT 
    TRY_CAST('12345' AS INT)        AS [ValidCastSuccess],    -- Returns 12345
    TRY_CAST('INVALID_NUMBER' AS INT) AS [InvalidCastSafelyNull], -- Returns NULL (No Crash!)
    TRY_CONVERT(DATE, '2024-02-30')  AS [InvalidDateSafelyNull];  -- Returns NULL (Feb 30 doesn't exist)
```

> [!NOTE]
> **Deterministic vs. Non-Deterministic Functions:**
> - **Deterministic**: Functions that always return the exact same output given the same input parameters (e.g., `ROUND()`, `UPPER()`, `DATEADD()`). These can be indexed in computed columns.
> - **Non-Deterministic**: Functions whose return value changes per invocation or depends on environment state (e.g., `GETDATE()`, `NEWID()`, `RAND()`). These cannot be indexed.

---

## 8. Logical Helper Functions

Transact-SQL provides convenient inline logical functions that streamline conditional evaluations:

### A. `IIF(condition, true_value, false_value)`

Shorthand syntax for a simple two-branch `CASE WHEN` expression:

```SQL
SELECT 
    ProductName,
    UnitPrice,
    StockQty,
    IIF(StockQty > 20, 'In Stock', 'Low Inventory Alert') AS StockStatus
FROM dbo.Products;
```

### B. `CHOOSE(index, val1, val2, val3, ...)`

Returns the item at the specified 1-based index position from an ordered list:

```SQL
-- Maps integer status codes (1, 2, 3, 4) to readable strings
SELECT 
    OrderID,
    StatusCode,
    CHOOSE(StatusCode, 'Pending', 'Processing', 'Shipped', 'Delivered') AS StatusDescription
FROM dbo.Orders;
```

### C. `COALESCE()` vs. `ISNULL()`

Both replace `NULL` with a fallback value, but differ in standards compliance and parameter flexibility:

```SQL
-- ISNULL: T-SQL specific, accepts exactly 2 arguments, inherits data type of 1st argument
SELECT OrderID, ISNULL(ShipCity, 'Pick-up in Store') AS ShippingDestination
FROM dbo.Orders;

-- COALESCE: ANSI-SQL standard, evaluates sequentially and returns the first non-NULL expression from N arguments
SELECT 
    CustomerID,
    COALESCE(ContactEmail, AlternativeEmail, BillingEmail, 'no-email@company.com') AS PrimaryEmail
FROM dbo.Customers;
```

---

## 9. Ranking & Window Functions

Ranking functions calculate ordinal ranks, row positions, or percentiles across a defined set of rows (**partition**) without collapsing rows (unlike `GROUP BY`).

All ranking functions require the `OVER()` clause:

```SQL
FUNCTION() OVER (
    [PARTITION BY partition_column]
    ORDER BY sort_column [ASC|DESC]
)
```

### The 4 Core Ranking Functions

```
+---------------+--------------------------------------------------------------------+
| Function      | Numbering Behavior on Ties                                         |
+---------------+--------------------------------------------------------------------+
| ROW_NUMBER()  | Unique sequential integer (1, 2, 3, 4) with no ties.               |
| RANK()        | Same rank for ties; leaves gaps (1, 2, 2, 4).                       |
| DENSE_RANK()  | Same rank for ties; NO gaps in sequence (1, 2, 2, 3).              |
| NTILE(n)      | Divides rows into n equal-sized buckets/quartiles (e.g., 1, 1, 2, 2).|
+---------------+--------------------------------------------------------------------+
```

### Comparison Demonstration

```SQL
SELECT 
    CategoryID,
    ProductName,
    UnitPrice,
    ROW_NUMBER() OVER(PARTITION BY CategoryID ORDER BY UnitPrice DESC) AS [RowNumber],
    RANK()       OVER(PARTITION BY CategoryID ORDER BY UnitPrice DESC) AS [RankPrice],
    DENSE_RANK() OVER(PARTITION BY CategoryID ORDER BY UnitPrice DESC) AS [DenseRankPrice],
    NTILE(2)     OVER(PARTITION BY CategoryID ORDER BY UnitPrice DESC) AS [PriceQuartile]
FROM dbo.Products;
```

### Solving "Top N Per Group" Using Subqueries / Derived Tables

Because window functions cannot be placed directly inside the `WHERE` clause of the same query block, wrap the query in a **derived table** or subquery:

```SQL
-- Find the Top 2 most expensive products within EACH category
SELECT CategoryID, ProductName, UnitPrice, PriceRank
FROM (
    SELECT 
        CategoryID,
        ProductName,
        UnitPrice,
        DENSE_RANK() OVER(PARTITION BY CategoryID ORDER BY UnitPrice DESC) AS PriceRank
    FROM dbo.Products
) AS RankedProducts
WHERE PriceRank <= 2
ORDER BY CategoryID, PriceRank;
```

---

## 10. Aggregate Functions & Group Summarization

Aggregate functions summarize data across multiple rows, returning a single metric:

- `COUNT(*)`: Counts total rows in a set, including `NULL` values.
- `COUNT(column)`: Counts only non-`NULL` occurrences in that specific column.
- `COUNT(DISTINCT column)`: Counts unique non-`NULL` occurrences.
- `SUM(column)`: Computes arithmetic sum of numeric non-`NULL` values.
- `AVG(column)`: Computes arithmetic mean of numeric non-`NULL` values.
- `MIN(column)` / `MAX(column)`: Returns lowest/highest numeric, date, or alphabetical string value.
- `STRING_AGG(column, separator)`: Concatenates string values across grouped rows into a single delimited string.

### Grouping with `GROUP BY` and `HAVING`

```SQL
SELECT 
    p.CategoryID,
    COUNT(*)                             AS [TotalProducts],
    AVG(p.UnitPrice)                     AS [AverageCategoryPrice],
    STRING_AGG(p.ProductName, ', ')      AS [ProductCatalogList]
FROM dbo.Products AS p
WHERE p.StockQty > 0                     -- 1. WHERE filters individual rows BEFORE grouping
GROUP BY p.CategoryID                    -- 2. GROUP BY creates category subsets
HAVING COUNT(*) >= 2                     -- 3. HAVING filters aggregate groups AFTER grouping
ORDER BY [AverageCategoryPrice] DESC;    -- 4. ORDER BY sorts final output
```

> [!WARNING]
> ### Error Msg 8120 Explained
> `Msg 8120: Column 'dbo.Products.ProductName' is invalid in the select list because it is not contained in either an aggregate function or the GROUP BY clause.`
>
> **The Golden Rule**: When `GROUP BY` is present, every single column in the `SELECT` clause must either be listed in the `GROUP BY` clause or be enclosed within an aggregate function.

---

## 11. Best Practices & Troubleshooting Cheatsheet

1. **Beware `NOT IN` with Nullable Columns**: Always default to `NOT EXISTS` or add `WHERE Column IS NOT NULL` when writing negative subquery filters.
2. **Qualify All Subquery Columns**: When writing correlated subqueries, always use explicit table aliases (e.g., `p1.CategoryID = p2.CategoryID`) to prevent accidental variable capture and outer column shadowing.
3. **Use Safe Type Conversions in Data Pipelines**: Prefer `TRY_CAST()` and `TRY_CONVERT()` over `CAST()` and `CONVERT()` when importing or transforming raw user input to prevent batch failures.
4. **Use Derived Tables to Filter Window Functions**: Window/ranking functions cannot appear directly in `WHERE` or `HAVING` clauses; nest them inside a subquery in the `FROM` clause.
5. **Remember T-SQL Logical Order of Execution**:
   $$\text{FROM} \longrightarrow \text{WHERE} \longrightarrow \text{GROUP BY} \longrightarrow \text{HAVING} \longrightarrow \text{SELECT} \longrightarrow \text{DISTINCT} \longrightarrow \text{ORDER BY} \longrightarrow \text{TOP / OFFSET-FETCH}$$


# Day 4: Aggregate Functions, GROUP BY, HAVING, and CASE WHEN

---

## 1. Aggregate Functions

Aggregate functions perform a mathematical calculation on a set of values in a column and return a **single summary value**.

| Function    | Purpose                              | Example                           |
| :---------- | :----------------------------------- | :-------------------------------- |
| `COUNT()` | Counts total rows or non-null values | `COUNT(SaleID)` or `COUNT(*)` |
| `SUM()`   | Calculates total numeric sum         | `SUM(SaleAmount)`               |
| `AVG()`   | Calculates arithmetic mean           | `AVG(SaleAmount)`               |
| `MIN()`   | Returns the smallest / minimum value | `MIN(SaleAmount)`               |
| `MAX()`   | Returns the largest / maximum value  | `MAX(SaleAmount)`               |

### Basic Aggregate Example

```SQL
SELECT 
    COUNT(*) AS TotalTransactions,
    SUM(SaleAmount) AS TotalRevenue,
    AVG(SaleAmount) AS AverageSale,
    MIN(SaleAmount) AS SmallestSale,
    MAX(SaleAmount) AS LargestSale
FROM dbo.Sales;
```

> [!NOTE]
> - `COUNT(*)` counts all rows in the table (including rows with `NULL`s).
> - `COUNT(column_name)` counts only non-NULL values in that column.
> - `COUNT(DISTINCT column_name)` counts the number of unique non-NULL values.
> - `SUM()`, `AVG()`, `MIN()`, and `MAX()` ignore `NULL` values.

---

## 2. Grouping Data: The `GROUP BY` Clause

When you need to calculate aggregate summary metrics for specific categories (e.g., total sales per sales representative, average salary per department, or order counts per region), use the `GROUP BY` statement.

```SQL
SELECT SalesRep, SUM(SaleAmount) AS TotalRevenue
FROM dbo.Sales
GROUP BY SalesRep;
```

### Multi-Column Grouping

You can group by multiple columns to create granular breakdown buckets:

```SQL
SELECT Region, ProductCategory, SUM(SaleAmount) AS TotalRevenue, COUNT(*) AS TotalSales
FROM dbo.Sales
GROUP BY Region, ProductCategory;
```

> [!IMPORTANT]
> **The Golden Rule of `GROUP BY`**:
> Any non-aggregated column in your `SELECT` list **must** be included in your `GROUP BY` clause.
>
> *Incorrect:*
>
> ```SQL
> SELECT SalesRep, Region, SUM(SaleAmount) -- Error: Region is not in GROUP BY!
> FROM dbo.Sales
> GROUP BY SalesRep;
> ```
>
> *Correct:*
>
> ```SQL
> SELECT SalesRep, Region, SUM(SaleAmount)
> FROM dbo.Sales
> GROUP BY SalesRep, Region;
> ```

---

## 3. Filtering Aggregates: `HAVING` vs. `WHERE`

A common mistake is attempting to filter aggregated values inside a `WHERE` clause (e.g., `WHERE SUM(SaleAmount) > 3000` — this causes a syntax error).

| Clause               | When it Runs                  | Purpose                           | Can use Aggregates? |
| :------------------- | :---------------------------- | :-------------------------------- | :------------------ |
| **`WHERE`**  | **Before** `GROUP BY` | Filters individual records/rows   | ❌ No               |
| **`HAVING`** | **After** `GROUP BY`  | Filters aggregated summary groups | ✅ Yes              |

```
Logical Processing Order:
FROM  --->  WHERE  --->  GROUP BY  --->  HAVING  --->  SELECT  --->  ORDER BY
```

### Example: Combining `WHERE`, `GROUP BY`, and `HAVING`

Find sales reps in the `'East'` region who generated over $3,000 in total revenue:

```SQL
SELECT SalesRep, SUM(SaleAmount) AS TotalRevenue
FROM dbo.Sales
WHERE Region = 'East'             -- 1. Filters individual records (East region only)
GROUP BY SalesRep                 -- 2. Aggregates total per sales rep
HAVING SUM(SaleAmount) > 3000     -- 3. Filters aggregated groups (Revenue > 3000)
ORDER BY TotalRevenue DESC;       -- 4. Sorts the final result
```

---

## 4. Conditional Logic: The `CASE WHEN` Statement

The `CASE` expression evaluates conditions sequentially and returns a specified value when the first condition evaluates to `TRUE` (if-then-else logic).

### Basic Syntax

```SQL
SELECT 
    SaleID,
    SalesRep,
    SaleAmount,
    CASE 
        WHEN SaleAmount >= 3000 THEN 'High Value'
        WHEN SaleAmount BETWEEN 1500 AND 2999 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS SaleTier
FROM dbo.Sales;
```

---

## 5. Advanced: Conditional Aggregation

You can embed `CASE` expressions inside aggregate functions (`SUM()`, `COUNT()`) to pivot data or calculate filtered totals in a single query:

```SQL
SELECT 
    SalesRep,
    SUM(SaleAmount) AS TotalRevenue,
    SUM(CASE WHEN Region = 'East' THEN SaleAmount ELSE 0 END) AS EastRevenue,
    SUM(CASE WHEN Region = 'West' THEN SaleAmount ELSE 0 END) AS WestRevenue,
    COUNT(CASE WHEN SaleAmount >= 3000 THEN 1 END) AS HighValueSalesCount
FROM dbo.Sales
GROUP BY SalesRep;
```

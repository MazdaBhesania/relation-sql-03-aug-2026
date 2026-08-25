# Day 5: Combining Multiple Tables with JOINs in T-SQL

---

## 1. Introduction to Joins & Logical Processing

In relational database design (RDBMS), data is normalized and separated into multiple specialized tables to reduce redundancy and maintain data integrity. To answer business questions, you must combine data from two or more tables into a single result set using **JOIN** operations.

```
+------------------+         +--------------------+
|  dbo.Customers   |         |     dbo.Orders     |
+------------------+         +--------------------+
| CustomerID (PK)  |<---+    | OrderID (PK)       |
| CustomerName     |    +----| CustomerID (FK)    |
| City             |         | OrderDate          |
+------------------+         | TotalAmount        |
                             +--------------------+
```

### The `FROM` Clause and Intermediate Virtual Tables

In T-SQL logical query processing, the `FROM` clause is the **very first clause evaluated**.

```
Logical Processing Order:
FROM (Joins & Virtual Tables) ---> WHERE ---> GROUP BY ---> HAVING ---> SELECT ---> DISTINCT ---> ORDER BY ---> TOP/OFFSET-FETCH
```

1. The `FROM` clause identifies the source tables and evaluates the `JOIN` conditions.
2. It produces an intermediate **virtual table** containing the combined columns and rows.
3. This virtual table is passed downstream to subsequent clauses (`WHERE`, `GROUP BY`, `SELECT`, etc.).
4. In SQL Server, no physical table or temporary disk structure is created—this is entirely an in-memory, logical operation managed by the SQL Server Query Optimizer.

---

## 2. ANSI SQL-89 vs. ANSI SQL-92 Syntax

T-SQL supports two syntax standards for joining tables:

### A. ANSI SQL-89 (Legacy Syntax — Avoid)

In the SQL-89 standard, tables are listed in the `FROM` clause separated by commas, and the join condition is placed in the `WHERE` clause.

```SQL
-- ANSI SQL-89 Style (Not Recommended)
SELECT c.CustomerName, o.OrderID, o.TotalAmount
FROM dbo.Customers AS c, dbo.Orders AS o
WHERE c.CustomerID = o.CustomerID;
```

> [!WARNING]
> **Why ANSI SQL-89 is an Anti-Pattern:**
>
> - If you accidentally omit the `WHERE` clause, SQL Server will execute an unintended **Cartesian product** (cross join), matching every single row from table 1 with every row of table 2. On large production tables, this can lock tables, exhaust memory, and degrade performance.
> - Mixing filtering conditions with join conditions inside `WHERE` makes queries difficult to read and maintain.

### B. ANSI SQL-92 (Modern Standard — Recommended)

The ANSI SQL-92 standard introduces explicit `JOIN` operators and the `ON` clause to separate the **join relationship** from row filtering (`WHERE`).

```SQL
-- ANSI SQL-92 Style (Standard & Safe)
SELECT c.CustomerName, o.OrderID, o.TotalAmount
FROM dbo.Customers AS c
INNER JOIN dbo.Orders AS o
    ON c.CustomerID = o.CustomerID;
```

> [!IMPORTANT]
> In ANSI SQL-92 syntax, if you write `JOIN` but forget the `ON` clause, SQL Server immediately throws a **syntax error**, preventing accidental Cartesian products.

---

## 3. Overview of Join Types

| Join Type                      | Description                                                                                       | Unmatched Rows Included?                              |
| :----------------------------- | :------------------------------------------------------------------------------------------------ | :---------------------------------------------------- |
| **`INNER JOIN`**       | Returns only rows where the join condition matches in**both** tables.                       | ❌ No (non-matching rows discarded)                   |
| **`LEFT OUTER JOIN`**  | Returns**all** rows from the left table, plus matching rows from the right table.           | ✅ Yes (Left table preserved; NULLs for Right)        |
| **`RIGHT OUTER JOIN`** | Returns**all** rows from the right table, plus matching rows from the left table.           | ✅ Yes (Right table preserved; NULLs for Left)        |
| **`FULL OUTER JOIN`**  | Returns**all** rows from both tables, matching where possible.                              | ✅ Yes (Both tables preserved; NULLs where unmatched) |
| **`CROSS JOIN`**       | Returns the**Cartesian product** (every row of table 1 combined with every row of table 2). | N/A (No condition used)                               |
| **`SELF JOIN`**        | Joins a table to**itself** using distinct aliases (hierarchies, self-comparisons).          | Depends on INNER / OUTER join syntax                  |

---

## 4. Inner Joins (`INNER JOIN`)

An `INNER JOIN` is the most common join type. It returns only rows that satisfy the `ON` predicate in both tables.

```
       Table A            Table B
    +-----------+      +-----------+
    |     1     |      |     1     |
    |     2     |  ==> |     2     |  ===> Result: [ 1, 2 ]
    |     3     |      |     4     |
    +-----------+      +-----------+
```

### Basic Syntax

```SQL
SELECT c.CustomerID, c.CustomerName, o.OrderID, o.OrderDate, o.TotalAmount
FROM dbo.Customers AS c
INNER JOIN dbo.Orders AS o
    ON c.CustomerID = o.CustomerID;
```

*(Note: The `INNER` keyword is optional; writing `JOIN` defaults to `INNER JOIN` in T-SQL).*

### Multi-Table Inner Joins

To join three or more tables, chain consecutive `JOIN ... ON` statements:

```SQL
SELECT 
    c.CustomerName,
    o.OrderID,
    p.ProductName,
    oi.Quantity,
    oi.UnitPrice
FROM dbo.Customers AS c
INNER JOIN dbo.Orders AS o
    ON c.CustomerID = o.CustomerID
INNER JOIN dbo.OrderItems AS oi
    ON o.OrderID = oi.OrderID
INNER JOIN dbo.Products AS p
    ON oi.ProductID = p.ProductID;
```

### Composite Joins (Multiple Match Columns)

When tables share a composite primary/foreign key relationship across multiple columns, include all keys in the `ON` clause using `AND`:

```SQL
SELECT od.OrderID, od.CompanyCode, od.ProductID, p.ProductName
FROM dbo.OrderDetails AS od
INNER JOIN dbo.Products AS p
    ON od.ProductID = p.ProductID
   AND od.CompanyCode = p.CompanyCode;
```

---

## 5. Outer Joins (`LEFT`, `RIGHT`, `FULL`)

Outer joins allow you to preserve rows from one or both tables even when no corresponding match exists in the joined table. Unmatched attributes are filled with `NULL`.

### A. Left Outer Join (`LEFT OUTER JOIN` / `LEFT JOIN`)

Preserves **all** rows from the left (first) table. If a row in the left table has no match in the right table, right table columns return `NULL`.

```SQL
-- Returns ALL customers, including those who have never placed an order
SELECT c.CustomerID, c.CustomerName, o.OrderID, o.TotalAmount
FROM dbo.Customers AS c
LEFT OUTER JOIN dbo.Orders AS o
    ON c.CustomerID = o.CustomerID;
```

### B. Right Outer Join (`RIGHT OUTER JOIN` / `RIGHT JOIN`)

Preserves **all** rows from the right (second) table.

```SQL
-- Returns ALL orders, even if CustomerID is not associated with a customer
SELECT c.CustomerID, c.CustomerName, o.OrderID, o.TotalAmount
FROM dbo.Customers AS c
RIGHT OUTER JOIN dbo.Orders AS o
    ON c.CustomerID = o.CustomerID;
```

> [!TIP]
> Most professional database developers prefer `LEFT JOIN` over `RIGHT JOIN` for readability, as queries are typically structured reading from left-to-right (or top-to-bottom).

### C. Full Outer Join (`FULL OUTER JOIN` / `FULL JOIN`)

Combines the effects of both `LEFT` and `RIGHT` joins. It returns all matched rows, plus all unmatched rows from the left table (with `NULL`s for the right), plus all unmatched rows from the right table (with `NULL`s for the left).

```SQL
SELECT c.CustomerName, o.OrderID, o.TotalAmount
FROM dbo.Customers AS c
FULL OUTER JOIN dbo.Orders AS o
    ON c.CustomerID = o.CustomerID;
```

---

## 6. Identifying Orphan Records (Anti-Joins with `IS NULL`)

A powerful pattern using outer joins is finding rows in one table that have **no matching records** in another table.

```SQL
-- Find customers who have NEVER placed an order
SELECT c.CustomerID, c.CustomerName, c.Email
FROM dbo.Customers AS c
LEFT JOIN dbo.Orders AS o
    ON c.CustomerID = o.CustomerID
WHERE o.OrderID IS NULL;
```

```SQL
-- Find products that have NEVER been ordered
SELECT p.ProductID, p.ProductName, p.Price
FROM dbo.Products AS p
LEFT JOIN dbo.OrderItems AS oi
    ON p.ProductID = oi.ProductID
WHERE oi.OrderItemID IS NULL;
```

> [!CAUTION]
> When filtering outer joins in the `WHERE` clause, make sure your filter does not accidentally convert the outer join into an inner join!
>
> *Problem:*
>
> ```SQL
> SELECT c.CustomerName, o.TotalAmount
> FROM dbo.Customers AS c
> LEFT JOIN dbo.Orders AS o ON c.CustomerID = o.CustomerID
> WHERE o.TotalAmount > 100.00; -- Filters out customers with NULL orders! Converts to INNER JOIN!
> ```
>
> *Solution (Put right-table predicates in the `ON` clause or handle NULLs in `WHERE`):*
>
> ```SQL
> SELECT c.CustomerName, o.TotalAmount
> FROM dbo.Customers AS c
> LEFT JOIN dbo.Orders AS o 
>     ON c.CustomerID = o.CustomerID 
>    AND o.TotalAmount > 100.00;
> ```

---

## 7. Cross Joins (`CROSS JOIN` — Cartesian Products)

A `CROSS JOIN` combines every row of the first table with every row of the second table. If Table A has $N$ rows and Table B has $M$ rows, the result set will contain $N \times M$ rows.

```SQL
SELECT e.FirstName, p.ProductName
FROM dbo.Employees AS e
CROSS JOIN dbo.Products AS p;
```

> [!NOTE]
> - `CROSS JOIN` does **not** take an `ON` clause (attempting to use `ON` with `CROSS JOIN` results in a SQL syntax error).
> - **Practical Use Cases:**
>   1. Generating test data matrices.
>   2. Generating combinations (e.g., all store locations $\times$ all calendar months to prepare a zero-filled sales template).
>   3. Generating number or date sequences.

---

## 8. Self Joins

A **Self Join** is when a table is joined to itself. This is commonly used when a table contains a hierarchical relationship (such as an organizational chart or multi-level product categories) or when comparing records within the same table.

### Example A: Employee & Manager Hierarchy

An `Employees` table where each employee's record includes a `ManagerID` referencing another `EmployeeID` in the same table:

```SQL
SELECT 
    emp.EmployeeID AS EmployeeID,
    emp.FirstName + ' ' + emp.LastName AS EmployeeName,
    emp.JobTitle AS EmployeeTitle,
    ISNULL(mgr.FirstName + ' ' + mgr.LastName, 'Top Level Executive') AS ManagerName,
    mgr.JobTitle AS ManagerTitle
FROM dbo.Employees AS emp
LEFT JOIN dbo.Employees AS mgr
    ON emp.ManagerID = mgr.EmployeeID;
```

*(We use `LEFT JOIN` so that top-level leaders/executives who have `ManagerID = NULL` are still included in the result set).*

### Example B: Comparing Rows in the Same Table

Find pairs of customers located in the same city:

```SQL
SELECT 
    c1.CustomerName AS Customer1,
    c2.CustomerName AS Customer2,
    c1.City
FROM dbo.Customers AS c1
INNER JOIN dbo.Customers AS c2
    ON c1.City = c2.City
   AND c1.CustomerID < c2.CustomerID; -- Prevents matching a customer to themselves and eliminates duplicate mirrored pairs
```

---

## 9. Best Practices for Writing JOIN Queries

1. **Always Use Table Aliases**: Make queries concise and legible (e.g. `FROM dbo.Customers AS c INNER JOIN dbo.Orders AS o ON c.CustomerID = o.CustomerID`).
2. **Explicitly Qualify Column Names**: When querying multiple tables, always prefix column names with their table alias (e.g., `c.CustomerID` instead of just `CustomerID`) to avoid the `Ambiguous column name` error.
3. **Prefer ANSI SQL-92**: Always use explicit `INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN`, `FULL JOIN`, or `CROSS JOIN` syntax with `ON` predicates rather than comma-separated lists in `FROM`.
4. **Be Deliberate with `ON` vs. `WHERE`**:
   - `ON` determines how rows are matched during the join phase.
   - `WHERE` filters rows after the join is performed.
5. **Index Foreign Key Columns**: In production databases, ensure columns used in `ON` clauses (Foreign Keys) are indexed to optimize join performance.

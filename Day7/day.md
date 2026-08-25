# Day 7: Data Definition (DDL) & Data Manipulation (DML) in T-SQL

---

## 1. Introduction to DDL vs. DML

In SQL, SQL statements are categorized based on their functional purpose within the database engine:

| Category | Full Name | Purpose | Core Commands |
| :--- | :--- | :--- | :--- |
| **DDL** | Data Definition Language | Defines, alters, or removes database **structures/schemas**. | `CREATE`, `ALTER`, `DROP`, `TRUNCATE` |
| **DML** | Data Manipulation Language | Manages and modifies **data records inside** existing tables. | `INSERT`, `UPDATE`, `DELETE`, `MERGE` |

```
               +----------------------------------+
               |        Database Engine           |
               +----------------------------------+
                                |
        +-----------------------+-----------------------+
        |                                               |
  [ DDL Commands ]                                [ DML Commands ]
 (Building the House)                           (Furnishing the Rooms)
CREATE / ALTER / DROP                          INSERT / UPDATE / DELETE
```

---

## 2. Creating Tables: `CREATE TABLE` (DDL)

Before you can store or manipulate data, you must define the schema structure using the `CREATE TABLE` statement.

### Basic Syntax

```SQL
CREATE TABLE schema_name.table_name (
    column1_name data_type [column_constraint],
    column2_name data_type [column_constraint],
    ...
    [table_constraint]
);
```

### Common T-SQL Data Types

| Data Type | Description | Best Used For |
| :--- | :--- | :--- |
| `INT` | 4-byte whole integer (-2.1B to +2.1B) | IDs, Quantities, Counts |
| `BIGINT` | 8-byte whole integer | Large transaction IDs |
| `DECIMAL(p,s)` | Fixed precision (`p` total digits, `s` decimal digits) | Money, Financial calculations e.g. `DECIMAL(10,2)` |
| `VARCHAR(n)` | Variable-length character string (1 byte per char) | Names, Emails, Descriptions |
| `NVARCHAR(n)` | Variable-length Unicode string (2 bytes per char) | Multi-lingual / International text |
| `DATE` | Calendar date (`YYYY-MM-DD`) | Birthdates, Order Dates |
| `DATETIME2` | High precision Date + Time | System audit timestamps |
| `BIT` | Integer 1, 0, or `NULL` | Boolean flags e.g., `IsActive` |

### Key Column Constraints & Auto-Increment (`IDENTITY`)

* **`PRIMARY KEY`**: Uniquely identifies each row in a table. Imposes uniqueness and disallows `NULL`s.
* **`NOT NULL`**: Ensures a column cannot contain `NULL` values.
* **`DEFAULT`**: Provides a default value if no value is explicitly supplied during an `INSERT`.
* **`IDENTITY(seed, increment)`**: Automatically generates sequential numbers (e.g., `IDENTITY(1,1)` starts at 1 and increments by 1).

### Example: Creating a Table

```SQL
CREATE TABLE dbo.Employees (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    Salary DECIMAL(10,2) NOT NULL,
    HireDate DATE DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1
);
```

---

## 3. Inserting Data: `INSERT INTO` (DML)

The `INSERT` statement adds new records to an existing table.

### A. Single-Row and Multi-Row Insert

```SQL
-- Explicit column mapping (Best Practice)
INSERT INTO dbo.Employees (FirstName, LastName, Email, Salary, HireDate, IsActive)
VALUES 
('Alice', 'Smith', 'alice.smith@company.com', 75000.00, '2023-01-15', 1),
('Bob', 'Jones', 'bob.jones@company.com', 62000.00, '2023-03-20', 1),
('Charlie', 'Brown', 'charlie.b@company.com', 88000.00, '2022-11-01', 0);
```

> [!NOTE]
> Do **not** include `IDENTITY` columns (like `EmployeeID`) in your `INSERT` list. SQL Server generates those values automatically.

### B. `INSERT INTO ... SELECT`

Populates an existing target table dynamically from the results of a `SELECT` query:

```SQL
INSERT INTO dbo.ArchivedEmployees (FirstName, LastName, Email, Salary)
SELECT FirstName, LastName, Email, Salary
FROM dbo.Employees
WHERE IsActive = 0;
```

### C. `SELECT INTO` (Creating & Populating a New Table)

Creates a **new** table on the fly based on the structure and result set of a `SELECT` statement:

```SQL
SELECT EmployeeID, FirstName, LastName, Salary
INTO dbo.HighEarners
FROM dbo.Employees
WHERE Salary >= 70000.00;
```

---

## 4. Updating Data: `UPDATE` (DML)

The `UPDATE` statement modifies existing values in one or more columns for rows matching a specified condition.

### Basic Syntax

```SQL
UPDATE schema_name.table_name
SET column1 = value1, column2 = value2
WHERE condition;
```

```SQL
-- Give a 10% raise to active employees in department 3
UPDATE dbo.Employees
SET Salary = Salary * 1.10
WHERE IsActive = 1;
```

> [!IMPORTANT]
> **The Golden Rule of `UPDATE`**:
> Always specify a `WHERE` clause unless you intentionally want to modify **every single row** in the entire table!
> 
> *Dangerous (Modifies all rows):*
> ```SQL
> UPDATE dbo.Employees SET Salary = 100000.00; -- EVERY employee now gets 100k!
> ```

### Advanced: `UPDATE` with `JOIN` (T-SQL Pattern)

You can update a table based on data residing in another related table using a `FROM` / `JOIN` clause:

```SQL
UPDATE e
SET e.Salary = e.Salary + d.BonusAmount
FROM dbo.Employees e
INNER JOIN dbo.DepartmentBonuses d
    ON e.DepartmentID = d.DepartmentID
WHERE d.PerformanceRating = 'High';
```

---

## 5. Deleting Data: `DELETE` vs. `TRUNCATE`

### A. The `DELETE` Statement (DML)

Removes specific records from a table based on a `WHERE` clause.

```SQL
DELETE FROM dbo.Employees
WHERE IsActive = 0 AND HireDate < '2020-01-01';
```

### B. The `TRUNCATE TABLE` Statement (DDL)

Removes **all rows** from a table instantly by deallocating the data pages.

```SQL
TRUNCATE TABLE dbo.TemporaryStaging;
```

### Deep Dive: `DELETE` vs. `TRUNCATE` Comparison

| Feature | `DELETE` | `TRUNCATE TABLE` |
| :--- | :--- | :--- |
| **Language Category** | **DML** (Data Manipulation) | **DDL** (Data Definition) |
| **Filtering (`WHERE`)** | ✅ Supported (can delete specific rows) | ❌ Not supported (removes all rows) |
| **Performance** | Slower (logs row-by-row deletions) | Extremely fast (deallocates data pages) |
| **Identity Reset** | ❌ Does **not** reset `IDENTITY` seed | ✅ Resets `IDENTITY` back to initial seed |
| **Foreign Key Restrictions**| Works if FK records aren't violated | ❌ Fails if table is referenced by a Foreign Key |
| **Rollback Capability** | ✅ Can be rolled back inside a Transaction | ✅ Can be rolled back inside a Transaction |

---

## 6. Upserting Data: The `MERGE` Statement (T-SQL)

The `MERGE` statement performs `INSERT`, `UPDATE`, or `DELETE` operations on a **target table** in a single atomic query based on matching records from a **source table**.

```SQL
MERGE INTO dbo.TargetInventory AS Target
USING dbo.SourceUpdates AS Source
    ON Target.ProductID = Source.ProductID

-- 1. When record exists in both target & source -> UPDATE
WHEN MATCHED THEN
    UPDATE SET Target.Quantity = Target.Quantity + Source.Quantity,
               Target.LastUpdated = GETDATE()

-- 2. When record exists in source but NOT target -> INSERT
WHEN NOT MATCHED BY TARGET THEN
    INSERT (ProductID, Quantity, LastUpdated)
    VALUES (Source.ProductID, Source.Quantity, GETDATE());
```

---

## 7. Data Safety: Basic Transactions (`BEGIN TRAN`, `COMMIT`, `ROLLBACK`)

When performing destructive DML operations (`UPDATE`, `DELETE`), use **Explicit Transactions** to verify changes before permanently applying them to disk.

```SQL
-- Start an explicit transaction block
BEGIN TRANSACTION;

-- Perform DML statement
DELETE FROM dbo.Employees
WHERE HireDate < '2015-01-01';

-- Check affected row count or test results
SELECT COUNT(*) FROM dbo.Employees;

-- If satisfied, save permanently:
COMMIT TRANSACTION;

-- OR if an error occurred / mistake made, undo completely:
-- ROLLBACK TRANSACTION;
```

> [!TIP]
> **Safety Best Practice**: Write `BEGIN TRAN;` before your `UPDATE` or `DELETE`, execute your query, review the `(X row(s) affected)` output, and only run `COMMIT` when you confirm the exact rows were updated.

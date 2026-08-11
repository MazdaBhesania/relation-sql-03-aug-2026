1. Intro
    Microsoft SQL Server (The engine) - 1433 

    SQL Server Management Studio(SSMS)(The Client GUI)


    [Developer/SSMS GUI] --- (T-SQL Query)---> [SQL Server Database Engine]
                        <---(Result Set)----


    What is 1433 ? default port but why it require a port ? 
    Traffic Direction 


    (Trust Server Certs) Public key and private key ? ----- Encryption 

2. Core SQL Engine: Relational Structures
   - Schema: Blueprint that groups related objects together (Default Schema : `dbo`)
   - table: Rows (record/tuples) and Columns (attributes)
   - Primary Key(PK): A unique identifier for every row in a table. 
   - What is the difference between primary key and unique constraint ?
   - Foreign Key (FK) : A column that references the primary key of another table to maintain referential integrity 


3. Writing Your First Queries: The SELECT Statement
    The `SELECT statement` is used to fetch and retrieve data from one or more tables.

    Basic Syntax
    ```SQL
    SELECT column1, column2
    FROM schema_name.table_name;
    ```

    A. Selecting All Columns (`*`)
    To retrieve every column in a table 
    ```SQL
    SELECT * FROM dbo.Employees;
    ```

    B. Selecting Specific Columns
    Explicitly list the required columns separated by commas:

    ```SQL
    SELECT EmployeeID, FirstName, LastName, JobTitle
    FROM dbo.Employees;
    ```

    C. Column Aliases (`AS`)
    Aliases rename columns in the query output for readability:
    ```SQL
    Select FirstName AS [Fist Name],
            LastName AS [Last Name],
            EmployeeCode From dbo.Employees;
    ```

    D. Derived / Calculated Columns
    Mathematical operations can be performed directly within a `SELECT` Statements:
    ```SQL 

    Select FirstName AS [Fist Name],
            LastName AS [Last Name],
            EmployeeCode*10 AS EC From dbo.Employees;
    ```

    E. Removing Duplicates (`DISTINCT`)
    To return only unique values from a column: 

    ```SQL 
    Select distinct LastName AS [Last Name]
            From dbo.Employees;
    ```

4. Filtering Data: The `WHERE` Clause 
   The `WHERE` Clause filters records so that only row meeting specified conditions are returned. 

   ```Plaintext
   Processing Order: FROM -> WHERE -> SELECT
   ``` 


    A. Basic Comparison Operators (`=`,`>`,`<`, `>=`, `<=`, `<>`)

    ```SQL
    -- FIND EMPLOYEE WITH SALARY GREATER THAN 60000
    SELECT EmployeeID, FirstName, LastName, Salary
    FROM dbo.Employees
    WHERE Salary > 60000;
    ```

    B. Multiple Conditions (`AND`, `OR`, `NOT`)

    ```SQL
    -- Find Software Engineers earning more than 70,000
    SELECT FirstName, LastName, JobTitle, Salary
    FROM dbo.Employees
    WHERE JobTitle = 'Software Engineer' 
    AND Salary > 70000;
    ```

    C. Range & List Filtering (`BETWEEN`, `IN`)

    ```SQL
    -- Filtering within a range 
    SELECT EmployeeID, Salary
    FROM dbo.Employees
    WHERE Salary BETWEEN 50000 AND 80000;

    -- Filtering against a list of specific values
    SELECT FirstName, LastName, Department
    FROM dbo.Employees
    WHERE Department IN ('IT', 'HR', 'Finance');
    ```

    D. Pattern Matching (`LIKE` & `Wildcard`)
    use `LIKE` to search for specific text patterns:
    - `%` represent zero, one or multiple characters. 
    - `_` represents a single character. 

    ```SQL
    -- Find Employees whose last name starts with 'S'
    SELECT FirstName, LastName
    FROM dbo.Employees
    WHERE LastName Like 'S%';

    -- Find emails ending in @company.com
    SELECT Email
    FROM dbo.Employees
    WHERE Email LIKE '%@company.com';
    ```
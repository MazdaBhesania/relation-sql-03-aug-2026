Setup Script (Run in SSMS):
```SQL
-- Drop existing table if it exists
IF OBJECT_ID('dbo.Books', 'U') IS NOT NULL
    DROP TABLE dbo.Books;

-- Create sample workspace
CREATE TABLE dbo.Books (
    BookID INT PRIMARY KEY,
    Title VARCHAR(100),
    Author VARCHAR(50),
    Genre VARCHAR(50),
    Price DECIMAL(6,2),
    Rating DECIMAL(3,2),
    PublishYear INT,
    CopiesSold INT
);

INSERT INTO dbo.Books VALUES
(101, 'Clean Code', 'Robert C. Martin', 'Software Engineering', 45.00, 4.70, 2008, 150000),
(102, 'The Pragmatic Programmer', 'Andrew Hunt', 'Software Engineering', 49.99, 4.80, 1999, 180000),
(103, 'Designing Data-Intensive Applications', 'Martin Kleppmann', 'Data Science', 55.00, 4.90, 2017, 120000),
(104, 'Introduction to Algorithms', 'Thomas H. Cormen', 'Computer Science', 89.99, 4.60, 2009, 95000),
(105, 'Hands-On Machine Learning', 'Aurélien Géron', 'Data Science', 59.99, 4.85, 2019, 110000),
(106, 'Deep Learning', 'Ian Goodfellow', 'Data Science', 75.00, 4.50, 2016, 70000),
(107, 'Python Crash Course', 'Eric Matthes', 'Programming', 35.50, 4.65, 2015, 220000),
(108, 'Fluent Python', 'Luciano Ramalho', 'Programming', 52.00, 4.75, 2021, 85000),
(109, 'SQL for Data Analytics', 'Upom Malik', 'Data Analytics', 39.99, 4.40, 2019, 45000),
(110, 'Storytelling with Data', 'Cole Nussbaumer', 'Data Analytics', 38.00, 4.60, 2015, 130000),
(111, 'Learning SQL', 'Alan Beaulieu', 'Database', 42.50, 4.50, 2020, 90000),
(112, 'Database System Concepts', 'Abraham Silberschatz', 'Database', 95.00, 4.30, 2019, 60000),
(113, 'Artificial Intelligence: A Modern Approach', 'Stuart Russell', 'Data Science', 110.00, 4.70, 2020, 80000),
(114, 'Head First Design Patterns', 'Eric Freeman', 'Software Engineering', 48.00, 4.65, 2004, 160000),
(115, 'Grokking Algorithms', 'Aditya Bhargava', 'Computer Science', 39.99, 4.80, 2016, 140000),
(116, 'Practical Statistics for Data Scientists', 'Peter Bruce', 'Data Science', 47.99, 4.55, 2020, 75000);
```

Student Tasks:

Task 1 (Single-Column Sorting): Write a query to retrieve `Title`, `Author`, `Price`, and `PublishYear` for all books, sorted by `Price` from most expensive to least expensive (descending order).

Task 2 (Multi-Column Sorting & Tie-Breaking): Write a query to display `Title`, `Genre`, `Rating`, and `Price`. Sort the results:
- Primarily by `Genre` alphabetically (A to Z)
- Secondarily by `Rating` from highest to lowest (descending)
- Tertiarily by `Title` alphabetically (A to Z) to break any remaining ties.

Task 3 (Sorting by Computed Expression / Alias): Write a query to display `Title`, `Price`, `CopiesSold`, and a calculated column multiplying `Price` by `CopiesSold` aliased as `[Total Revenue]`. Sort the final results by `[Total Revenue]` in descending order.
*(Hint: In SQL Server, can you use the column alias in the `ORDER BY` clause? Why?)*

Task 4 (Row Limiting with TOP):
- **Part A**: Retrieve the top 3 most expensive books in the catalog (`Title`, `Author`, `Price`).
- **Part B**: Retrieve the top 25% highest-rated books across the entire catalog (`Title`, `Rating`, `Genre`), sorted from highest rating to lowest.

Task 5 (Handling Duplicate Ranks with TOP WITH TIES):
- Retrieve the top 4 highest-rated books (`Title`, `Rating`, `Genre`).
- Use `WITH TIES` to ensure that any other books sharing the exact same rating as the 4th book are also included in the output.

Task 6 (Basic Result Set Pagination):
Imagine you are building a bookstore web application where 5 books are displayed per page, sorted by `PublishYear` from newest to oldest, with `BookID ASC` as the unique tie-breaker:
- **Query A (Page 1)**: Retrieve records 1 through 5 (Page 1).
- **Query B (Page 2)**: Retrieve records 6 through 10 (Page 2).
- **Query C (Page 3)**: Retrieve records 11 through 15 (Page 3).

Task 7 (Filtered Pagination):
A customer searches for books in either the `'Data Science'` or `'Computer Science'` genre with a `Price` under `100.00`.
- Display `Title`, `Genre`, `Price`, and `Rating`.
- Sort the results by `Rating` descending, and then `Price` ascending.
- Return **Page 1** with a page size of **4** books per page.


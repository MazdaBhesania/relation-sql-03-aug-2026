Setup Script (Run in SSMS):
```SQL
-- Create sample workspace
CREATE TABLE dbo.Students (
    StudentID INT PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Major VARCHAR(50),
    GPA DECIMAL(3,2),
    EnrollmentYear INT
);

INSERT INTO dbo.Students VALUES
(101, 'Alice', 'Smith', 'Computer Science', 3.85, 2022),
(102, 'Bob', 'Jones', 'Data Science', 2.90, 2021),
(103, 'Charlie', 'Brown', 'Computer Science', 3.40, 2023),
(104, 'Diana', 'Prince', 'Mathematics', 3.95, 2020),
(105, 'Evan', 'Wright', 'Data Science', 3.10, 2022);
```

Student Tasks:
Task 1: Write a query to select `FirstName`, `LastName`, and `GPA` for all students, aliasing `GPA` as `[Grade Point Average]`.

Task 2: Retrieve all students majoring in either `Computer Science` or `Data Science` who have a `GPA` greater than `3.20`.

Task 3: Find all students whose `LastName` starts with the letter `J` or who enrolled between `2021` and `2023`.
-- 1. Create a new database named TestDB
CREATE DATABASE TestDB;
GO

-- 2. Switch to TestDB so our next commands run inside it
USE TestDB;
GO

-- 3. List all databases to verify TestDB was created
SELECT name, create_date 
FROM sys.databases;
GO



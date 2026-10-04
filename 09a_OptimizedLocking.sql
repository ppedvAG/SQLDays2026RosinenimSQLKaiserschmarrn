--Die neuen Funktion Optimzed Locking 

----------------------------------------------------
-- SESSION 1
----------------------------------------------------

 -- DEMODATEN -->

ALTER DATABASE CURRENT SET ACCELERATED_DATABASE_RECOVERY = ON;
ALTER DATABASE CURRENT SET READ_COMMITTED_SNAPSHOT ON;
GO

DROP TABLE IF EXISTS dbo.Accounts;
CREATE TABLE dbo.Accounts (
    AccountID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName NVARCHAR(50),
    Balance DECIMAL(18,2)
);

INSERT INTO dbo.Accounts (CustomerName, Balance)
SELECT TOP (50000) 
    'Customer_' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS NVARCHAR(10)),
    1000.00
FROM sys.all_columns a CROSS JOIN sys.all_columns b;
GO

-- <---


-- In der Demo-Datenbank Optimized Locking ausschalten
ALTER DATABASE CURRENT SET OPTIMIZED_LOCKING = OFF;
GO


BEGIN TRANSACTION;
    -- Aktualisiert 10.000 Zeilen via Table-/Index-Scan
    UPDATE dbo.Accounts
    SET Balance = Balance + 50
    WHERE AccountID <= 10000;

    -- Transaktion bewusst offen lassen!
 -- --> GO TO SESSION 2

 -- In Session 1 erst das alte Update beenden
ROLLBACK TRANSACTION;
GO

-- Optimized Locking aktivieren
ALTER DATABASE CURRENT SET OPTIMIZED_LOCKING = ON;
GO


--Identische Stament nochmals

BEGIN TRANSACTION;
    UPDATE dbo.Accounts
    SET Balance = Balance + 50
    WHERE AccountID <= 10000;
/*
Optimized Locking - Demo mit zwei Sitzungen: SESSION 1 (Schreibende Sitzung)
Dieses Skript wird zusammen mit 09b_OptimizedLocking.sql (Session 2) in zwei getrennten Fenstern ausgeführt.
Ziel: Sichtbar machen, wie sich Sperren ohne und mit Optimized Locking unterscheiden.
Ablauf:
  1. Demodaten (dbo.Accounts mit 50.000 Zeilen) anlegen, ADR und RCSI einschalten
     (beides ist Voraussetzung für Optimized Locking).
  2. OPTIMIZED_LOCKING = OFF: Eine Transaktion aktualisiert 10.000 Zeilen und bleibt bewusst offen.
     Es entstehen tausende Zeilen- oder Seitensperren; ab ca. 5.000 Sperren eskaliert SQL Server zu einer
     Tabellensperre (X), und andere Sitzungen müssen warten.
  3. Wechsel zu Session 2 (09b): Dort werden die Sperren geprüft und ein Update auf eine ANDERE Zeile versucht
     (es wird blockiert).
  4. Rollback, OPTIMIZED_LOCKING = ON und dasselbe Statement erneut ausführen: Es wird nur noch eine
     XACT-Sperre (Transaktions-ID) gehalten, die Tabelle hat lediglich eine IX-Sperre.
     Das Update in Session 2 ist nun nicht mehr blockiert.
Merksatz: Optimized Locking = weniger Sperren im Lock Manager, weniger Lock Escalation, mehr Nebenläufigkeit.
Wichtig: Die offene Transaktion in Session 1 am Ende der Demo mit ROLLBACK beenden, damit keine Sperren bleiben.
*/

--Die neue Funktion Optimized Locking 

----------------------------------------------------
-- SESSION 1
----------------------------------------------------

 -- DEMODATEN --> Tabelle mit 50.000 Konten

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
    -- (ohne Optimized Locking: viele Zeilen-/Seitensperren, danach Lock Escalation)
    UPDATE dbo.Accounts
    SET Balance = Balance + 50
    WHERE AccountID <= 10000;

    -- Transaktion bewusst offen lassen!
 -- --> GO TO SESSION 2

 -- In Session 1 erst das alte Update beenden, damit alle Sperren freigegeben werden
ROLLBACK TRANSACTION;
GO

-- Optimized Locking aktivieren
ALTER DATABASE CURRENT SET OPTIMIZED_LOCKING = ON;
GO


--Identisches Statement nochmals: Nun wird nur noch eine XACT-Sperre gehalten

BEGIN TRANSACTION;
    UPDATE dbo.Accounts
    SET Balance = Balance + 50
    WHERE AccountID <= 10000;
/*
 SQL Server 2025 - Optimized Locking

 Voraussetzung: SQL Server 2025 (17.x); ADR erforderlich.
 RCSI wird für den LAQ-Effekt empfohlen. Lock after Qualification 
*/
USE SQL2025Workshop;
GO
-- Voraussetzungen und Status vor der Änderung prüfen.
SELECT name, compatibility_level,
       is_accelerated_database_recovery_on,
       is_optimized_locking_on,
       is_read_committed_snapshot_on
FROM sys.databases
WHERE database_id = DB_ID();
GO
-- Status von ADR und RCSI getrennt dokumentieren.
-- Bei kontrollierter Testdatenbank ADR aktivieren (erfordert exklusiven Zugriff).
-- ACHTUNG: ALTER DATABASE kann bestehende Verbindungen beeinflussen.
ALTER DATABASE SQL2025Workshop SET ACCELERATED_DATABASE_RECOVERY = ON;
GO
-- RCSI benötigt ebenfalls exklusiven Zugriff beim Umschalten.
ALTER DATABASE SQL2025Workshop SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;
GO
-- Optimized Locking explizit für diese Datenbank einschalten.
ALTER DATABASE SQL2025Workshop SET OPTIMIZED_LOCKING = ON;
GO

SELECT name, is_accelerated_database_recovery_on,
       is_optimized_locking_on, is_read_committed_snapshot_on
FROM sys.databases WHERE database_id = DB_ID();
GO
-- Einfacher DML-Test. Während die Transaktion offen ist, werden die
-- verbleibenden Sperren dieser Sitzung angezeigt.
BEGIN TRANSACTION;
UPDATE demo.Bestellung
SET Betrag = Betrag + 0.01
WHERE KundenID = 1 AND BestellungID <= 1000;

SELECT request_session_id, resource_type, request_mode, request_status,
       resource_description
FROM sys.dm_tran_locks
WHERE request_session_id = @@SPID
  AND resource_type IN ('PAGE','RID','KEY','XACT');
-- Mit optimized locking sollte die XACT/TID-Sperre sichtbar sein;
-- genaue Nebenlocks hängen von Zugriffspfad und Workload ab.
ROLLBACK TRANSACTION; -- Demo ändert keine Beispieldaten dauerhaft.

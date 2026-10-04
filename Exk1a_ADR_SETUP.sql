/*
Exkurs ADR, Teil 1: Vorbereitung der Vergleichsdatenbanken
Accelerated Database Recovery (ADR) wurde mit SQL Server 2019 eingeführt und ist in SQL Server 2025
Grundlage für Optimized Locking und für ADR in der tempdb.
Dieses Skript erstellt zwei leere Datenbanken, um das Verhalten bei einem Rollback zu vergleichen:
  - OldStyle: klassische Wiederherstellung (ADR aus). Beim Rollback muss das Transaktionsprotokoll rückwärts
    abgearbeitet werden (Undo), die Dauer entspricht ungefähr der Dauer der ursprünglichen Transaktion.
  - NewStyle: ADR eingeschaltet. Alte Zeilenversionen liegen im Persistent Version Store (PVS), ein Rollback
    markiert die Transaktion nur als abgebrochen und ist nahezu sofort beendet.
Zusätzlich wird die Serveroption 'ADR Cleaner Thread Count' gesetzt. Sie legt fest, wie viele Threads den
Hintergrundprozess zur Bereinigung des PVS verwenden (Standard 4). Weniger Threads schonen die Ressourcen,
verlangsamen aber das Aufräumen.
Bestehende Datenbanken gleichen Namens werden vorher gelöscht, das Skript ist wiederholbar.
Weiter geht es mit Exk1b_ADR_Fill2.sql (Daten füllen und Rollback messen) und
Exk1c__ADR Cleanup.sql (PVS überwachen und bereinigen).
Hinweis: sp_configure 'show advanced options' wird dafür aktiviert.
*/


-- Alte Demodatenbanken entfernen, damit das Skript wiederholbar ist
DROP database IF EXISTS oldstyle;
DROP database IF EXISTS NewStyle;

--Serveroption für den ADR-Cleaner setzen (erweiterte Optionen müssen sichtbar sein)
EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
GO
EXEC sp_configure 'ADR Cleaner Thread Count', '1'
--Wie viele Threads sollen für einen ADR Cleanup verwendet werden
--Standard ist 4. Weniger Threads können sinnvoll sein, wenn die Systemressourcen begrenzt sind.
RECONFIGURE WITH OVERRIDE;


-- OldStyle: Datenbank ohne ADR (klassisches Verhalten)
CREATE DATABASE OldStyle;
GO
-- NewStyle: Datenbank mit ADR (Persistent Version Store)
CREATE DATABASE NewStyle;
ALTER  DATABASE NewStyle SET ACCELERATED_DATABASE_RECOVERY = ON;
GO


--https://docs.microsoft.com/de-de/sql/relational-databases/accelerated-database-recovery-concepts?view=sql-server-ver15
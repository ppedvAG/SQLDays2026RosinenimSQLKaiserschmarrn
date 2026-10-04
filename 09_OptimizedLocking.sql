/*
Neu in SQL Server 2025: Optimized Locking (Überblick und Aktivierung)
Optimized Locking reduziert den Speicherverbrauch für Sperren und die Blockierungen bei Schreibzugriffen.
Es besteht aus zwei Bausteinen:
  1. TID-Locking (Transaction ID Locking): Statt jede geänderte Zeile/Seite einzeln zu sperren, wird nur
     eine Sperre auf die Transaktions-ID (XACT) gehalten. Die Zeilensperren werden sofort nach der Änderung
     wieder freigegeben. Der Lock Manager hat dadurch nur noch einen Eintrag pro Transaktion,
     und Lock Escalation tritt kaum noch auf.
  2. LAQ (Lock After Qualification): Bei READ COMMITTED SNAPSHOT (RCSI) wird die WHERE-Bedingung zuerst
     ohne Sperre auf der letzten committeten Version geprüft. Nur Zeilen, die wirklich passen, werden gesperrt.
     Dadurch blockieren sich parallele Updates auf unterschiedliche Zeilen weniger.
Voraussetzungen: Accelerated Database Recovery (ADR) muss aktiv sein; für LAQ wird RCSI empfohlen.
Das Skript prüft den Status in sys.databases, aktiviert ADR, RCSI und OPTIMIZED_LOCKING, führt ein
kleines UPDATE aus und zeigt mit sys.dm_tran_locks, welche Sperren gehalten werden (XACT-Sperre sichtbar).
Achtung: ALTER DATABASE erfordert exklusiven Zugriff und kann bestehende Verbindungen beeinflussen.
Die Zwei-Sitzungen-Demo mit Blockierungen steht in 09a (Session 1) und 09b (Session 2).
*/

/*
 SQL Server 2025 - Optimized Locking

 Voraussetzung: SQL Server 2025 (17.x); ADR erforderlich.
 RCSI wird für den LAQ-Effekt empfohlen (LAQ = Lock After Qualification).
*/
USE SQL2025Workshop;
GO
-- Voraussetzungen und Status vor der Änderung prüfen
-- (is_optimized_locking_on zeigt, ob das Feature in der Datenbank aktiv ist).
SELECT name, compatibility_level,
       is_accelerated_database_recovery_on,
       is_optimized_locking_on,
       is_read_committed_snapshot_on
FROM sys.databases
WHERE database_id = DB_ID();
GO
-- Status von ADR und RCSI getrennt dokumentieren.
-- ADR ist die Grundlage, weil die Transaktions-ID in den Zeilen über die ADR-Versionierung abgelegt wird.
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

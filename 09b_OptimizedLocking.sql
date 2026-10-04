/*
Optimized Locking - Demo mit zwei Sitzungen: SESSION 2 (Beobachtende Sitzung)
Dieses Skript gehört zu 09a_OptimizedLocking.sql (Session 1) und läuft in einem zweiten Abfragefenster.
Es zeigt, was auf dem Server passiert, während Session 1 eine Transaktion offen hält.
Teil 1 (OPTIMIZED_LOCKING = OFF in Session 1):
  - sys.dm_tran_locks zeigt tausende KEY- bzw. PAGE-Sperren, bei mehr als ca. 5.000 Sperren
    eskaliert SQL Server auf eine Objektsperre (X).
  - Ein Update auf eine andere Zeile (AccountID = 50000) wird blockiert, weil die Tabelle gesperrt ist.
Teil 2 (OPTIMIZED_LOCKING = ON in Session 1):
  - Die Objektsperre X entfällt, es bleibt nur IX auf Tabellenebene. IX ist mit IX anderer Transaktionen
    kompatibel, daher können parallele Transaktionen arbeiten.
  - Neu ist die XACT-Sperre: Die Transaktions-ID (TID) steht im Header der Datenzeile (ADR-Versionierung),
    und der Lock Manager verwaltet pro Transaktion nur einen Eintrag statt eines Eintrags pro Zeile.
  - Das Update auf AccountID = 50000 läuft ohne Wartezeit durch.
Am Ende des Skripts erklärt eine ASCII-Grafik, wie Datenseite, TID und Lock Manager zusammenspielen.
Hinweis: Die Grafik am Dateiende ist als Kommentar eingeschlossen, damit das Skript ausführbar bleibt.
*/

USE SQL2025Workshop
GO

----------------------------------------------------
-- SESSION 2
----------------------------------------------------

-- 1. Sperren prüfen: Tausende KEY- / PAGE-Locks sind vorhanden
SELECT resource_type, request_mode, COUNT(*) AS LockCount
FROM sys.dm_tran_locks
WHERE resource_database_id = DB_ID()
GROUP BY resource_type, request_mode;
--> mehr als 5000 Zeilen --> Key-Sperren --> Objektsperren (Tabelle) --> Lock Escalation greift

-- 2. Paralleles Update auf eine ANDERE Zeile versuchen:
-- (Wird blockiert, wenn der Scan über gesperrte Bereiche stolpert oder Lock Escalation greift)
UPDATE dbo.Accounts
SET Balance = Balance + 100
WHERE AccountID = 50000;

--> Zurück zu Session 1


--> Wieder zurück aus Session 1
SELECT resource_type, request_mode, COUNT(*) AS LockCount
FROM sys.dm_tran_locks
WHERE resource_database_id = DB_ID()
GROUP BY resource_type, request_mode;

--Die Objektsperre X ist weg, dafür gibt es IX. IX und X sind nicht kompatibel, daher müssten andere warten.
--                                        IX und IX zweier Transaktionen sind aber kompatibel.
--							 Das Objekt bekommt die Information, dass irgendwo darunter eine Sperre existiert. 
--							 Daher entfällt das aufwendige Suchen nach z. B. Sperren pro Zeile.
-- Neu ist XACT: eine Sperre auf Transaktionsebene. Die Transaktions-ID wird in den Header der Zeile geschrieben. Im Lock Manager gibt es nur 1 Eintrag.
-- Ohne Optimized Locking gibt es im Lock Manager für jede Zeilensperre einen Eintrag.

UPDATE dbo.Accounts
SET Balance = Balance + 100
WHERE AccountID = 50000;



/* Schematische Darstellung (als Kommentar, damit das Skript ausführbar bleibt)
+-----------------------------------------------------------------------------------+
| SQL Server 8-KB Data Page (im Buffer Pool / Speicher)                             |
|                                                                                   |
|  +-----------------------------------------------------------------------------+  |
|  | Physische Datenzeile (Data Row Slot)                                        |  |
|  |                                                                             |  |
|  |  [Record Header] -> Bit gesetzt: "Row Versioning / ADR aktiv"               |  |
|  |  [Fixed Length Columns] (z.B. AccountID = 42)                               |  |
|  |  [Null Bitmap]                                                              |  |
|  |  [Variable Length Data] (z.B. CustomerName = 'Customer_42')                 |  |
|  |                                                                             |  |
|  |  +-----------------------------------------------------------------------+  |  |
|  |  | 14-Byte Versioning Trailer (ADR PVS Info)                             |  |  |
|  |  |  * XACT-ID / TID: [ 0x000000004A12 ] (Transaktion A)                  |  |  |
|  |  |  * PVS Pointer:  [ FileID : PageID : SlotID ] -> Vorversion im PVS    |  |  |
|  |  +-----------------------------------------------------------------------+  |  |
|  +---------------------------------------|-------------------------------------+  |
+------------------------------------------|----------------------------------------+
                                           |
                                           | 1. Transaktion B liest Zielzeile
                                           |    und extrahiert XACT-ID (0x000000004A12)
                                           v
+-----------------------------------------------------------------------------------+
| SQL Server Lock Manager (Arbeitsspeicher)                                         |
|                                                                                   |
|  Ressourcentyp: XACT (Transaction ID)                                             |
|  +-------------------------+-------------+---------------------+---------------+  |
|  | Ressource (TID)         | Modus       | Status              | Eigentümer    |  |
|  +-------------------------+-------------+---------------------+---------------+  |
|  | XACT: 0x000000004A12    | X (Exklusiv)| GRANT (Hält Sperre) | Transaktion A |  |
|  | XACT: 0x000000004A12    | S (Shared)  | WAIT (Muss warten)  | Transaktion B |  |
|  +-------------------------+-------------+---------------------+---------------+  |
|                                                                                   |
|  Vorteil: Tausende geänderte Zeilen zeigen alle auf DENSELBEN TID-Eintrag.        |
|  Keine Millionen Einzelsperren auf KEY/PAGE-Ebene!                                |
+-----------------------------------------------------------------------------------+
*/

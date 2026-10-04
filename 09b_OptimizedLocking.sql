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
--> mehr als 5000 Zeilen --> key Sperren--> Objekt Sperren (Schlüssel) --> Lock Escalation greift

-- 2. Paralleles Update auf eine ANDERE Zeile versuchen:
-- (Wird blockiert, wenn der Scan über gesperrte Bereiche stolpert oder Lock Escalation greift)
UPDATE dbo.Accounts
SET Balance = Balance + 100
WHERE AccountID = 50000;

--> Zurück zu Session 1


--> Weider zurück aus Session 1
SELECT resource_type, request_mode, COUNT(*) AS LockCount
FROM sys.dm_tran_locks
WHERE resource_database_id = DB_ID()
GROUP BY resource_type, request_mode;

--Die Object Sperre X ist weg , dafür IX. IX und X ist nocht kompatibel, daher müssen andere warten.
--                                        IX und IX zweier Transcations sind aber kompatibel
--							 Objekt bekommt INformation, dass irgendwo darunter eine Sperre exisiert. 
--							 Daher entfällt das aufwendige Suchen nach zb Sperren pro Zeile
-- neu XACT: eine Sperre auf Transaktionsebene: TransaktionsID wird in den Header der Seite geschrieben. Im Lockmanager nur 1 Eintrag
-- ohne Optimized Locking-- im Lockmanager für jede Zeilensperren ein Eintrag

UPDATE dbo.Accounts
SET Balance = Balance + 100
WHERE AccountID = 50000;



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

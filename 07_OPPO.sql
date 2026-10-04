/*
Neu in SQL Server 2025: OPPO - Optional Parameter Plan Optimization
Problem: Prozeduren mit optionalen Parametern nach dem Muster
  WHERE KundenID = @KundenID OR @KundenID IS NULL
erhalten nur einen einzigen Plan. Je nach erstem Aufruf ist das ein Scan (bei NULL) oder ein Seek (bei einem Wert).
Der zwischengespeicherte Plan passt dann für den anderen Fall schlecht (Parameter-Sniffing-Problem).
Bisherige Workarounds: OPTION (RECOMPILE), dynamisches SQL oder getrennte Abfragen.
OPPO löst das automatisch: Der Optimizer erzeugt mehrere Pläne für dieselbe Anweisung (Multiplan-
Infrastruktur, bekannt von PSP) und wählt zur Laufzeit abhängig vom Parameterwert:
  - @Parameter IS NULL      -> Scan-Plan (alle Daten werden benötigt)
  - @Parameter IS NOT NULL  -> Seek-Plan (Index wird genutzt)
Voraussetzungen: Kompatibilitätsgrad 170 und die datenbankbezogene Konfiguration
OPTIONAL_PARAMETER_OPTIMIZATION = ON.
Das Skript aktiviert den Query Store, führt die Prozedur mit verschiedenen Werten aus (1 = häufiger,
999 = seltener Kunde), und vergleicht Pläne, Dauer und Lesevorgänge in den Query-Store-Sichten.
Danach wird OPPO ausgeschaltet und das Ergebnis erneut verglichen.
Hinweis: Mit "Actual Execution Plan" (Strg+M) lassen sich die Pläne direkt ansehen.
*/

-- Query Store einschalten, damit Pläne und Laufzeiten aufgezeichnet werden
ALTER DATABASE SQL2025Workshop SET QUERY_STORE=ON;

ALTER DATABASE SQL2025Workshop SET QUERY_STORE(
 OPERATION_MODE=READ_WRITE,QUERY_CAPTURE_MODE=AUTO,
 INTERVAL_LENGTH_MINUTES=1);

-- OPPO einschalten (setzt Kompatibilitätsgrad 170 voraus)
ALTER DATABASE SCOPED CONFIGURATION
 SET OPTIONAL_PARAMETER_OPTIMIZATION=ON;
GO


-- Prozedur mit optionalem Parameter: bei NULL werden alle Bestellungen geliefert, sonst nur die des Kunden
CREATE OR ALTER PROCEDURE demo.BestellungenSuchen
 @KundenID int=NULL AS
BEGIN
 SET NOCOUNT ON;
 SELECT BestellungID,KundenID,Bestelldatum,Betrag
 FROM demo.Bestellung
 WHERE KundenID=@KundenID OR @KundenID IS NULL;
END;
GO
-- Actual Execution Plan einschalten (Strg+M)
-- 999 = seltener Kunde (Seek), NULL = alle Zeilen (Scan): Mit OPPO sollten zwei verschiedene Pläne entstehen
EXEC demo.BestellungenSuchen @KundenID=999;
EXEC demo.BestellungenSuchen @KundenID=1;
EXEC demo.BestellungenSuchen @KundenID=NULL;


-- Messung der logischen Lesevorgänge und Zeiten
SET STATISTICS IO,TIME ON;
EXEC demo.BestellungenSuchen @KundenID=999;
EXEC demo.BestellungenSuchen @KundenID=NULL;
SET STATISTICS IO,TIME OFF;

-- Query Store auswerten: Anzahl der Pläne, Ausführungen, Dauer und Lesevorgänge je Plan
SELECT q.query_id,qt.query_sql_text,p.plan_id,
 rs.count_executions,rs.avg_duration,rs.avg_logical_io_reads
FROM sys.query_store_query_text qt
JOIN sys.query_store_query q ON q.query_text_id=qt.query_text_id
JOIN sys.query_store_plan p ON p.query_id=q.query_id
JOIN sys.query_store_runtime_stats rs ON rs.plan_id=p.plan_id
WHERE qt.query_sql_text LIKE '%demo.Bestellung%'
ORDER BY q.query_id,p.plan_id;



-- Vergleich: OPPO ausschalten und Plan Cache leeren. Nun gilt der Plan des ersten Aufrufs für alle Parameter.
ALTER DATABASE SCOPED CONFIGURATION
 SET OPTIONAL_PARAMETER_OPTIMIZATION=OFF;

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
EXEC demo.BestellungenSuchen @KundenID=999;
EXEC demo.BestellungenSuchen @KundenID=NULL;
ALTER DATABASE SCOPED CONFIGURATION
 SET OPTIONAL_PARAMETER_OPTIMIZATION=ON;

-- Danach OPPO wieder einschalten, Prozeduren erneut aufrufen und Pläne vergleichen
 EXEC demo.BestellungenSuchen @KundenID=999;
EXEC demo.BestellungenSuchen @KundenID=NULL;

/*
Parameter Sensitivity Plan

 bezieht sich auf einen Prozess, wobei SQL Server 
 die aktuellen Parameter während der Kompilierung oder Neukompilierung 
 ermittelt und diese an den Abfrageoptimierer übermittelt
 , sodass sie zum Generieren potenziell effizienter 
 Abfrageausführungspläne verwendet werden können.

 Parameterwerte werden während der Kompilierung oder Neukompilierung 
    für die folgenden Batchtypen ermittelt:

- Gespeicherten Prozeduren
- Abfragen, die über sp_executesql übermittelt werden
- Vorbereitete Abfragen



 Mit OPTION (RECOMPILE) kann der Optimierer einen optimalen 
 Abfrageplan generieren, der auf die spezifischen Werte 
 zugeschnitten ist und die besten zugrunde liegenden Indizes 
 zur Laufzeit nutzen kann. Bei Parametern bezieht sich dieser 
 Prozess nicht auf die Werte, die ursprünglich an die 
 Batch- oder gespeicherte Prozedur übergeben wurden
 , sondern auf ihre Werte zum Zeitpunkt der Neukompilierung. 
 Diese Werte wurden möglicherweise innerhalb der Prozedur geändert
 , bevor Sie die anweisung erreichen, die enthält RECOMPILE. 
 Dieses Verhalten kann die Leistung für Abfragen mit 
 stark variablen oder schiefen Eingabedaten verbessern.
 
 Lokale Variablen
Wenn eine Abfrage lokale Variablen verwendet, 
kann SQL Server ihre Werte zur Kompilierungszeit nicht ermitteln, 
sodass sie die Kardinalität
mithilfe verfügbarer Statistiken oder Heuristiken schätzt. 

10% Selektivität für Gleichheitsprädikate und 
30% für Ungleichheiten und Bereiche. Dies kann zu 
weniger genauen Ausführungsplänen führen. 
Hier ist ein Beispiel für eine Abfrage, die eine lokale Variable verwendet.

Optimierung des Parameterempfindlichkeitsplans (Parameter Sensitivity Plan, PSP) 

 Dieser wurde für Szenarios entwickelt, in denen ein 
 einzelner zwischengespeicherter Plan für eine parametrisierte 
 Abfrage nicht für alle möglichen eingehenden Parameterwerte optimal ist. 
 Dies ist bei uneinheitlichen Datenverteilungen der Fall. 

 Die PSP-Optimierung aktiviert automatisch mehrere aktive 
 zwischengespeicherte Pläne für eine einzelne parametrisierte 
 Anweisung. Zwischengespeicherte Ausführungspläne decken verschiedene
 Datengrößen basierend  auf den kundenseitig angegebenen 
 Laufzeitparameterwert(en) ab.

 Implementierung der PSP-Optimierung

 Während der anfänglichen Kompilierung werden über 
 Spaltenstatistikhistogramme uneinheitliche Verteilungen 
 identifiziert und bis zu drei der am stärksten gefährdeten 
 parametrisierten Prädikate bewertet.

 Optionale PSP-Optimierung

 derzeit nur mit Gleichheitsprädikaten.
 ?  Suche in eine Tabelle durchgeführt oder gescannt werden muss?

 WHERE column1 = @p OR @p IS NULL;

 --> immer SCAN

 Die Optionale Parameterplanoptimierung (OPPO) 
    verwendet die Adaptive Planoptimierungsinfrastruktur (Multiplan), 
    die mit der Optimierung des Parametersensitiven Plans eingeführt 
    wurde und mehrere Pläne aus einer einzigen Anweisung generiert. 
    Dadurch kann das Feature unterschiedliche Annahmen abhängig 
    von den parameterwerten vornehmen, die in der Abfrage verwendet 
    werden. Während der Abfrageausführung wählt OPPO den 
    entsprechenden Plan aus:

Wenn der Parameterwert IS NOT NULL erfüllt ist
    , wird ein Suchplan verwendet oder ein Plan
    , der optimaler ist als ein vollständiger Scanplan.
wobei der Parameterwert lautet NULL, wird ein Scanplan verwendet.

Voraussetzung

Die Datenbank muss die Kompatibilitätsebene 170 verwenden.
Die OPTIONAL_PARAMETER_OPTIMIZATION Konfiguration 
    mit Datenbankbereich muss aktiviert sein.

*/


USE IQP_Demo2025;
GO

-- 1. Tabelle zurücksetzen
DROP TABLE IF EXISTS dbo.Bestellungen;

CREATE TABLE dbo.Bestellungen (
    BestellID INT IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED,
    KundenTypID INT NOT NULL,
    FilialID INT NOT NULL,
    Notiz CHAR(1000) NOT NULL DEFAULT 'Breite Datenzeile'
);

-- Index nur auf KundenTypID
CREATE NONCLUSTERED INDEX IX_KundenTypID ON dbo.Bestellungen(KundenTypID);
GO

-- 2. Daten mit extremer Verteilung einfügen:
-- Wert 1: 10 Zeilen
-- Wert 2: 1.000.000 Zeilen
SET NOCOUNT ON;

-- 10 VIP-Zeilen
INSERT INTO dbo.Bestellungen (KundenTypID, FilialID)
SELECT TOP (10) 1, 1
FROM sys.all_objects;

-- 1.000.000 Standard-Zeilen
INSERT INTO dbo.Bestellungen (KundenTypID, FilialID)
SELECT TOP (1000000) 2, 2
FROM sys.all_columns a CROSS JOIN sys.all_columns b;
GO

-- 3. Statistiken mit echtem FULLSCAN erzwingen
UPDATE STATISTICS dbo.Bestellungen WITH FULLSCAN;
GO

-- 4. Testen, was der Optimizer NATIV bei Einzelabfragen machen würde
-- (Hier siehst du VOR der Prozedur, ob der Tipping-Point steht!)
SET STATISTICS XML ON;

-- Muss: Index Seek + Key Lookup sein!
SELECT * FROM dbo.Bestellungen WHERE KundenTypID = 1;

-- Muss: Clustered Index Scan sein!
SELECT * FROM dbo.Bestellungen WHERE KundenTypID = 2;

SET STATISTICS XML OFF;
GO

CREATE OR ALTER PROCEDURE dbo.usp_GetBestellungenByType
    @KundenTypID INT
AS
BEGIN
    SELECT * FROM dbo.Bestellungen WHERE KundenTypID = @KundenTypID;
END;
GO

-- Cache leeren
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

-- 1. Aufruf (10 Zeilen):
EXEC dbo.usp_GetBestellungenByType @KundenTypID = 1;

-- 2. Aufruf (1.000.000 Zeilen):
EXEC dbo.usp_GetBestellungenByType @KundenTypID = 2;
GO

--2 verschiedene Pläne..

SELECT 
    qs.execution_count,
    qs.plan_handle,
    qs.query_hash,
    st.text AS QueryText,
    qp.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE st.text LIKE '%dbo.Bestellungen%'
  AND st.text NOT LIKE '%sys.dm_exec_query_stats%'
ORDER BY qs.execution_count DESC;

--Plan anseehen in XML--> Dispatcher/Showplan XML


WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT 
    qs.execution_count,
    -- Prüft, ob das Attribut Dispatcher="true" irgendwo im Statement existiert
    qp.query_plan.value('(//StmtSimple/@Dispatcher)[1]', 'varchar(10)') AS IsDispatcher_Attr,
    -- Prüft, ob das Element <Dispatcher> vorhanden ist
    CASE WHEN qp.query_plan.exist('//Dispatcher') = 1 THEN 'JA' ELSE 'NEIN' END AS HasDispatcherNode,
    -- Liest die QueryVariantID aus
    qp.query_plan.value('(//StmtSimple/@QueryVariantID)[1]', 'int') AS QueryVariantID,
    st.text AS QueryText,
    qp.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE st.text LIKE '%dbo.Bestellungen%'
  AND st.text NOT LIKE '%sys.dm_exec_query_stats%'
ORDER BY qs.execution_count DESC;





---OPO
USE IQP_Demo2025;
GO

-- Index anpassen, damit der Seek bei gegebenem Parameter extrem billig ist
DROP INDEX IF EXISTS IX_FilialID ON dbo.Bestellungen;

CREATE NONCLUSTERED INDEX IX_FilialID 
ON dbo.Bestellungen (FilialID) 
INCLUDE (KundenTypID, Notiz);
GO

UPDATE STATISTICS dbo.Bestellungen WITH FULLSCAN;
GO

CREATE OR ALTER PROCEDURE dbo.usp_SucheBestellungenOptional
    @FilialID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT BestellID, FilialID, KundenTypID
    FROM dbo.Bestellungen
    WHERE (@FilialID IS NULL OR FilialID = @FilialID);
END;
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO


-- Fall 1: NULL übergeben
-- Erwartung: Clustered Index Scan (liest alle Daten)
EXEC dbo.usp_SucheBestellungenOptional @FilialID = NULL;

-- Fall 2: Konkreten Wert übergeben
-- Erwartung: Index Seek auf IX_FilialID (ohne Recompile!)
EXEC dbo.usp_SucheBestellungenOptional @FilialID = 99;

ALTER DATABASE SCOPED CONFIGURATION SET OPTIONAL_PARAMETER_OPTIMIZATION = OFF;










CREATE OR ALTER PROCEDURE dbo.usp_SucheBestellungenOptional
    @FilialID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT BestellID, KundenTypID, FilialID, Notiz
    FROM dbo.Bestellungen
    WHERE (@FilialID IS NULL OR FilialID = @FilialID);
END;
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

-- Lauf A: Kein Filter übergeben
EXEC dbo.usp_SucheBestellungenOptional @FilialID = NULL;

-- Lauf B: Konkreter Filter übergeben
EXEC dbo.usp_SucheBestellungenOptional @FilialID = 99;
/*
Neu in SQL Server 2025: OPTIMIZED_SP_EXECUTESQL
Dynamisches SQL kann auf drei Arten ausgeführt werden, mit unterschiedlichen Folgen für den Plan Cache:
  - EXEC(@sql) mit eingebetteten Werten: Jeder andere Wert erzeugt einen neuen Plan (Plan-Cache-Bloat,
    viele Kompilierungen).
  - sp_executesql mit Parametern: Ein Plan wird für alle Parameterwerte wiederverwendet. Das spart Kompilierungen,
    kann aber bei ungleich verteilten Daten (Parameter Sniffing) einen ungünstigen Plan liefern.
  - sp_executesql mit der datenbankbezogenen Option OPTIMIZED_SP_EXECUTESQL = ON (neu): Wird derselbe
    Batch gleichzeitig von vielen Sitzungen gestartet, kompiliert nur eine Sitzung, die anderen warten
    und verwenden das Ergebnis. Dadurch entfallen "Compile Storms" (viele gleichzeitige, identische
    Kompilierungen), CPU-Spitzen und Wartezeiten auf den Plan Cache.
Das Skript vergleicht die Anzahl der Pläne im Cache (sys.dm_exec_cached_plans) bei den drei Varianten
und schaltet die Option per ALTER DATABASE SCOPED CONFIGURATION aus und wieder ein.
Messen lässt sich der Effekt mit einem Lasttest (z. B. SQLQueryStress) mit vielen parallelen Sitzungen.
Voraussetzungen: Tabelle demo.Bestellung (Skript 01) und Kompatibilitätsgrad 170.
*/

USE SQL2025Workshop
GO

---Dynamisches SQL und seine Tücken

-- Datenüberblick
select * from demo.bestellung
-- Variante 1: EXEC mit fest eingebauten Werten (jeder Wert = neuer Plan im Cache)
DECLARE @sql NVARCHAR(MAX);


SET @sql = N'
SELECT BestellungID,KundenID, Bestelldatum, Betrag
FROM demo.Bestellung
WHERE KundenID = 999'
EXEC(@sql);

SET @sql = N'
SELECT BestellungID,KundenID, Bestelldatum, Betrag
FROM demo.Bestellung
WHERE KundenID = 993'
EXEC(@sql);

SET @sql = N'
SELECT BestellungID,KundenID, Bestelldatum, Betrag
FROM demo.Bestellung
WHERE KundenID = 1'
EXEC(@sql);

--Wie viele Pläne haben wir im Cache? Für jede Variante des Textes entsteht ein eigener Plan

SELECT cp.usecounts, st.text
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
WHERE st.text LIKE '%demo.bestellung%'
ORDER BY cp.usecounts DESC;


-----------------------------------------------------------
-- sp executesql
-----------------------------------------------------------

-- Variante 2: sp_executesql mit Parameter (ein Plan für alle Werte)
DECLARE @sql NVARCHAR(MAX);
DECLARE @KdID INT;

SET @sql = N'
SELECT BestellungID,KundenID, Bestelldatum, Betrag
FROM demo.Bestellung
WHERE KundenID = @KdID';

SET @Kdid = 999;
EXEC sp_executesql @sql, N'@KdId INT', @Kdid;

SET @Kdid = 993;
EXEC sp_executesql @sql, N'@KdId INT', @Kdid;

SET @Kdid = 1;
EXEC sp_executesql @sql, N'@KdId INT', @Kdid;

--Was haben wir im Plancache?

SELECT cp.usecounts, st.text
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
WHERE st.text LIKE '%demo.bestellung%'
ORDER BY cp.usecounts DESC;


--Vorteil: Wir haben nur einen Plan im Cache, der für alle drei Aufrufe wiederverwendet wird.

--Nachteil von sp_executesql: Die Wiederverwendung des Plans kann dazu führen, dass bei einer hohen 
--Anzahl von Aufrufen mit unterschiedlichen Parametern der Plan nicht optimal ist. Mal wenige Treffer, mal viele Treffer. 
-- Der Plan wird nur einmal erstellt und dann für alle Aufrufe wiederverwendet.
--In diesem Fall kann es sinnvoll sein, den Plan zu optimieren, indem man die Abfrage anpasst oder den Plan manuell erstellt.

--Ein weitere Aspekt:
-- In SQL 2025 gibt es die Möglichkeit, OPTIMIZED_SP_EXECUTESQL zu setzen.
-- Variante 3: Erst mit OPTIMIZED_SP_EXECUTESQL = OFF testen, danach mit ON vergleichen.


-- Plan Cache leeren, damit der Test bei null beginnt
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;

ALTER DATABASE SCOPED CONFIGURATION SET ASYNC_STATS_UPDATE_WAIT_AT_LOW_PRIORITY = OFF;
ALTER DATABASE SCOPED CONFIGURATION SET OPTIMIZED_SP_EXECUTESQL = OFF;



DECLARE @sql NVARCHAR(MAX);
DECLARE @KdID INT;

SET @sql = N'
SELECT BestellungID,KundenID, Bestelldatum, Betrag
FROM demo.Bestellung
WHERE KundenID = @KdID';

SET @Kdid = 999;
EXEC sp_executesql @sql, N'@KdId INT', @Kdid;

SET @Kdid = 993;
EXEC sp_executesql @sql, N'@KdId INT', @Kdid;

SET @Kdid = 1;
EXEC sp_executesql @sql, N'@KdId INT', @Kdid;



-- Nun mit eingeschalteter Option: Plan Cache erneut leeren und denselben Test wiederholen
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;

ALTER DATABASE SCOPED CONFIGURATION SET ASYNC_STATS_UPDATE_WAIT_AT_LOW_PRIORITY = ON;
ALTER DATABASE SCOPED CONFIGURATION SET OPTIMIZED_SP_EXECUTESQL = ON;


DECLARE @sql NVARCHAR(MAX);
DECLARE @KdID INT;

SET @sql = N'
SELECT BestellungID,KundenID, Bestelldatum, Betrag
FROM demo.Bestellung
WHERE KundenID = @KdID';

SET @Kdid = 999;
EXEC sp_executesql @sql, N'@KdId INT', @Kdid;

SET @Kdid = 993;
EXEC sp_executesql @sql, N'@KdId INT', @Kdid;

SET @Kdid = 1;
EXEC sp_executesql @sql, N'@KdId INT', @Kdid;

/* Jeder Thread, der diese sp_executesql aufruft, muss im globalen Plan Cache nachsehen, ob der Plan schon existiert.

SQL Server muss bei jedem Durchlauf im globalen Plan Cache nachsehen, 
--> Sperren/Latches auf Cache-Buckets (SOS_CACHESTORE) anfordern und den 
--> Metadaten-Hash verifizieren.

Bei hoher Parallelität führt das zu spürbaren Spinlock- und Cache-Wartezeiten sowie messbarem CPU-Overhead für die reine Aufruf-Koordination.
Man muss auf die Kompilierung warten, obwohl der gleiche Plan bereits vorliegt oder gerade ein anderer Thread den Plan kompiliert. 
Das ist ein Overhead, der bei sehr vielen Aufrufen mit unterschiedlichen Parametern spürbar wird. 

BEI OPTIMIZED_SP_EXECUTESQL = ON:

SQL Server nutzt einen optimierten Pfad für wiederkehrende parametrisierte Aufrufe.
--> Das wiederholte Nachschlagen und die Sperren-Synchronisation im Plan Cache werden minimiert.

Ergebnis: Höherer Durchsatz (mehr Iterationen/Sekunde in SQLQueryStress) bei reduzierter System-CPU-Last.
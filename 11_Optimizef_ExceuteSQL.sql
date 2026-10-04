USE SQL2025Workshop
GO

---Dynamisches SQL und sein Tücken

select * from demo.bestellung
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

--Wieviele Pläne haben wir im Cache?

SELECT cp.usecounts, st.text
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
WHERE st.text LIKE '%demo.bestellung%'
ORDER BY cp.usecounts DESC;


-----------------------------------------------------------
-- sp executesql
-----------------------------------------------------------

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

--Nachteil von sp_exceturesql. Die Wiederverwendung des Plans kann dazu führen, dass bei einer hohen 
--Anzahl von Aufrufen mit unterschiedlichen Parametern der Plan nicht optimal ist. Mal wenige Treffer, mal viele Treffer. 
-- Der Plan wird nur einmal erstellt und dann für alle Aufrufe wiederverwendet.
--In diesem Fall kann es sinnvoll sein, den Plan zu optimieren, indem man die Abfrage anpasst oder den Plan manuell erstellt.

--Ein weitere Aspekt:
-- In SQL 2025 gibt es die Möglichkeit OPTIMIZED_SP_EXECUTESQL  zu setzen.


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

/* Jeder Threads ruft  der diese sp_executesql aufuft, muss im globalen Plan Cache nachsehen, ob der Plan schon existiert.

SQL Server muss bei jedem Durchlauf im globalen Plan Cache nachsehen, 
--> Sperren/Latches auf Cache-Buckets (SOS_CACHESTORE) anfordern und den 
--> Metadaten-Hash verifizieren.

Bei hoher Parallelität führt das zu spürbaren Spinlock- und Cache-Wartezeiten sowie messbarem CPU-Overhead für die reine Aufruf-Koordination.
Man muss auf die Kompilierung warten, obwohl der gleiche Plan bereits vorliegt oer gerade ein anderer Thread den Plan gerade kompiliert. 
Das ist ein Overhead, der bei sehr vielen Aufrufen mit unterschiedlichen Parametern spürbar wird. 

BEI OPTIMIZED_SP_EXECUTESQL = ON:

SQL Server nutzt einen optimierten Pfad für wiederkehrende parametrisierte Aufrufe.
--> Das wiederholte Nachschlagen und die Sperren-Synchronisation im Plan Cache werden minimiert.

Ergebnis: Höherer Durchsatz (mehr Iterationen/Sekunde in SQLQueryStress) bei reduzierter System-CPU-Last.
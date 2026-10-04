ALTER DATABASE SQL2025Workshop SET QUERY_STORE=ON;

ALTER DATABASE SQL2025Workshop SET QUERY_STORE(
 OPERATION_MODE=READ_WRITE,QUERY_CAPTURE_MODE=AUTO,
 INTERVAL_LENGTH_MINUTES=1);

ALTER DATABASE SCOPED CONFIGURATION
 SET OPTIONAL_PARAMETER_OPTIMIZATION=ON;
GO


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
EXEC demo.BestellungenSuchen @KundenID=999;
EXEC demo.BestellungenSuchen @KundenID=1;
EXEC demo.BestellungenSuchen @KundenID=NULL;


SET STATISTICS IO,TIME ON;
EXEC demo.BestellungenSuchen @KundenID=999;
EXEC demo.BestellungenSuchen @KundenID=NULL;
SET STATISTICS IO,TIME OFF;

SELECT q.query_id,qt.query_sql_text,p.plan_id,
 rs.count_executions,rs.avg_duration,rs.avg_logical_io_reads
FROM sys.query_store_query_text qt
JOIN sys.query_store_query q ON q.query_text_id=qt.query_text_id
JOIN sys.query_store_plan p ON p.query_id=q.query_id
JOIN sys.query_store_runtime_stats rs ON rs.plan_id=p.plan_id
WHERE qt.query_sql_text LIKE '%demo.Bestellung%'
ORDER BY q.query_id,p.plan_id;



ALTER DATABASE SCOPED CONFIGURATION
 SET OPTIONAL_PARAMETER_OPTIMIZATION=OFF;

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
EXEC demo.BestellungenSuchen @KundenID=999;
EXEC demo.BestellungenSuchen @KundenID=NULL;
ALTER DATABASE SCOPED CONFIGURATION
 SET OPTIONAL_PARAMETER_OPTIMIZATION=ON;

 EXEC demo.BestellungenSuchen @KundenID=999;
EXEC demo.BestellungenSuchen @KundenID=NULL;

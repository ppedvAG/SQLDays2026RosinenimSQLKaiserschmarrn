/*
TEMPDB ADR

Ab SQL Server 2025 (17.x) Preview kann ADR in der tempdb-Datenbank aktiviert werden.

Ohne ADR, und selbst bei minimaler Protokollierung, 
können Transaktionen, die Objekte wie tempdb, Tabellenvariablen 
oder im erstellte nicht temporäre Tabellen umfassen, 
von langen Rollback-Zeiten und hohem Transaktionsprotokollverbrauch 
betroffen sein. Das Auslaufen des tempdb Transaktionsprotokollspeichers 
kann zu erheblichen Unterbrechungen und Anwendungsausfallzeiten führen.


*/

ALTER DATABASE tempdb set Accelerated_database_recovery = ON
--Neustart SQL Server!

select name,is_accelerated_database_recovery_on from sys.databases
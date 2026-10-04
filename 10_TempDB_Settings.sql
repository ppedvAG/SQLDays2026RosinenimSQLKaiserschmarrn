/*
Neu in SQL Server 2025: Verbesserungen an der tempdb (Metadaten und ADR)
Die tempdb ist der gemeinsame Arbeitsbereich für temporäre Tabellen, Tabellenvariablen, Sortierungen
und Zeilenversionierung. Dieses Skript zeigt zwei Einstellungen, die Engpässe dort verringern:
1. MEMORY_OPTIMIZED TEMPDB_METADATA = ON
   Die Systemtabellen der tempdb (Metadaten) werden in speicheroptimierten Strukturen gehalten.
   Das beseitigt Latch-Konflikte auf den Metadatenseiten bei sehr vielen gleichzeitigen CREATE/DROP von
   temporären Objekten. Die Option wird erst nach einem Neustart des SQL-Server-Dienstes wirksam;
   sys.configurations zeigt über value und value_in_use, ob ein Neustart aussteht.
2. Accelerated Database Recovery (ADR) in der tempdb (neu in SQL Server 2025)
   ADR speichert Zeilenversionen im Persistent Version Store (PVS), wodurch Rollbacks und Recovery
   nicht mehr von der Transaktionsgröße abhängen. In der tempdb verhindert das lange Rollbackzeiten und
   ein volllaufendes Transaktionsprotokoll, z. B. bei großen Transaktionen mit temporären Tabellen.
   Auch diese Einstellung erfordert einen Neustart.
Nach dem Neustart kontrolliert man die Einstellungen mit sys.configurations bzw. sys.databases
(Spalte is_accelerated_database_recovery_on).
Hinweis: Änderungen an der tempdb sollten zuerst in einer Testumgebung geprüft werden.
*/

/* =============================================
   Thema: Optimierung der tempdb

   Beschreibung: Verbesserung der Leistung in der tempdb
   ============================================= */

----------------------------------
--Metadaten in In-Memory-Strukturen
----------------------------------
-- Systemtabellen der tempdb in speicheroptimierte Tabellen verlagern (reduziert Latch-Konflikte)
ALTER SERVER CONFIGURATION SET MEMORY_OPTIMIZED TEMPDB_METADATA = ON;
GO
-- Danach SQL Dienst neu starten

-- value = konfigurierter Wert, value_in_use = aktuell wirksamer Wert (unterschiedlich = Neustart steht aus)
SELECT name, value, value_in_use
FROM sys.configurations
WHERE name = 'tempdb metadata memory-optimized';-- Unterscheiden sich value und value_in_use, steht ein Neustart aus



----------------------------------
-- ADR
----------------------------------

/*

Ab SQL Server 2025 (17.x) Preview kann ADR in der tempdb-Datenbank aktiviert werden.

Ohne ADR, und selbst bei minimaler Protokollierung, 
können Transaktionen, die Objekte wie tempdb, Tabellenvariablen 
oder in der tempdb erstellte nicht temporäre Tabellen umfassen, 
von langen Rollback-Zeiten und hohem Transaktionsprotokollverbrauch 
betroffen sein. Das Auslaufen des tempdb Transaktionsprotokollspeichers 
kann zu erheblichen Unterbrechungen und Anwendungsausfallzeiten führen.


*/

-- ADR für die tempdb einschalten
ALTER DATABASE tempdb set Accelerated_database_recovery = ON
--Neustart SQL Server!

-- Status der ADR-Einstellung aller Datenbanken prüfen
select name,is_accelerated_database_recovery_on from sys.databases
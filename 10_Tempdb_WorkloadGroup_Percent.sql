/* Prüfung

SELECT file_id,
       name,
       size * 8. / 1024 AS size_mb,
       IIF(max_size = -1, NULL, max_size * 8. / 1024) AS maxsize_mb,
       IIF(is_percent_growth = 0, growth * 8. / 1024, NULL) AS filegrowth_mb,
       IIF(is_percent_growth = 1, growth, NULL) AS filegrowth_percent
FROM sys.master_files
WHERE database_id = 2
      AND
      type_desc = 'ROWS';


USE tempdb;
GO
SELECT 
    name AS FileName, 
    size * 8 / 1024 AS SizeMB,     -- Aktuelle Größe der Datei
    file_id
FROM sys.database_files
WHERE type_desc = 'ROWS';          -- Nur Datendateien (kein Log)
 */

 /* TEMPDB Workload Group Limits für Tempdb

  Ab SQL Server 2022 (16.x) können Sie die Ressourcengovernor-Workload-Gruppen so konfigurieren, 
  dass sie die Nutzung von tempdb-Daten einschränken. 
  Dies ist besonders nützlich in gemeinsam genutzten Umgebungen, 
  in denen mehrere Workloads um die Ressourcen der tempdb konkurrieren.
  Mit dieser Funktion können Sie sicherstellen, 
  dass keine einzelne Workload die tempdb übermäßig beansprucht, 
  was zu Leistungsproblemen für andere Workloads führen könnte.
  */

 --Festlegen eines Grenzwertes in MB für Defaul WLgroup

----------------------------------------------
 --Zurücksetzen aller Werte und Kontrolle
ALTER WORKLOAD GROUP [default]
WITH (GROUP_MAX_TEMPDB_DATA_MB = NULL, GROUP_MAX_TEMPDB_DATA_PERCENT = NULL);
ALTER RESOURCE GOVERNOR RECONFIGURE;

ALTER DATABASE tempdb MODIFY FILE (NAME = N'tempdev', MAXSIZE = UNLIMITED);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp2', FILEGROWTH = 64 MB, MAXSIZE = UNLIMITED);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp3', FILEGROWTH = 64 MB, MAXSIZE = UNLIMITED);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp4', FILEGROWTH = 64 MB, MAXSIZE = UNLIMITED);

drop table if exists #t1;
drop table if exists #t2;
drop table if exists #t3;
drop table if exists #t4;


--Kontrolle der aktuellen Werte

SELECT group_id,       name,
       group_max_tempdb_data_mb,
       group_max_tempdb_data_percent
FROM sys.resource_governor_workload_groups
WHERE name = 'default';
----------------------------------------------

-----------------------------
--DEMO
-----------------------------

-----------------------------------------------
-- Festelegen einers Limits pro Workload Groupt
-----------------------------------------------



--Festlegen auf Maximalen Verbrauch in MB
ALTER WORKLOAD GROUP [default] WITH (GROUP_MAX_TEMPDB_DATA_MB = 100);
ALTER RESOURCE GOVERNOR RECONFIGURE;

--Worklad Group prüfen
SELECT group_id,
       name,
       group_max_tempdb_data_mb,
       group_max_tempdb_data_percent
FROM sys.resource_governor_workload_groups
WHERE name = 'default';

SELECT * INTO #t1 FROM sys.messages where language_id=1031; --96MB..sollte gehen

SELECT * INTO #t2 FROM sys.messages; --96MB..sollte nicht gehen


--Aktuellen Verbrauch der tempdb prüfen

SELECT group_id,       name,
       tempdb_data_space_kb
FROM sys.dm_resource_governor_workload_groups
WHERE name = 'default';

--Erhöhen des Limits:
ALTER WORKLOAD GROUP [default] WITH (GROUP_MAX_TEMPDB_DATA_MB = 250);
ALTER RESOURCE GOVERNOR RECONFIGURE;

--sollte nun gehen
drop table if exists #t1
SELECT * INTO #t2 FROM sys.messages; --96MB


-----------------------------------------------------
-- DEMO 
-- Festelegen eines tempdb Limits
-----------------------------------------------------

ALTER DATABASE tempdb MODIFY FILE (NAME = N'tempdev', MAXSIZE = 256 MB);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp2', FILEGROWTH = 64 MB, MAXSIZE = 256 MB);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp3', FILEGROWTH = 64 MB, MAXSIZE = 256 MB);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp4', FILEGROWTH = 64 MB, MAXSIZE = 256 MB);



--Wie voll ist tempdb aktuell?
SELECT group_id,name,tempdb_data_space_kb, peak_tempdb_data_space_kb,
       total_tempdb_data_limit_violation_count
FROM sys.dm_resource_governor_workload_groups
WHERE name = 'default';

ALTER WORKLOAD GROUP [default] WITH (GROUP_MAX_TEMPDB_DATA_MB = 300);
ALTER RESOURCE GOVERNOR RECONFIGURE;


SELECT * INTO #t3 FROM sys.messages; --96MB
SELECT * INTO #t4 FROM sys.messages; --96MB

-- Durch das Limit der tempdb-Dateien wird der Insert fehlschlagen,
-- obwohl noch Platz in tempdb ist.
-- Daher sind feste Limits mit Vorsicht zu genießen.

---------------------------------------------------------------------------
-- Neu ist, dass die tempdb -Nutzung pro Workload Group auch in Prozent
-- angegeben werden kann.
-- wächst die tempdb, wächst auch die erlaubte Nutzung für die Workload Group.
---------------------------------------------------------------------------


--Cleanup

ALTER WORKLOAD GROUP [default]
WITH (GROUP_MAX_TEMPDB_DATA_MB = NULL, GROUP_MAX_TEMPDB_DATA_PERCENT = NULL);
ALTER RESOURCE GOVERNOR RECONFIGURE;

ALTER DATABASE tempdb MODIFY FILE (NAME = N'tempdev', MAXSIZE = UNLIMITED);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp2', FILEGROWTH = 64 MB, MAXSIZE = UNLIMITED);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp3', FILEGROWTH = 64 MB, MAXSIZE = UNLIMITED);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp4', FILEGROWTH = 64 MB, MAXSIZE = UNLIMITED);

drop table if exists #t1;
drop table if exists #t2;
drop table if exists #t3;
drop table if exists #t4;

--Kontrolle
SELECT group_id,name,tempdb_data_space_kb
FROM sys.dm_resource_governor_workload_groups
WHERE name = 'default';

SELECT group_id,name,group_max_tempdb_data_mb,group_max_tempdb_data_percent
FROM sys.resource_governor_workload_groups
WHERE name = 'default';


-------------------------------------
--- Nun % Limits
-------------------------------------


/*

* Angabe in Prozent in der Workload Group
* sorgt dafür, dass die Grenze dynamisch an die Größe der tempdb-Dateien angepasst wird.
* Wächst die tempdb, wächst auch die erlaubte Nutzung für die Workload Group.
* Dies ist besonders nützlich in Umgebungen, in denen die tempdb-Größe variieren kann.
* Dadurch wird sichergestellt, dass die Workload Group immer einen angemessenen Anteil der tempdb-Ressourcen nutzen kann,
* ohne dass eine feste Grenze überschritten wird.
* Dies hilft, die Leistung und Stabilität der Datenbankumgebung zu gewährleisten,
* insbesondere in Szenarien mit wechselnden Workloads und tempdb-Nutzungen.


Hier gelten aber bestimmte Rahmenbedungen:
https://learn.microsoft.com/en-us/sql/relational-databases/resource-governor/tempdb-space-resource-governance?view=sql-server-ver17

- GROUP_MAX_TEMPDB_DATA_MB ist nicht festgelegt
- Für alle Datendateien gilt: MAXSIZE ist nicht UNLIMITED
- Für alle Datendateien gilt: FILEGROWTH ist nicht null	

tempdbDatendateien können automatisch auf ihre maximale Größe anwachsen.	

Die Summe der MAXSIZEWerte für alle Datendateien	100%

- GROUP_MAX_TEMPDB_DATA_MB ist nicht festgelegt
- Für alle Datendateien MAXSIZEgilt: UNLIMITED
- Für alle Datendateien FILEGROWTH gilt: Null	
tempdbDie Datendateien sind bereits auf ihre vorgesehene Größe voreingestellt 
und können nicht weiter wachsen.	
Die Summe der SIZEWerte für alle Datendateien	100%

Alle anderen Konfigurationen			NEIN
*/

--evtl Neustart und mehrfach ausführen, bis tempdb wieder klein ist
USE [tempdb]
GO
DBCC SHRINKFILE (N'tempdev' , 8)
DBCC SHRINKFILE (N'temp2' ,   8)
DBCC SHRINKFILE (N'temp3' ,   8)
DBCC SHRINKFILE (N'temp4' ,   8)
DBCC SHRINKFILE (N'templog' , 1)
GO

ALTER DATABASE tempdb MODIFY FILE (NAME = N'tempdev',FILEGROWTH = 1 MB);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp2', FILEGROWTH = 1 MB);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp3', FILEGROWTH = 1 MB);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp4', FILEGROWTH = 1 MB);

ALTER DATABASE tempdb MODIFY FILE (NAME = N'tempdev', MAXSIZE = 20 MB);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp2',   MAXSIZE = 20 MB);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp3',   MAXSIZE = 20 MB);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp4',   MAXSIZE = 20 MB);


---Akt Status der Dateien --------------
SELECT 
    name,
    size * 8 / 1024 AS CurrentSize_MB,
    CASE max_size 
        WHEN -1 THEN 'UNLIMITED' 
        WHEN 0 THEN 'NO_GROWTH' 
        ELSE CAST(max_size * 8 / 1024 AS VARCHAR(20)) 
    END AS MaxSize_MB,
    CASE is_percent_growth 
        WHEN 1 THEN CAST(growth AS VARCHAR(10)) + '%' 
        ELSE CAST(growth * 8 / 1024 AS VARCHAR(10)) + ' MB' 
    END AS Growth
FROM sys.master_files
WHERE database_id = DB_ID('tempdb');
GO

--Die Prozentangabe in der Workload Group bezieht sich auf die aktuelle Größe aller tempdb-Dateien.--> 8 MB--> 10% : 800kb
ALTER WORKLOAD GROUP [default]
WITH (GROUP_MAX_TEMPDB_DATA_PERCENT = 20); 
ALTER RESOURCE GOVERNOR RECONFIGURE;
--Tabelle mit best Größe anlegen

USE tempdb;
GO

-- 1. Wie groß soll die Tabelle sein? (Hier ändern!)
DECLARE @WunschMB INT =36; -- Beispiel: 100 MB

-- 2. Berechnung: 1 MB ca. 128 Data-Pages (128 * 8KB = 1024KB)
DECLARE @BenötigteZeilen INT = @WunschMB * 128;

-- 3. Tabelle erstellen (falls vorhanden, erst löschen)
CREATE TABLE #t_SizeTest (    Id INT IDENTITY(1,1),
                              Fuellmaterial CHAR(8000) DEFAULT 'X' );
-- 4. Daten generieren (Wir nutzen Systemtabellen als Quelle für viele Zeilen)
INSERT INTO #t_SizeTest (Fuellmaterial) SELECT TOP (@BenötigteZeilen) 'X'
FROM sys.all_columns a CROSS JOIN sys.all_columns b;
-- 5. Ergebnis prüfen
EXEC sp_spaceused '#t_SizeTest';
DROP TABLE IF EXISTS #t_SizeTest;


--nun mit MAX MB
ALTER WORKLOAD GROUP [default]
WITH (GROUP_MAX_TEMPDB_DATA_MB = 500 ); --3,2 MB





--in welcher Gruppe bin ich
SELECT 
    s.session_id,
    g.name as [Workload Group],
    p.name as [Resource Pool]
FROM sys.dm_exec_sessions s
INNER JOIN sys.resource_governor_workload_groups g 
    ON s.group_id = g.group_id
INNER JOIN sys.resource_governor_resource_pools p 
    ON g.pool_id = p.pool_id
WHERE s.session_id = @@SPID;

















ALTER DATABASE tempdb MODIFY FILE (NAME = N'tempdev', FILEGROWTH = 64 MB, MAXSIZE = 256 MB);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp2', FILEGROWTH = 64 MB, MAXSIZE = 256 MB);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp3', FILEGROWTH = 64 MB, MAXSIZE = 256 MB);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp4', FILEGROWTH = 64 MB, MAXSIZE = 256 MB);

ALTER WORKLOAD GROUP [default]
WITH (GROUP_MAX_TEMPDB_DATA_PERCENT = 4);

--Falls ein fester Grenzwert vorliegt, diesen entfernen

ALTER WORKLOAD GROUP [default]
WITH (GROUP_MAX_TEMPDB_DATA_MB = NULL);

ALTER RESOURCE GOVERNOR RECONFIGURE;

---Kontrolle
SELECT group_id,
       name,
       group_max_tempdb_data_mb,
       group_max_tempdb_data_percent
FROM sys.resource_governor_workload_groups
WHERE name = 'default';


--Daten in tempdb
SELECT * INTO #m6 FROM sys.messages;
--Error 1138..wird abgebrochen
drop table #m7;
SELECT *
INTO #m7
FROM sys.messages; --96MB




EXEC tempdb.sys.sp_spaceused '#m6';

--Kontrolle
SELECT group_id,
       name,
       tempdb_data_space_kb,
       peak_tempdb_data_space_kb,
       total_tempdb_data_limit_violation_count
FROM sys.dm_resource_governor_workload_groups
WHERE name = 'default';
--tatal_temdb_data_limit_violation_count wurd erhöht


--Grenze entfernen..
ALTER WORKLOAD GROUP [default]
WITH (GROUP_MAX_TEMPDB_DATA_MB = 512, GROUP_MAX_TEMPDB_DATA_PERCENT = 5);

ALTER WORKLOAD GROUP [default]
WITH (GROUP_MAX_TEMPDB_DATA_MB = NULL, GROUP_MAX_TEMPDB_DATA_PERCENT = NULL);

ALTER RESOURCE GOVERNOR DISABLE;





--Angabe in ProzentALTER DATABASE tempdb MODIFY FILE (NAME = N'tempdev', FILEGROWTH = 64 MB, MAXSIZE = 256 MB);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'tempdev', FILEGROWTH = 64 MB, MAXSIZE = 256 MB);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp2', FILEGROWTH = 64 MB, MAXSIZE = 256 MB);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp3', FILEGROWTH = 64 MB, MAXSIZE = 256 MB);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp4', FILEGROWTH = 64 MB, MAXSIZE = 256 MB);


--Wieviel darf default verwenden-- immer dieselbe Größe in MB, auch wenn die DAteien größer werden dürfen?

ALTER WORKLOAD GROUP [default]
WITH (GROUP_MAX_TEMPDB_DATA_PERCENT = 5);

ALTER RESOURCE GOVERNOR RECONFIGURE;

--Aktuell Settings abfragen
SELECT group_id,
       name,
       group_max_tempdb_data_mb,
       group_max_tempdb_data_percent
FROM sys.resource_governor_workload_groups
WHERE name = 'default';





--ENDE


--TempDB 

SELECT file_id,
       name,
       size * 8. / 1024 AS size_mb,
       IIF(max_size = -1, NULL, max_size * 8. / 1024) AS maxsize_mb,
       IIF(is_percent_growth = 0, growth * 8. / 1024, NULL) AS filegrowth_mb,
       IIF(is_percent_growth = 1, growth, NULL) AS filegrowth_percent
FROM sys.master_files
WHERE database_id = 2
      AND
      type_desc = 'ROWS';
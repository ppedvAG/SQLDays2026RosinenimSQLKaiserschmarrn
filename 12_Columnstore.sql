/*
Neu in SQL Server 2025: Sortierte (ORDER) Columnstore-Indizes und Online-Neuaufbau
Ein Columnstore-Index speichert Daten spaltenweise in komprimierten Segmenten (Rowgroups mit
bis zu ca. 1 Million Zeilen). Er ist ideal für Analyseabfragen mit Aggregationen über viele Zeilen.
Jedes Segment kennt Minimum und Maximum seiner Werte, so kann die Engine ganze Segmente überspringen
(Segment Elimination), wenn der Filter nicht passt. Das funktioniert nur gut, wenn die Daten nach der
Filterspalte sortiert sind.
Neu in SQL Server 2025:
  - ORDER (spalte) bei einem nicht gruppierten Columnstore-Index (NCCI): Die Daten werden beim Aufbau
    nach der angegebenen Spalte sortiert, dadurch überlappen sich die Wertebereiche der Segmente kaum
    und Segment Elimination wird sehr wirksam.
  - ONLINE = ON beim Erstellen/Neuaufbau eines sortierten Columnstore-Index: Die Tabelle bleibt während
    des Neuaufbaus les- und schreibbar. MAXDOP steuert den Parallelitätsgrad (MAXDOP = 1 liefert die beste Sortierung).
Das Skript vergleicht eine Abfrage mit Gruppierung über demo.Bestellung ohne Index, mit klassischem
nicht gruppierten Index, mit Columnstore, mit sortiertem Columnstore und prüft die Rowgroups über die
Sichten sys.dm_db_column_store_row_group_physical_stats/_operational_stats.
SET STATISTICS IO, TIME zeigt Lesevorgänge und CPU-Zeit.
*/

-- Anzahl der Zeilen (Tabelle mit ca. 1 Million Bestellungen)
select count(*) from demo.bestellung

-- Lesevorgänge und CPU-Zeit anzeigen, um die Varianten zu vergleichen
SET STATISTICS IO, TIME ON 

-- Zeitraum der Daten ermitteln
select min(bestelldatum), max(bestelldatum) from demo.bestellung

-- Analyseabfrage: Umsatz pro Kunde im Jahr 2024, zunächst ohne passenden Index
select Kundenid, sum(Betrag)from demo.bestellung
where bestelldatum between '1.1.2024' and '31.12.2024'
group by Kundenid

-- Klassischer nicht gruppierter Zeilenindex mit INCLUDE-Spalten (Covering Index)
CREATE NONCLUSTERED INDEX NIX1
ON [demo].[Bestellung] ([Bestelldatum])
INCLUDE ([KundenID],[Betrag])

select Kundenid, sum(Betrag)from demo.bestellung
where bestelldatum between '1.1.2024' and '31.12.2024'
group by Kundenid

--NONCLUSTERED COLUMNSTORE INDEX: spaltenweise, komprimierte Speicherung für Analyseabfragen
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI1
ON demo.bestellung (Kundenid, Betrag, Bestelldatum)

select Kundenid, sum(Betrag)from demo.bestellung
where bestelldatum between '1.1.2024' and '31.12.2024'
group by Kundenid


-- Rowgroups prüfen: Größe, Zustand und Komprimierung der Segmente
select * from sys.dm_db_column_store_row_group_physical_stats
select * from sys.dm_db_column_store_row_group_operational_stats


-- Neu in SQL 2025: sortierter Columnstore mit ORDER; Online-Aufbau (ONLINE = ON) ohne Sperre der Tabelle
-- Mit MAXDOP = 8 wird parallel gebaut, die Sortierung ist dabei weniger perfekt
CREATE NONCLUSTERED COLUMNSTORE INDEX NCLCS
ON demo.bestellung (Kundenid, Betrag, Bestelldatum) 
ORDER  (bestelldatum) 
WITH (DROP_EXISTING = ON,ONLINE = ON, MAXDOP = 8);--MAXDOP=1


select Kundenid, sum(Betrag)from demo.bestellung
where bestelldatum between '1.1.2024' and '31.12.2024'
group by Kundenid


-- Dasselbe mit MAXDOP = 1: Single-Thread-Aufbau liefert die beste Sortierung und damit die beste Segment Elimination
CREATE NONCLUSTERED COLUMNSTORE INDEX NCLCS
ON demo.bestellung (Kundenid, Betrag, Bestelldatum) 
ORDER  (bestelldatum) 
WITH (DROP_EXISTING = ON,ONLINE = ON, MAXDOP = 1);--MAXDOP=1


select Kundenid, sum(Betrag)from demo.bestellung
where bestelldatum between '1.1.2024' and '31.12.2024'
group by Kundenid



-- Offline-Rebuild: Die Tabelle ist währenddessen gesperrt
ALTER INDEX NCLCS ON demo.bestellung REBUILD;
--Abfrage in zweitem Fenster starten.. läuft und läuft

-- Online-Rebuild: Abfragen bleiben währenddessen möglich
ALTER INDEX NCLCS ON demo.bestellung
REBUILD WITH (ONLINE = ON); 


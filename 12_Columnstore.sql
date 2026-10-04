select count(*) from demo.bestellung

SET STATISTICS IO, TIME ON 

select min(bestelldatum), max(bestelldatum) from demo.bestellung

select Kundenid, sum(Betrag)from demo.bestellung
where bestelldatum between '1.1.2024' and '31.12.2024'
group by Kundenid

CREATE NONCLUSTERED INDEX NIX1
ON [demo].[Bestellung] ([Bestelldatum])
INCLUDE ([KundenID],[Betrag])

select Kundenid, sum(Betrag)from demo.bestellung
where bestelldatum between '1.1.2024' and '31.12.2024'
group by Kundenid

--NIN CLUSTERED INDEX
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI1
ON demo.bestellung (Kundenid, Betrag, Bestelldatum)

select Kundenid, sum(Betrag)from demo.bestellung
where bestelldatum between '1.1.2024' and '31.12.2024'
group by Kundenid


select * from sys.dm_db_column_store_row_group_physical_stats
select * from sys.dm_db_column_store_row_group_operational_stats


CREATE NONCLUSTERED COLUMNSTORE INDEX NCLCS
ON demo.bestellung (Kundenid, Betrag, Bestelldatum) 
ORDER  (bestelldatum) 
WITH (DROP_EXISTING = ON,ONLINE = ON, MAXDOP = 8);--MAXDOP=1


select Kundenid, sum(Betrag)from demo.bestellung
where bestelldatum between '1.1.2024' and '31.12.2024'
group by Kundenid


CREATE NONCLUSTERED COLUMNSTORE INDEX NCLCS
ON demo.bestellung (Kundenid, Betrag, Bestelldatum) 
ORDER  (bestelldatum) 
WITH (DROP_EXISTING = ON,ONLINE = ON, MAXDOP = 1);--MAXDOP=1


select Kundenid, sum(Betrag)from demo.bestellung
where bestelldatum between '1.1.2024' and '31.12.2024'
group by Kundenid



ALTER INDEX NCLCS ON demo.bestellung REBUILD;
--Abfrage in zweitem Fenster starten.. läuft und läuft

ALTER INDEX NCLCS ON demo.bestellung
REBUILD WITH (ONLINE = ON); 


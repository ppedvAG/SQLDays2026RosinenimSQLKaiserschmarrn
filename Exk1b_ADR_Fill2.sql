/*
Exkurs ADR, Teil 2: Rollback-Dauer mit und ohne ADR messen
Voraussetzung: Die Datenbanken OldStyle (ohne ADR) und NewStyle (mit ADR) aus Exk1a_ADR_SETUP.sql.
Die Demo führt in beiden Datenbanken exakt dieselbe große Transaktion aus und misst die Rollback-Zeit:
  1. Tabelle test1 mit Index anlegen.
  2. In einer offenen Transaktion 400.000 Zeilen per Schleife einfügen, alle Zeilen ändern und danach löschen.
  3. Die Dauer dieser Arbeit in Millisekunden ausgeben (DATEDIFF).
  4. ROLLBACK ausführen und die Dauer messen.
Erwartetes Ergebnis:
  - OldStyle: Das Rollback dauert lange, weil jede Protokollzeile rückwärts rückgängig gemacht werden muss.
  - NewStyle (ADR): Das Rollback ist fast sofort fertig, weil nur die Version aus dem Persistent Version Store
    sichtbar wird und die Bereinigung später im Hintergrund erfolgt.
Hinweis: Die Transaktion bewusst ohne COMMIT lassen; die Zeitmessung beim Rollback im selben Batch
oder, wie im Skript, in einem eigenen Batch mit neu gesetzter Startzeit ausführen.
Anschließend den Zustand des PVS mit Exk1c__ADR Cleanup.sql prüfen.
*/


-- Teil 1: Datenbank ohne ADR (OldStyle)
USE OldStyle

GO


drop table if exists test1;-
GO
-- Testtabelle mit Nonclustered Index: Der Index erzeugt zusaetzliche Protokollmengen
create table test1(id int, spx char(50), nummer int, Datum datetime);
GO
create index nix on test1(id asc);
GO

---------------------START DEMO-------------------------
DECLARE @Start datetime2 = SYSDATETIME();

-- Grosse Transaktion bewusst offen lassen: 400.000 Zeilen einfuegen, aendern und loeschen
Begin tran

declare @i as int= 1
while @i< 400000
	begin
		insert into test1 
		select @i,'XY', @i, GETDATE()
		set @i+=1
	end

update test1 set nummer = 100000, Datum= GETDATE()

delete from test1

DECLARE @Ende datetime2 = SYSDATETIME();
-- Dauer in Millisekunden berechnen
SELECT DATEDIFF(MILLISECOND, @Start, @Ende) AS Dauer_in_ms;


--ROLLBACK
--DECLARE @Start datetime2 = SYSDATETIME();
-- Rollback der gesamten Transaktion: Ohne ADR muss das Protokoll rückwärts abgearbeitet werden
-- (Die Startzeit muss hier bereits gesetzt sein, ggf. Skript in einem Zug markieren)

ROLLBACK

DECLARE @Ende datetime2 = SYSDATETIME();
-- Dauer in Millisekunden berechnen
SELECT DATEDIFF(MILLISECOND, @Start, @Ende) AS Dauer_in_ms;



-----NUN MIT ADR IN NEWSTYLE: dieselbe Transaktion, aber mit Persistent Version Store
USE NewStyle;
GO

drop table if exists test1;--create or alter
GO
create table test1(id int, spx char(50), nummer int, Datum datetime);
GO
create index nix on test1(id asc);
GO

---------------------START DEMO-------------------------
DECLARE @Start datetime2 = SYSDATETIME();

Begin tran

declare @i as int= 1
while @i< 400000
	begin
		insert into test1 
		select @i,'XY', @i, GETDATE()
		set @i+=1
	end

update test1 set nummer = 100000, Datum= GETDATE()

delete from test1

DECLARE @Ende datetime2 = SYSDATETIME();
-- Dauer in Millisekunden berechnen
SELECT DATEDIFF(MILLISECOND, @Start, @Ende) AS Dauer_in_ms;


--Was ist im PVS?
--Skript Exk1c__ADR Cleanup.sql ausführen (zeigt PVS-Größe und Cleaner-Status)

--ROLLBACK mit ADR: sollte praktisch sofort beendet sein
DECLARE @Start datetime2 = SYSDATETIME();

ROLLBACK

DECLARE @Ende datetime2 = SYSDATETIME();
-- Dauer in Millisekunden berechnen
SELECT DATEDIFF(MILLISECOND, @Start, @Ende) AS Dauer_in_ms;



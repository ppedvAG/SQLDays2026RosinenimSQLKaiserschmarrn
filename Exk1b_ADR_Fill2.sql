
USE OldStyle

GO


drop table if exists test1;-
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


--ROLLBACK
--DECLARE @Start datetime2 = SYSDATETIME();

ROLLBACK

DECLARE @Ende datetime2 = SYSDATETIME();
-- Dauer in Millisekunden berechnen
SELECT DATEDIFF(MILLISECOND, @Start, @Ende) AS Dauer_in_ms;



-----NUN MIT ADR IN NEWSTYLE
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
--Script Nnr2_ADR_Cleanup.sql ausführen

--ROLLBACK
DECLARE @Start datetime2 = SYSDATETIME();

ROLLBACK

DECLARE @Ende datetime2 = SYSDATETIME();
-- Dauer in Millisekunden berechnen
SELECT DATEDIFF(MILLISECOND, @Start, @Ende) AS Dauer_in_ms;



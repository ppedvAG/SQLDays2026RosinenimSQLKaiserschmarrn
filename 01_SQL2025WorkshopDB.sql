USE master;
GO
IF DB_ID(N'SQL2025Workshop') IS NOT NULL
BEGIN
 ALTER DATABASE SQL2025Workshop SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
 DROP DATABASE SQL2025Workshop;
END;
GO
CREATE DATABASE SQL2025Workshop;
GO
ALTER DATABASE SQL2025Workshop SET COMPATIBILITY_LEVEL=170;
GO
USE SQL2025Workshop;
GO
CREATE SCHEMA demo AUTHORIZATION dbo;
GO
CREATE TABLE demo.KontaktImport(
 KontaktID int IDENTITY PRIMARY KEY, Firmenname nvarchar(100) NOT NULL,
 EMail varchar(200), Telefon varchar(50), Freitext nvarchar(400));
INSERT demo.KontaktImport(Firmenname,EMail,Telefon,Freitext) VALUES
(N'Alfreds Futterkiste','maria@alfreds.de','+49 30 1234-567',N'Kunde: A-100; Region: Nord'),
(N'Alfred Futterkiste','maria.alfreds.de','030/1234567',N'Kunde: A-101; Region: Nord'),
(N'Blauer See GmbH','info@blauer-see.de','+49 (40) 778899',N'Kunde: B-200; Region: West'),
(N'Blaur See GmbH','kontakt@blauer-see.de','040 778899',N'Kunde: B-201; Region: West'),
(N'Königlich Essen','office@koeniglich.de',NULL,N'Kunde: K-300; Region: Süd');



CREATE TABLE demo.Bestellung(
 BestellungID bigint IDENTITY PRIMARY KEY,KundenID int NOT NULL,
 Bestelldatum date NOT NULL,Betrag decimal(12,2) NOT NULL);
WITH n AS(
 SELECT TOP(1000000) ROW_NUMBER() OVER(ORDER BY(SELECT NULL)) rn
 FROM sys.all_objects a CROSS JOIN sys.all_objects b)
INSERT demo.Bestellung(KundenID,Bestelldatum,Betrag)
SELECT CASE WHEN rn<=70000 THEN 1 WHEN rn<=85000 THEN 2 ELSE 3+(rn%997) END,
 DATEADD(day,-(rn%730),CONVERT(date,CURRENT_TIMESTAMP)),
 CONVERT(decimal(12,2),10+(rn%5000)/10.0) FROM n;
CREATE INDEX IX_Bestellung_KundenID ON demo.Bestellung(KundenID)
INCLUDE(Bestelldatum,Betrag);
GO

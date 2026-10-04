-- SQL Server 2025 hat eine neu KOmpressionsart für Back eingeführt. 
-- ZSTD ist eine neue Kompressionsart, die in SQL Server 2025 verfügbar ist. 
-- Sie bietet eine bessere Kompression im Vergleich zu den bisherigen Methoden 
-- und kann die Größe von Backups erheblich reduzieren.
--Bisherige Backup Kompressionsarten sind MS_XPRESS, QAT 


set statistics  time on 
-- Klassischer MS_XPRESS-Standard
BACKUP DATABASE SQL2025Workshop
TO DISK = N'C:\_SQLBACKUP\SQL2025WorkshopMSX.bak'
WITH COMPRESSION (ALGORITHM = MS_XPRESS), FORMAT, STATS=10; --(165.658 MB/s).



-- Standard ZSTD-Komprimierung (nutzt implizit LEVEL = LOW)
-- Je höher der Levl, desto besser die Kompression, aber desto langsamer die Backup-Geschwindigkeit und CPU Aufwand


-- ZSTD mit spezifischem Kompressionsgrad
BACKUP DATABASE SQL2025Workshop
TO DISK = N'C:\_SQLBACKUP\SQL2025WorkshopZMED.bak'
WITH COMPRESSION (ALGORITHM = ZSTD, LEVEL = MEDIUM),FORMAT, STATS=10;


BACKUP DATABASE SQL2025Workshop
TO DISK = N'C:\_SQLBACKUP\SQL2025Workshoplow.bak'
WITH COMPRESSION (ALGORITHM = ZSTD, LEVEL = LOW),FORMAT, STATS=10;


BACKUP DATABASE SQL2025Workshop
TO DISK = N'C:\_SQLBACKUP\SQL2025Workshophigh.bak'
WITH COMPRESSION (ALGORITHM = ZSTD, LEVEL = HIGH);



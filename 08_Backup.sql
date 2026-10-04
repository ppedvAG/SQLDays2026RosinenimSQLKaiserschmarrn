/*
Neu in SQL Server 2025: ZSTD-Backupkomprimierung
Bisher bot SQL Server als Backup-Komprimierung MS_XPRESS (Standard) und, mit Hardwarebeschleunigung, QAT an.
SQL Server 2025 ergänzt den Algorithmus ZSTD (Zstandard) mit wählbarer Kompressionsstufe:
  LEVEL = LOW (Standard), MEDIUM oder HIGH.
Funktionsweise: Mit der Syntax COMPRESSION (ALGORITHM = ZSTD, LEVEL = ...) wird der Algorithmus pro Backup festgelegt.
Eine höhere Stufe erzeugt kleinere Backupdateien, benötigt aber mehr CPU-Zeit und dauert länger;
LOW ist schneller bei etwas geringerer Kompression.
Typischer Vorteil gegenüber MS_XPRESS: bessere Kompressionsrate bei vergleichbarer oder besserer
Geschwindigkeit, dadurch weniger Speicherplatz und geringere Netzwerkbelastung bei Sicherungen.
Das Skript sichert die Datenbank SQL2025Workshop viermal (MS_XPRESS, ZSTD LOW/MEDIUM/HIGH).
SET STATISTICS TIME und STATS zeigen die Dauer und den Durchsatz. Anschließend vergleicht man die
Dateigrößen im Ordner C:\_SQLBACKUP.
Hinweis: Das Zielverzeichnis muss existieren und für das SQL-Server-Dienstkonto beschreibbar sein.
*/

-- SQL Server 2025 hat eine neue Kompressionsart für Backups eingeführt. 
-- ZSTD ist eine neue Kompressionsart, die in SQL Server 2025 verfügbar ist. 
-- Sie bietet eine bessere Kompression im Vergleich zu den bisherigen Methoden 
-- und kann die Größe von Backups erheblich reduzieren.
--Bisherige Backup-Kompressionsarten sind MS_XPRESS und QAT. 


-- Zeitmessung einschalten, STATS=10 zeigt den Fortschritt in 10-%-Schritten
set statistics  time on 
-- Klassischer MS_XPRESS-Standard
BACKUP DATABASE SQL2025Workshop
TO DISK = N'C:\_SQLBACKUP\SQL2025WorkshopMSX.bak'
WITH COMPRESSION (ALGORITHM = MS_XPRESS), FORMAT, STATS=10; --(165.658 MB/s).



-- Standard ZSTD-Komprimierung (nutzt implizit LEVEL = LOW), siehe das Backup mit LEVEL = LOW weiter unten
-- Je höher der Level, desto besser die Kompression, aber desto langsamer die Backup-Geschwindigkeit und CPU Aufwand


-- ZSTD mit spezifischem Kompressionsgrad (MEDIUM): bessere Kompression, mehr CPU
BACKUP DATABASE SQL2025Workshop
TO DISK = N'C:\_SQLBACKUP\SQL2025WorkshopZMED.bak'
WITH COMPRESSION (ALGORITHM = ZSTD, LEVEL = MEDIUM),FORMAT, STATS=10;


-- ZSTD mit LEVEL = LOW: schnell, geringste Kompression der ZSTD-Stufen
BACKUP DATABASE SQL2025Workshop
TO DISK = N'C:\_SQLBACKUP\SQL2025Workshoplow.bak'
WITH COMPRESSION (ALGORITHM = ZSTD, LEVEL = LOW),FORMAT, STATS=10;


-- ZSTD mit LEVEL = HIGH: kleinste Datei, höchster CPU-Aufwand und längste Laufzeit
-- Danach die Dateigrößen im Ordner C:\_SQLBACKUP vergleichen
BACKUP DATABASE SQL2025Workshop
TO DISK = N'C:\_SQLBACKUP\SQL2025Workshophigh.bak'
WITH COMPRESSION (ALGORITHM = ZSTD, LEVEL = HIGH);



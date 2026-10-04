/*
Admin-Skript: Accelerated Database Recovery (ADR) in der tempdb aktivieren
Neu ab SQL Server 2025 (17.x): ADR kann auch für die Systemdatenbank tempdb eingeschaltet werden.
Bisher war ADR nur in Benutzerdatenbanken möglich.
Hintergrund: ADR speichert Zeilenversionen im Persistent Version Store (PVS) und schreibt das Protokoll so,
dass Rollback und Recovery in nahezu konstanter Zeit abgeschlossen sind - unabhängig von der Größe der Transaktion.
Problem ohne ADR in der tempdb: Selbst bei minimaler Protokollierung können Transaktionen mit temporären Objekten
(#-Tabellen, Tabellenvariablen, in der tempdb angelegte Tabellen) lange zurückgerollt werden und viel
Transaktionsprotokoll beanspruchen. Läuft das tempdb-Protokoll voll, führt das zu Ausfällen der Anwendungen.
Vorgehen:
  1. ALTER DATABASE tempdb SET ACCELERATED_DATABASE_RECOVERY = ON.
  2. SQL-Server-Dienst neu starten, damit die Einstellung wirksam wird.
  3. Mit sys.databases (is_accelerated_database_recovery_on) den Status prüfen.
Nach der Aktivierung sollte der Speicherplatz der tempdb (PVS) überwacht werden.
Das Skript dient als Administrationsvorlage und ist unabhängig von den Demodatenbanken.
*/

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

-- ADR in der tempdb einschalten
ALTER DATABASE tempdb set Accelerated_database_recovery = ON
--Neustart SQL Server!

-- Kontrolle des Status (1 = ADR aktiv)
select name,is_accelerated_database_recovery_on from sys.databases
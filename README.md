# SQLDays 2026 – Rosinen im SQL Kaiserschmarrn

Demo-Skripte zum Workshop über die Neuerungen in **SQL Server 2025 (17.x)**.
Die Dateien sind nummeriert und sollten in dieser Reihenfolge ausgeführt bzw. gezeigt werden.
Jedes Skript ab Nr. 03 beginnt mit einem Kommentar, der die Neuerung und ihre Funktionsweise erklärt.

## Voraussetzungen

- SQL Server 2025 (Developer oder Enterprise Edition), SSMS oder VS Code mit der MSSQL-Erweiterung
- Datenbank `SQL2025Workshop` mit Kompatibilitätsgrad 170 (wird in Skript 01 angelegt)
- Für die KI-Demo: Ollama, nginx und mkcert (siehe [06_AI_Setup.md](06_AI_Setup.md))
- Für Backup- und tempdb-Demos: Testsystem mit Administratorrechten (Ordner `C:\_SQLBACKUP` anlegen)

## Vorbereitung

| Datei | Inhalt |
|---|---|
| `00_Systemcheck.sql` | Prüft Version, Edition und Kompatibilitätsgrade der Datenbanken |
| `01_SQL2025WorkshopDB.sql` | Erstellt die Datenbank `SQL2025Workshop` mit Schema `demo`, `demo.KontaktImport` und `demo.Bestellung` (1 Mio. Zeilen) |
| `02_NorthwindDB.txt` / `02a_NorthwindDB.sql` | Northwind-Beispieldatenbank (Textfassung und SQL-Skript) für die KI-Demo |
| `02b_Spieltabelle mit ID.sql` | Erzeugt die Tabelle `KundenUmsatz` aus Northwind und vergrößert sie für Tests |

## T-SQL-Neuerungen

| Datei | Thema |
|---|---|
| `03_RegEx.sql` | Reguläre Ausdrücke: `REGEXP_LIKE`, `REGEXP_REPLACE`, `REGEXP_SUBSTR`, `REGEXP_INSTR`, `REGEXP_COUNT`, `REGEXP_SPLIT_TO_TABLE` |
| `03_TSQL_DATETRUNC.sql` | `DATETRUNC` zum Abschneiden von Datums- und Zeitwerten |
| `03_TSQL_neue Funktionen.sql` | `CURRENT_DATE`, Operator `\|\|`, `PRODUCT`, `SUBSTRING` ohne Länge |
| `04_Fuzzy.sql` | Fuzzy String Matching: `EDIT_DISTANCE`, `EDIT_DISTANCE_SIMILARITY`, `JARO_WINKLER_SIMILARITY` (Dublettensuche) |
| `05_Json.sql` | Nativer Datentyp `json`, `CREATE JSON INDEX`, `JSON_ARRAYAGG`, `JSON_CONTAINS` |

## KI und Vektoren

| Datei | Thema |
|---|---|
| `06_AI_Setup.md` | Einrichtung von Ollama, nginx und mkcert für den lokalen HTTPS-Endpunkt |
| `06_Aktiviern_AI_SQLDB.sql` | Externes Modell, `AI_GENERATE_EMBEDDINGS`, `AI_GENERATE_CHUNKS`, Vektorindex, `VECTOR_SEARCH` mit Northwind |
| `06_MiniDemo.sql` | Kurzdemo `vector`-Datentyp und `VECTOR_DISTANCE` ohne KI-Modell |

## Intelligent Query Processing und Engine

| Datei | Thema |
|---|---|
| `07_OPPO.sql` | Optional Parameter Plan Optimization (OPPO) mit Query Store |
| `08_Backup.sql` | Backup-Komprimierung mit ZSTD (LOW, MEDIUM, HIGH) im Vergleich zu MS_XPRESS |
| `09_OptimizedLocking.sql` | Optimized Locking: Überblick, Aktivierung (ADR, RCSI) und Sperrenkontrolle |
| `09a_OptimizedLocking.sql` | Optimized-Locking-Demo, **Session 1** (offene Transaktion, Umschalten des Features) |
| `09b_OptimizedLocking.sql` | Optimized-Locking-Demo, **Session 2** (Sperren beobachten, parallele Updates) |
| `10_TempDB_Settings.sql` | tempdb: speicheroptimierte Metadaten und ADR |
| `10_Tempdb_WorkloadGroup_Percent.sql` | tempdb-Platzbegrenzung pro Workload Group (Resource Governor, MB und Prozent) |
| `11_Optimizef_ExceuteSQL.sql` | `OPTIMIZED_SP_EXECUTESQL` und Plan-Cache-Verhalten bei dynamischem SQL |
| `12_Columnstore.sql` | Sortierte nicht gruppierte Columnstore-Indizes (`ORDER`) und Online-Neuaufbau |
| `13_PSP_OPO.sql` | Parameter Sensitive Plan (PSP) und Optional Parameter Optimization (OPO) |

## Zusatzskripte und Exkurse

| Datei | Thema |
|---|---|
| `Admin_tempdb_ADR.sql` | Accelerated Database Recovery (ADR) in der tempdb aktivieren |
| `Exk1a_ADR_SETUP.sql` | Exkurs ADR 1: Datenbanken `OldStyle` (ohne ADR) und `NewStyle` (mit ADR) anlegen |
| `Exk1b_ADR_Fill2.sql` | Exkurs ADR 2: Große Transaktion mit Rollback in beiden Datenbanken messen |
| `Exk1c__ADR Cleanup.sql` | Exkurs ADR 3: Persistent Version Store überwachen und bereinigen |

## Hinweise

- Einige Funktionen (Fuzzy Matching, Vektorindex, `VECTOR_SEARCH`, `AI_GENERATE_CHUNKS`) sind noch Preview-Features und benötigen `ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON`.
- Mehrere Skripte ändern Server- oder Datenbankeinstellungen (ADR, tempdb, Resource Governor, Backups). Nur in einer Testumgebung ausführen.
- Die Demos `13_PSP_OPO.sql` benötigen zusätzlich die Datenbank `IQP_Demo2025`.

/*
T-SQL-Funktion DATETRUNC
DATETRUNC(datepart, wert) schneidet einen Datums-/Zeitwert auf die angegebene Genauigkeit ab.
Alle kleineren Bestandteile werden auf ihren Minimalwert zurückgesetzt (Monat -> 1., Zeit -> 00:00:00 ...).
Bisher war dafür ein Umweg nötig, z. B. DATEADD(month, DATEDIFF(month, 0, @d), 0)
oder eine Kombination aus CAST und FORMAT. DATETRUNC ist kürzer, lesbarer und verständlicher.
Unterstützte Teile: year, quarter, month, week, iso_week, dayofyear, day, hour, minute,
second, millisecond und microsecond.
Das Ergebnis behält den Datentyp des Eingabewertes (hier datetime2).
Besonderheiten: 'week' hängt von SET DATEFIRST ab (Standard 7 = Sonntag bei US-Englisch),
'iso_week' beginnt immer am Montag.
Typischer Einsatz: Gruppierung von Umsätzen nach Monat/Quartal/Woche in GROUP BY,
Bildung von Zeitfenstern und Berichtsperioden, einfachere Vergleiche in WHERE-Bedingungen.
Das Skript zeigt alle Datumsteile nacheinander an einem Beispielwert.
Hinweis: Die Funktion wurde mit SQL Server 2022 eingeführt und gehört zu den modernen
T-SQL-Erweiterungen, die im SQL-2025-Workshop als Ergänzung gezeigt werden.
*/

-- Beispielwert mit voller Genauigkeit (7 Nachkommastellen)
DECLARE @d datetime2 = '2021-12-08 11:30:15.1234567';
-- Jede Abfrage schneidet auf die genannte Einheit ab, kleinere Einheiten werden auf ihren Minimalwert gesetzt
SELECT 'Year', DATETRUNC(year, @d); -- 2021-01-01 00:00:00
SELECT 'Quarter', DATETRUNC(quarter, @d); -- Beginn des Quartals: 2021-10-01
SELECT 'Month', DATETRUNC(month, @d); -- Monatsanfang: 2021-12-01
SELECT 'Week', DATETRUNC(week, @d); -- Using the default DATEFIRST setting value of 7 (U.S. English)
SELECT 'Iso_week', DATETRUNC(iso_week, @d); -- ISO-Woche beginnt immer am Montag
SELECT 'DayOfYear', DATETRUNC(dayofyear, @d); -- entspricht day: Tagesanfang
SELECT 'Day', DATETRUNC(day, @d); -- Uhrzeit wird auf 00:00:00 gesetzt
SELECT 'Hour', DATETRUNC(hour, @d); -- Minuten und Sekunden werden entfernt
SELECT 'Minute', DATETRUNC(minute, @d);
SELECT 'Second', DATETRUNC(second, @d);
SELECT 'Millisecond', DATETRUNC(millisecond, @d);
SELECT 'Microsecond', DATETRUNC(microsecond, @d); -- datetime2(7) wird auf 6 Nachkommastellen gekürzt
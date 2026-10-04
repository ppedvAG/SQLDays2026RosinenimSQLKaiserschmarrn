/*
Kleine T-SQL-Neuerungen in SQL Server 2025
Dieses Skript zeigt mehrere kleine Erweiterungen der Sprache, die den Alltag vereinfachen:
1. CURRENT_DATE
   Liefert das aktuelle Datum als Typ date (ISO-/ANSI-SQL-konform), ohne CONVERT(date, GETDATE()).
2. || (Zeichenfolgen-Verkettungsoperator)
   Verkettet Texte nach ANSI-SQL-Standard, Alternative zu + und CONCAT.
   Ist ein Operand NULL, ist das Ergebnis NULL (Verhalten wie beim Operator +, anders als CONCAT).
3. PRODUCT
   Aggregatfunktion, die das Produkt aller Werte einer Spalte bildet (ähnlich wie SUM für die Summe).
   Bisher musste man mit EXP(SUM(LOG(x))) arbeiten, was bei 0 und negativen Zahlen Probleme macht.
4. SUBSTRING ohne Längenangabe
   SUBSTRING(text, start) gibt den Rest des Textes ab der Startposition zurück.
   Bisher war ein dritter Parameter Pflicht, meist mit LEN() als Workaround.
Die Beispiele laufen in der Datenbank SQL2025Workshop (Skript 01).
Alle Neuerungen erfordern SQL Server 2025 bzw. den Kompatibilitätsgrad 170.
*/

USE SQL2025Workshop;

--CURRENT_DATE ist neu in SQL Server 2025 und kann direkt mit dem Befehl CURRENT_DATE abgefragt werden 
-- ohne Angabe von GETDATE() oder ähnlichem.
-- Außerdem ist der Verkettungsoperator || neu: 'SQL'||' Server '||'2025' ergibt 'SQL Server 2025'.
SELECT CURRENT_DATE Heute,'SQL'||' Server '||'2025' Titel;

-- Die Funktion PRODUCT ist neu in SQL Server 2025 und berechnet das Produkt von allen Werten in einer Spalte. 
-- In diesem Beispiel wird das Produkt von 2, 3 und 4 berechnet.
SELECT PRODUCT(v.Wert) Produkt FROM(
									VALUES	(2.0)
											,(3.0)
											,(4.0)
									)  v(Wert);

-- Neu in SQL 2025: SUBSTRING ist jetzt auch ohne Angabe der Länge möglich.
-- Das Ergebnis ist der Rest des Textes ab Position 5, hier 'Server 2025'.
SELECT SUBSTRING('SQL Server 2025',5) OhneLaenge;

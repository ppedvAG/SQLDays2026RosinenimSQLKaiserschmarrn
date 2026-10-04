USE SQL2025Workshop;

--Current Date ist neu in SQL Server 2025 und kann direkt mit dem Befehl CURRENT_DATE abgefragt werden 
-- ohne Angabe von GETDATE() oder ähnlichem.
SELECT CURRENT_DATE Heute,'SQL'||' Server '||'2025' Titel;

-- Der Befehl Product ist neu in SQL Server 2025 und berechnet das Produkt von allen Werten in einer Spalte. 
-- In diesem Beispiel wird das Produkt von 2, 3 und 4 berechnet.
SELECT PRODUCT(v.Wert) Produkt FROM(
									VALUES	(2.0)
											,(3.0)
											,(4.0)
									)  v(Wert);

-- Neu in SQL 2025 Substring ist jetzt auch ohne Angabe der Länge möglich.
SELECT SUBSTRING('SQL Server 2025',5) OhneLaenge;

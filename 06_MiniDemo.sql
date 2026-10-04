CREATE TABLE demo.ProduktVektor(
 ProduktID int PRIMARY KEY REFERENCES demo.Produkt(ProduktID),
 Embedding vector(3) NOT NULL);


INSERT demo.ProduktVektor
SELECT ProduktID,CASE Produktname
 WHEN N'TrailBook 14' THEN '[0.95,0.85,0.30]'
 WHEN N'OfficeBook 15' THEN '[0.45,0.50,0.95]'
 WHEN N'Dock Pro' THEN '[0.10,0.25,0.80]'
 WHEN N'AnalystBook' THEN '[0.80,0.75,0.55]' END
FROM demo.Produkt;

DECLARE @Suche vector(3)='[0.90,0.80,0.25]';
SELECT p.Produktname,
 VECTOR_DISTANCE('cosine',v.Embedding,@Suche) Distanz
FROM demo.ProduktVektor v JOIN demo.Produkt p
 ON p.ProduktID=v.ProduktID ORDER BY Distanz;

 -- Syntax/Optionen vor dem Termin gegen aktuellen Build prüfen.
CREATE VECTOR INDEX IX_ProduktVektor_Embedding
ON demo.ProduktVektor(Embedding)
WITH(METRIC='cosine',TYPE='diskann');
GO
-- VECTOR_SEARCH ist Preview. Für kleine Tabellen kein Tempoeffekt.
-- Aktuelle Syntax aus Microsoft Learn im Termin verwenden.



/*
Mini-Demo: Vektordatentyp und Vektorsuche ohne externes KI-Modell
Diese kurze Demo zeigt die Grundlagen der neuen Vektor-Unterstützung von SQL Server 2025,
ohne dass ein Embedding-Modell (Ollama) installiert sein muss.
  - vector(3): neuer Datentyp für Vektoren fester Dimension. Hier nur 3 Dimensionen, damit die Werte
    lesbar bleiben (echte Embeddings haben meist 384 bis 1536 Dimensionen).
  - Die Vektoren werden von Hand als Zeichenfolge '[0.95,0.85,0.30]' eingefügt und implizit konvertiert.
  - VECTOR_DISTANCE('cosine', a, b): berechnet den Kosinus-Abstand. Der Wert 0 bedeutet gleiche Richtung
    (sehr ähnlich), Werte nahe 1 bedeuten wenig Ähnlichkeit. Weitere Metriken: 'euclidean', 'dot'.
  - ORDER BY Distanz liefert die ähnlichsten Produkte zuerst (exakte Suche, k-nächste-Nachbarn).
  - CREATE VECTOR INDEX mit TYPE = 'diskann' erzeugt einen Näherungsindex (ANN) für VECTOR_SEARCH.
    Das Feature ist noch Preview und bringt bei sehr kleinen Tabellen keinen Geschwindigkeitsvorteil.
Voraussetzung: Tabellen demo.Produkt und demo.Produktjson aus Skript 05 (bzw. 01 und 05).
Die vollständige Variante mit echten Embeddings steht in 06_Aktiviern_AI_SQLDB.sql.
*/

-- Tabelle mit einem 3-dimensionalen Vektor je Produkt (Fremdschlüssel auf demo.Produkt)
CREATE TABLE demo.ProduktVektor(
 ProduktID int PRIMARY KEY REFERENCES demo.Produkt(ProduktID),
 Embedding vector(3) NOT NULL);


-- Handgemachte Beispielvektoren: ähnliche Produkte erhalten ähnliche Zahlen
INSERT demo.ProduktVektor
SELECT ProduktID,CASE Produktname
 WHEN N'TrailBook 14' THEN '[0.95,0.85,0.30]'
 WHEN N'OfficeBook 15' THEN '[0.45,0.50,0.95]'
 WHEN N'Dock Pro' THEN '[0.10,0.25,0.80]'
 WHEN N'AnalystBook' THEN '[0.80,0.75,0.55]' END
FROM demo.Produkt;

-- Suchvektor: Die Produkte werden nach Ähnlichkeit zu diesem Vektor sortiert (kleinste Distanz = bester Treffer)
DECLARE @Suche vector(3)='[0.90,0.80,0.25]';
SELECT p.Produktname,
 VECTOR_DISTANCE('cosine',v.Embedding,@Suche) Distanz
FROM demo.ProduktVektor v JOIN demo.Produkt p
 ON p.ProduktID=v.ProduktID ORDER BY Distanz;

 -- Vektorindex: Syntax und Optionen vor dem Termin gegen den aktuellen Build prüfen.
CREATE VECTOR INDEX IX_ProduktVektor_Embedding
ON demo.ProduktVektor(Embedding)
WITH(METRIC='cosine',TYPE='diskann');
GO
-- VECTOR_SEARCH ist Preview. Für kleine Tabellen kein Tempoeffekt.
-- Aktuelle Syntax aus Microsoft Learn im Termin verwenden.



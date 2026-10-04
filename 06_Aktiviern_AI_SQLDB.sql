--KOnfiguration für Northwind DB

-- Aktivieren der External Rest Endpoint Funktionalität in SQL Server
EXECUTE sp_configure 'external rest endpoint enabled', 1;
GO

RECONFIGURE WITH OVERRIDE;
GO


select * from sys.external_models
-- drop External model ollamaollamasqldays


--pro DB
CREATE EXTERNAL MODEL ollamasqldays
WITH (
LOCATION = 'https://localhost:11435/api/embed',
API_FORMAT = 'Ollama',
MODEL_TYPE = EMBEDDINGS,
MODEL = 'nomic-embed-text'
        )




--Wir erstellen eine Tabelle speziell für AI
--Die Tabelle enthält die Produktinformationen und die Kategorieinformationen,
--damit die AI mehr Kontext hat.
--Die Spalte "chunk" enthält den Text, der in Embeddings umgewandelt wird.
--ebeddings ist der Vektor, der von der AI generiert wird und für die Suche verwendet wird.




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


--Einfache Suchge nach Vektoren
DECLARE @Suche vector(3)='[0.90,0.80,0.25]';
SELECT p.Produktname,
 VECTOR_DISTANCE('cosine',v.Embedding,@Suche) Distanz
FROM demo.ProduktVektor v JOIN demo.Produkt p
 ON p.ProduktID=v.ProduktID ORDER BY Distanz;


---NUN mit Northwind DB




select p.productid, p.productname, p.UnitPrice, p.UnitsInStock
	, c.CategoryName, c.Description, 
	convert(nvarchar(2000),CONCAT(	'ProductID: ',p.Productid, 
			' | Product Name: ',p.productname,
			' | Category Name: ', c.CategoryName, ' ',
			' | Category Descitption: ', c.Description)) chunk 
into Produktdetails
from products p inner join Categories c on p.CategoryID = c.CategoryID 


alter table Produktdetails add embeddings vector(768);



--Aktivieren des External Models




USE Northwind;

CREATE EXTERNAL MODEL ollamasqldays
WITH (
LOCATION = 'https://localhost:11435/api/embed',
API_FORMAT = 'Ollama',
MODEL_TYPE = EMBEDDINGS,
MODEL = 'nomic-embed-text'
        )




UPDATE Produktdetails
SET [embeddings] = AI_GENERATE_EMBEDDINGS(chunk USE MODEL ollamasqldays), [chunk] = chunk ;

ALTER TABLE Produktdetails add Constraint PK_PrID Primary Key Clustered(Productid)


CREATE VECTOR INDEX product_vector_index1 
ON Produktdetails (Embeddings)
WITH (METRIC = 'cosine', TYPE = 'diskann', MAXDOP = 8);
GO




declare @search_text nvarchar(max) = 'I am looking for a seafood'
declare @search_vector vector(768) = AI_GENERATE_EMBEDDINGS(@search_text USE MODEL ollamasqldays);
SELECT TOP(4)
p.ProductID, p.Productname , p.chunk,
vector_distance('cosine', @search_vector, p.embeddings) AS distance
FROM Produktdetails p
ORDER BY distance;



declare @search_text nvarchar(max) = 'I am looking for a seafood and productid must be beteen 40 and 49'
declare @search_vector vector(768) = AI_GENERATE_EMBEDDINGS(@search_text USE MODEL ollamaollamasqldays);
SELECT TOP(4)
p.ProductID, p.Productname , p.chunk,
vector_distance('cosine', @search_vector, p.embeddings) AS distance
FROM Produktdetails p
ORDER BY distance;



-- GENERATE CHUNKS
-- Chunks sind kleine Textstücke, die aus einem größeren Text extrahiert werden. 
-- Sie helfen dabei, den Text in handlichere Teile zu zerlegen, die leichter verarbeitet 
-- und analysiert werden können. In diesem Fall verwenden wir die Funktion AI_GENERATE_CHUNKS, 
-- um den "chunk" Text in kleinere Fragmente von jeweils 50 Zeichen aufzuteilen. 
-- Diese Fragmente werden dann in der neuen Tabelle "ProduktChunks" gespeichert, 
-- zusammen mit den entsprechenden Produkt-IDs und später auch mit den generierten Embeddings.

-- Erstellen der Tabelle für die aufgeteilten Fragmente
CREATE TABLE ProduktChunks (
    ChunkID INT IDENTITY PRIMARY KEY Clustered,
    ProductID INT,
    ChunkContent NVARCHAR(MAX),
    embeddings VECTOR(768) -- Hier speichern wir später die Vektoren
);

-- 2. Preview-Features aktivieren
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;
GO


--die Paramater der Funktion AI_GENERATE_CHUNKS:

-- source: Der Text, der in Chunks aufgeteilt werden soll (in diesem Fall die "chunk" Spalte).
-- chunk_type: Die Methode, die zum Aufteilen des Textes verwendet wird. FIXED bedeutet, 
--   dass der Text in feste Größen aufgeteilt wird.
-- chunk_size: Die Größe jedes Chunks in Zeichen (hier 50).
-- enable_chunk_set_id: Ein Flag, das angibt, ob eine Chunk-Set-ID generiert werden soll 
-- (hier auf 1 gesetzt, um dies zu aktivieren).

INSERT INTO ProduktChunks (ProductID, ChunkContent)
SELECT 
    p.productid, 
    c.chunk
FROM Produktdetails p
CROSS APPLY AI_GENERATE_CHUNKS(source=chunk, chunk_type=FIXED, chunk_size=50, enable_chunk_set_id=1) AS c;

alter table Produktchunks add embeddings vector(768);

select * from Produktchunks

-- AI_GENERATE_EMBEDDINGS(chunk, USE MODEL ?
--Die Parameter dafür sind:
-- chunk = inputtext
-- model

UPDATE Produktchunks
SET [embeddings] = AI_GENERATE_EMBEDDINGS(chunkContent USE MODEL ollama), [ChunkContent] = ChunkContent ;

--Anlegen eines Vektorindex auf der Embeddings-Spalte der ProduktChunks-Tabelle, um die Suche zu beschleunigen.
-- der VECTOR INDEX ermöglicht es, die Ähnlichkeit zwischen dem Suchvektor und den 
-- gespeicherten Embeddings effizient zu berechnen, was die Leistung bei der Suche erheblich verbessert.
-- Die Parameter des CREATE VECTOR INDEX Befehls:
--    ON Produktchunks (Embeddings): Gibt an, dass der Vektorindex
--    auf der "Embeddings"-Spalte der "Produktchunks"-Tabelle erstellt werden soll.

CREATE VECTOR INDEX product_vector_index2
ON Produktchunks (Embeddings)
WITH (METRIC = 'cosine', TYPE = 'diskann', MAXDOP = 8);
GO


declare @search_text nvarchar(max) = 'I am looking for a seafood and productid must be beteen 40 and 49'
declare @search_vector vector(768) = AI_GENERATE_EMBEDDINGS(@search_text USE MODEL ollama);
SELECT TOP(4)
p.ProductID, pd.ProductName, pd.Description,
vector_distance('cosine', @search_vector, p.embeddings) AS distance
FROM ProduktChunks p inner join produktdetails pd on p.ProductID = pd.ProductID
ORDER BY distance;


-- Verwendung der Vector Search Funktion, um die relevantesten Chunks basierend auf der Ähnlichkeit zum Suchvektor zu finden.
-- der unterschied zur vorherigen Suche besteht darin, dass hier die Funktion vector_search verwendet wird,
-- die speziell für die Suche in Vektordaten entwickelt wurde.
-- Die Parameter der vector_search Funktion:
-- table: Gibt die Tabelle an, in der die Suche durchgeführt werden soll (hier "ProduktChunks" mit Alias "t").
-- column: Gibt die Spalte an, die die Embeddings enthält (hier "embeddings").
-- similar_to: Gibt den Suchvektor an, mit dem die Ähnlichkeit verglichen werden soll (hier "@search_vector").
-- metric: Gibt die Metrik an, die zur Berechnung der Ähnlichkeit verwendet werden soll (hier "cosine").
-- top_n: Gibt die Anzahl der Top-Ergebnisse an, die zurückgegeben werden sollen (hier 10).

DECLARE @search_text NVARCHAR (MAX) = 'I am looking for a seafood';
DECLARE @search_vector VECTOR (768) = AI_GENERATE_EMBEDDINGS(@search_text USE MODEL ollama);
SELECT t.chunkcontent,t.ProductID,p.ProductName,c.CategoryName,
s.distance
FROM vector_search(
table = ProduktChunks as t,
column = [embeddings],
similar_to = @search_vector,
metric = 'cosine',
top_n = 10
) as s inner join Products p on p.ProductID = t.ProductID inner join Categories c on c.CategoryID = p.CategoryID
ORDER BY s.distance;
GO
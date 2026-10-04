USE SQL2025Workshop;

ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES=ON;
GO


--Fuzzy String Matching : in SQL Server 2025 kann mit den neuen Funktionen 
-- EDIT_DISTANCE, 
-- EDIT_DISTANCE_SIMILARITY und 
-- JARO_WINKLER_SIMILARITY die Ähnlichkeit von Strings berechnet werden.

--Der Unterschied ist, dass die Edit Distance die Anzahl der Bearbeitungsschritte (Einfügen, Löschen, Ersetzen) angibt,
-- während die Edit Distance Similarity und Jaro-Winkler Similarity einen Score zwischen 0 und 100 zurückgeben, wobei 100 für eine perfekte Übereinstimmung steht.
--EDIT_DISTANCE_SIMALIRITY gibt einen Score basierend auf der Edit Distance zurück, wobei ein höherer Score eine größere Ähnlichkeit anzeigt.

--JARO Winkler Similarity ist besonders nützlich für kurze Strings und berücksichtigt die Position der Zeichen, was sie für Namen und kurze Wörter geeignet macht.

-- In diesem Beispiel werden die Firmenname aus der Tabelle demo.KontaktImport miteinander verglichen und die Ergebnisse nach dem Jaro-Winkler Similarity Score absteigend sortiert.


SELECT 
    EDIT_DISTANCE('MEYER', 'MEYRE') AS EditDistanz,
    EDIT_DISTANCE_SIMILARITY('MEYER', 'MEYRE') AS EditScore,
    JARO_WINKLER_SIMILARITY('MEYER', 'MEYRE') AS JWScore

WITH TestPaare AS (
    SELECT 'Siemens AG' AS NameA, 'Siemenz AG' AS NameB, 'Fehler am Wortende' AS Szenario
    UNION ALL
    SELECT 'Siemens AG', 'Ziemens AG', 'Fehler am Wortanfang'
    UNION ALL
    SELECT 'Microsoft', 'Microsfot', 'Buchstabendreher (Transposition)'
    UNION ALL
    SELECT 'Contoso GmbH', 'Contoso Retail GmbH', 'Zusätzliches Wort / Einschub'
    UNION ALL
    SELECT 'BMW', 'AUDI', 'Keine Ähnlichkeit'
)
SELECT 
    Szenario,
    NameA,
    NameB,
    EDIT_DISTANCE(NameA, NameB) AS EditDistanz,
    EDIT_DISTANCE_SIMILARITY(NameA, NameB) AS EditScore,
    JARO_WINKLER_SIMILARITY(NameA, NameB) AS JWScore
FROM TestPaare
ORDER BY JWScore DESC;





SELECT a.Firmenname NameA,b.Firmenname NameB,
 EDIT_DISTANCE(a.Firmenname,b.Firmenname) EditDistanz,
 EDIT_DISTANCE_SIMILARITY(a.Firmenname,b.Firmenname) EditScore,
 JARO_WINKLER_SIMILARITY(a.Firmenname,b.Firmenname) JWScore
FROM demo.KontaktImport a JOIN demo.KontaktImport b
 ON a.KontaktID<b.KontaktID ORDER BY JWScore DESC;




 --Praxisbezogen: Dublettensuche
 SELECT a.KontaktID, a.Firmenname, b.KontaktID, b.Firmenname,
       JARO_WINKLER_SIMILARITY(a.Firmenname, b.Firmenname) AS JWScore
FROM demo.KontaktImport a
JOIN demo.KontaktImport b
  ON a.KontaktID < b.KontaktID
WHERE JARO_WINKLER_SIMILARITY(a.Firmenname, b.Firmenname) >= 0.88
   OR EDIT_DISTANCE_SIMILARITY(a.Firmenname, b.Firmenname) >= 85;


 WITH Paare AS(
 SELECT a.KontaktID ID_A,b.KontaktID ID_B,a.Firmenname Name_A,
 b.Firmenname Name_B,
 JARO_WINKLER_SIMILARITY(a.Firmenname,b.Firmenname) Score
 FROM demo.KontaktImport a JOIN demo.KontaktImport b
 ON a.KontaktID<b.KontaktID)
SELECT * FROM Paare WHERE Score>=85 ORDER BY Score DESC;

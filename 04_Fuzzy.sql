/*
Neu in SQL Server 2025: Fuzzy String Matching (unscharfer Textvergleich)
Mit einem normalen Vergleich (=, LIKE) werden Tippfehler, Buchstabendreher oder abweichende
Schreibweisen nicht erkannt. SQL Server 2025 enthält dafür Funktionen zur Ähnlichkeitsberechnung
(derzeit als Preview-Feature, daher PREVIEW_FEATURES = ON):
  EDIT_DISTANCE                - Levenshtein-Distanz: Anzahl der Einfüge-, Lösch- und
                                 Ersetzungsschritte, um den einen Text in den anderen zu verwandeln (0 = identisch)
  EDIT_DISTANCE_SIMILARITY     - dieselbe Berechnung als Ähnlichkeitswert von 0 bis 100 (100 = identisch)
  JARO_WINKLER_SIMILARITY      - Ähnlichkeitswert, der Übereinstimmungen am Wortanfang stärker
                                 gewichtet; gut für Namen und kurze Texte
Die Funktionen sind direkt in der Engine implementiert und können in SELECT, WHERE und JOIN verwendet werden.
Typische Einsatzfälle: Dublettenerkennung in Kunden- und Adressdaten, Datenbereinigung beim Import,
Vorschläge bei Tippfehlern ("Meinten Sie ..."), Zuordnung ähnlicher Firmennamen.
Wichtig: Ein Vergleich jeder Zeile mit jeder anderen (Self Join) ist rechenintensiv (n*n Paare)
und eignet sich nur für kleine Datenmengen oder nach vorheriger Eingrenzung.
Das Skript vergleicht erst einzelne Beispiele und danach die Firmennamen aus demo.KontaktImport.
*/

USE SQL2025Workshop;

-- Die Fuzzy-Funktionen sind noch Preview-Features und müssen zuerst aktiviert werden
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES=ON;
GO


--Fuzzy String Matching : in SQL Server 2025 kann mit den neuen Funktionen 
-- EDIT_DISTANCE, 
-- EDIT_DISTANCE_SIMILARITY und 
-- JARO_WINKLER_SIMILARITY die Ähnlichkeit von Strings berechnet werden.

--Der Unterschied ist, dass die Edit Distance die Anzahl der Bearbeitungsschritte (Einfügen, Löschen, Ersetzen) angibt,
-- während die Edit Distance Similarity und Jaro-Winkler Similarity einen Score zwischen 0 und 100 zurückgeben, wobei 100 für eine perfekte Übereinstimmung steht.
--EDIT_DISTANCE_SIMILARITY gibt einen Score basierend auf der Edit Distance zurück, wobei ein höherer Score eine größere Ähnlichkeit anzeigt.

--JARO Winkler Similarity ist besonders nützlich für kurze Strings und berücksichtigt die Position der Zeichen, was sie für Namen und kurze Wörter geeignet macht.

-- In diesem Beispiel werden die Firmennamen aus der Tabelle demo.KontaktImport miteinander verglichen und die Ergebnisse nach dem Jaro-Winkler Similarity Score absteigend sortiert.


-- Einfacher Vergleich zweier Namen mit Buchstabendreher (Meyer/Meyre)
SELECT 
    EDIT_DISTANCE('MEYER', 'MEYRE') AS EditDistanz,
    EDIT_DISTANCE_SIMILARITY('MEYER', 'MEYRE') AS EditScore,
    JARO_WINKLER_SIMILARITY('MEYER', 'MEYRE') AS JWScore;

-- Typische Fehlerszenarien als Testpaare: Die Funktionen liefern je nach Fehlerart unterschiedliche Scores
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





-- Alle Firmennamen paarweise vergleichen (a.KontaktID<b.KontaktID vermeidet doppelte Paare und Selbstvergleiche)
SELECT a.Firmenname NameA,b.Firmenname NameB,
 EDIT_DISTANCE(a.Firmenname,b.Firmenname) EditDistanz,
 EDIT_DISTANCE_SIMILARITY(a.Firmenname,b.Firmenname) EditScore,
 JARO_WINKLER_SIMILARITY(a.Firmenname,b.Firmenname) JWScore
FROM demo.KontaktImport a JOIN demo.KontaktImport b
 ON a.KontaktID<b.KontaktID ORDER BY JWScore DESC;




 --Praxisbezogen: Dublettensuche
 -- Als Dublette gilt ein Paar mit hohem Ähnlichkeitswert (Schwellenwerte je nach Datenqualität anpassen)
 SELECT a.KontaktID, a.Firmenname, b.KontaktID, b.Firmenname,
       JARO_WINKLER_SIMILARITY(a.Firmenname, b.Firmenname) AS JWScore
FROM demo.KontaktImport a
JOIN demo.KontaktImport b
  ON a.KontaktID < b.KontaktID
WHERE JARO_WINKLER_SIMILARITY(a.Firmenname, b.Firmenname) >= 0.88
   OR EDIT_DISTANCE_SIMILARITY(a.Firmenname, b.Firmenname) >= 85;


 -- Dieselbe Auswertung mit CTE: erst alle Paare berechnen, dann nach Score filtern und sortieren
 WITH Paare AS(
 SELECT a.KontaktID ID_A,b.KontaktID ID_B,a.Firmenname Name_A,
 b.Firmenname Name_B,
 JARO_WINKLER_SIMILARITY(a.Firmenname,b.Firmenname) Score
 FROM demo.KontaktImport a JOIN demo.KontaktImport b
 ON a.KontaktID<b.KontaktID)
SELECT * FROM Paare WHERE Score>=85 ORDER BY Score DESC;

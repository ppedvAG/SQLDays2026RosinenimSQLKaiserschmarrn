--Bis SQL Server 2022 konnte json nur als nvarchar gespeichert werden.
--Ab SQL Server 2025 gibt es einen nativen Datentyp json, der die Speicherung und Verarbeitung von json-Daten erleichtert.
--ZUsätzlich kann nun json indiziert werden, was die Abfragegeschwindigkeit deutlich erhöht.

--Bisher wurde json als "text" gespeichert , was die Abfragegeschwindigkeit stark verlangsamt und musste 
-- mit JSON_VALUE und OPENJSON aufwendig verarbeitet werden.


USE SQL2025Workshop;
GO



-- 1. Tabelle erstellen (nvarchar(max) statt nativer json-Typ)
CREATE TABLE demo.Produktjson (
    ProduktID    int IDENTITY PRIMARY KEY,
    Produktname  nvarchar(100) NOT NULL,
    Kategorie    nvarchar(40)  NOT NULL,
    Merkmale     nvarchar(max) NOT NULL, --hier kommt der json Code
    CONSTRAINT CK_Produkt_Merkmale_ISJSON CHECK (ISJSON(Merkmale) = 1) --ist json korrekt formatiert?
);

-- 2. Daten einfügen --der 
INSERT INTO demo.Produkt (Produktname, Kategorie, Merkmale)
VALUES
    (N'TrailBook 14',  N'Notebook', N'{"gewichtKg":1.18,"ramGB":32,"einsatz":["mobil","entwicklung"]}'),
    (N'OfficeBook 15', N'Notebook', N'{"gewichtKg":1.75,"ramGB":16,"einsatz":["office"]}'),
    (N'Dock Pro',      N'Zubehör',  N'{"ports":{"usbC":3,"hdmi":2},"leistungW":100}');

-- 3. JSON_VALUE (funktioniert identisch)
SELECT 
    Produktname,
    JSON_VALUE(Merkmale, '$.gewichtKg') AS Gewicht, --json auslesen
    JSON_VALUE(Merkmale, '$.ramGB')     AS RAM
FROM demo.Produkt
WHERE Kategorie = N'Notebook';

-- 4. JSON_MODIFY (funktioniert identisch)
UPDATE demo.Produkt
SET Merkmale = JSON_MODIFY(Merkmale, '$.ramGB', 64)
WHERE Produktname = N'TrailBook 14';

-- 5. OPENJSON mit CROSS APPLY (funktioniert identisch)
SELECT 
    p.Produktname,
    e.value AS Einsatz
FROM demo.Produkt p
CROSS APPLY OPENJSON(p.Merkmale, '$.einsatz') e;

-- 6. Ersatz für JSON_ARRAYAGG() via FOR JSON PATH
SELECT 
    p.Kategorie,
    (
        SELECT sub.Produktname AS [text()]
        FROM demo.Produkt sub
        WHERE sub.Kategorie = p.Kategorie
        ORDER BY sub.Produktname
        FOR JSON PATH
    ) AS Produkte
FROM demo.Produkt p
GROUP BY p.Kategorie;


select * from demo.produkt



--Nun als JSON Datentyp

--Der isjon Check entfällt, da der Datentyp json nur korrekt formatiertes json zulässt.

CREATE TABLE demo.Produktjson(
 ProduktID int IDENTITY PRIMARY KEY,Produktname nvarchar(100) NOT NULL,
 Kategorie nvarchar(40) NOT NULL,Merkmale json NOT NULL); --json als nativer Datentyp in SQL Server 2025

INSERT demo.Produktjson(Produktname,Kategorie,Merkmale) VALUES
(N'TrailBook 14',N'Notebook','{"gewichtKg":1.18,"ramGB":32,"einsatz":["mobil","entwicklung"]}'),
(N'OfficeBook 15',N'Notebook','{"gewichtKg":1.75,"ramGB":16,"einsatz":["office"]}'),
(N'Dock Pro',N'Zubehör','{"ports":{"usbC":3,"hdmi":2},"leistungW":100}');


--Abfragen gehen identisch wie bisher, nur dass der Datentyp json nun die Verarbeitung beschleunigt.
SELECT Produktname,JSON_VALUE(Merkmale,'$.gewichtKg') Gewicht,
 JSON_VALUE(Merkmale,'$.ramGB') RAM
FROM demo.Produktjson WHERE Kategorie=N'Notebook';

--auch das Update geht identisch, nur dass der Datentyp json nun die Verarbeitung beschleunigt.
UPDATE demo.Produktjson SET Merkmale=JSON_MODIFY(Merkmale,'$.ramGB',64)
WHERE Produktname=N'TrailBook 14';

--OPENJSON mit CROSS APPLY funktioniert identisch, nur dass der Datentyp json nun die Verarbeitung beschleunigt.
--OPENJSON und CROISS APLLY verwendet man, wenn man ein Array aus dem json auslesen möchte.
SELECT p.Produktname,e.value Einsatz FROM demo.Produktjson p
CROSS APPLY OPENJSON(p.Merkmale,'$.einsatz')e;

--neu ist die Funktion JSON_ARRAYAGG(), die ein Array aus json erstellt. Bisher musste man dafür FOR JSON PATH verwenden.
SELECT Kategorie,JSON_ARRAYAGG(Produktname ORDER BY Produktname) Produkte
FROM demo.Produktjson GROUP BY Kategorie;

--json Spalten lassen sich nun auch indizieren
-- ein CLUSTERD INDEX PRIMARY KEY muss vorhanden sein ;

--ein IX für spezielle PFade, die häufig abgefragt werden, ist sinnvoll, da die Indexerstellung schneller geht und weniger Speicherplatz benötigt.

CREATE JSON INDEX IX_JSON_Produkt_Merkmale 
ON demo.Produktjson (Merkmale) 
FOR (
    '$.gewichtKg',
    '$.ramGB',
    '$.ports.usbC'
);

--oder alle Pfade indizieren, was aber mehr Speicherplatz benötigt und die Indexerstellung länger dauert

CREATE JSON INDEX IX_JSON_Produkt_Merkmale_All 
ON demo.Produktjson (Merkmale);



-- Nutzt automatisch den JSON-Index via Index Seek
SELECT Produktname, Merkmale
FROM demo.Produktjson
WHERE CAST(JSON_VALUE(Merkmale, '$.ramGB') AS INT) >= 32;


-- 1. Testweise mit RETURNING INT
SELECT Produktname, Merkmale
FROM demo.Produktjson WITH (INDEX(ix_json_produkt_merkmale)) -- Name deines JSON-Index
WHERE JSON_VALUE(Merkmale, '$.ramGB' RETURNING INT) >= 32;

-- Ebenfalls voll vom JSON-Index unterstützt
SELECT Produktname
FROM demo.Produktjson
WHERE JSON_CONTAINS(Merkmale, 'mobil', '$.einsatz') = 1;
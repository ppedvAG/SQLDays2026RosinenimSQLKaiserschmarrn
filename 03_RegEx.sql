--Neu ist die Funktion für RegEx. Damit kann man z.B. E-Mail-Adressen prüfen, ob eine E-Mail-Adresse formal plausibel ist.

--Ohnen RegEx, war die Prüfung bedeutend schwieriger.
-- Man musste viele Funktionen kombinieren, um z.B. die Position des @-Zeichens zu prüfen
--, ob es nur einmal vorkommt, ob es ein Punkt nach dem @ gibt usw.

-- Beispiel für Email Prüfung ohne RegEx

--diese Beispiel prüft, ob das @-Zeichen nur einmal vorkommt und ob nach dem @-Zeichen ein Punkt vorkommt.
-- es müsste noch weiter geprüft werden, ob die E-Mail-Adresse nicht mit einem Punkt endet, ob sie nicht mit einem @ beginnt usw.



SELECT 
    KontaktID,
    Firmenname,
    EMail,
    CASE 
        WHEN CHARINDEX('@', EMail) > 1                                     -- @ vorhanden und nicht an 1. Stelle
             AND LEN(EMail) - LEN(REPLACE(EMail, '@', '')) = 1            -- exakt ein @
             AND CHARINDEX('.', EMail, CHARINDEX('@', EMail) + 2) > 0     -- Punkt nach dem @ (und nicht direkt danach)
             AND RIGHT(EMail, 1) <> '.'                                   -- endet nicht auf Punkt
        THEN 'formal plausibel' 
        ELSE 'auffällig' 
    END AS Bewertung
 FROM demo.KontaktImport;

--RegEx hatr folgende Funkionen: 
-- REGEXP_LIKE() prüft, ob ein String einem Muster entspricht
-- REGEXP_REPLACE() ersetzt Teile eines Strings, die einem Muster entsprechen
-- REGEXP_SUBSTR() gibt den Teil eines Strings zurück, der einem Muster entspricht
-- REGEXP_INSTR() gibt die Position des ersten Vorkommens eines Musters in einem String zurück
-- REGEXP_COUNT() gibt die Anzahl der Vorkommen eines Musters in einem String zurück

SELECT KontaktID,Firmenname,EMail,
	 CASE WHEN 
			REGEXP_LIKE( EMail, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' ) 
		 THEN 'formal plausibel' 
		 ELSE 'auffällig' END Bewertung
FROM demo.KontaktImport;

--weitere besipiele für den Einsatz von RegEx:

select KontaktID,Firmenname,EMail,
		REGEXP_REPLACE(EMail, '^[A-Za-z0-9._%+-]+@', '') as Domain,
		REGEXP_SUBSTR(EMail, '@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') as TLD,
		REGEXP_INSTR(EMail, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') as Position,
		REGEXP_COUNT(EMail, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') as Anzahl
from demo.KontaktImport;


/*
^[A-Za-z0-9._%+-]+@' 
	bdeutet, dass die E-Mail-Adresse mit einem 
	oder mehreren Zeichen aus dem Bereich A-Z, a-z, 0-9, Punkt, Unterstrich, Prozentzeichen, Pluszeichen oder Bindestrich beginnen muss,
	gefolgt von einem @-Zeichen.

'@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
	bedeutet, dass die E-Mail-Adresse nach dem @-Zeichen mit einem oder mehreren Zeichen aus dem Bereich A-Z, a-z, 0-9, Punkt oder Bindestrich 
	gefolgt von einem Punkt und mindestens zwei Buchstaben enden muss.
	Das \ vor dem Punkt ist notwendig, da der Punkt in RegEx ein Sonderzeichen ist und daher maskiert werden muss.
	Das + hinter dem Bereich [A-Za-z0-9.-] bedeutet, dass mindestens ein Zeichen aus diesem Bereich vorkommen muss.
	{2,} bedeutet, dass mindestens zwei Buchstaben vorkommen müssen. Das Komma nach der 2 bedeutet, dass es keine Obergrenze gibt.
	Das $ am Ende bedeutet, dass die E-Mail-Adresse mit diesem Muster enden muss.
*/

--
-- RegExp_SUBSTR

select * from demo.KontaktImport



SELECT KontaktID,
 REGEXP_SUBSTR(Freitext,'[A-Z]-[0-9]{3}') Kundencode, --extrahieren des Kundencode aus Freitext. Der Kundencode besteht aus einem Großbuchstaben, gefolgt von einem Bindestrich und drei Ziffern.
 REGEXP_REPLACE(Telefon,'[^0-9+]','') TelefonNormalisiert, --normalisieren der Telefonnummer. Es werden alle Zeichen entfernt, die keine Ziffern oder das Pluszeichen sind.
 REGEXP_COUNT(Freitext,':') AnzahlDoppelpunkte --zählt die Anzahl der Doppelpunkte im Freitext. Das ist z.B. nützlich, um zu prüfen, ob ein Textfeld mehrere Werte enthält, die durch Doppelpunkte getrennt sind.
FROM demo.KontaktImport;

--TODO
--Splitte die Spalte  Freitext in mehrere Zeilen, die durch Semikolons getrennt sind.

--';\s*' bedeutet, dass der String durch ein Semikolon und optional durch beliebig viele Leerzeichen getrennt ist.
--Das \s steht für ein Leerzeichen und das * bedeutet, dass beliebig viele Leerzeichen vorkommen können, auch keine. 
--Das ist nützlich, um z.B. eine Liste von Werten zu trennen, die durch Semikolons getrennt sind, aber auch Leerzeichen enthalten können.
select * from demo.KontaktImport
SELECT k.KontaktID,s.value Token
FROM demo.KontaktImport k
CROSS APPLY REGEXP_SPLIT_TO_TABLE(k.Freitext,';\s*') s;

Kunde: A-100; Region: Nord


--Im folgenden Beispiel wird geprüft, ob die Telefonnummer vorhanden ist und ob die Region im Freitext angegeben ist.
--und mit RegExp_Replace
select * from demo.KontaktImport	

-- REGEXP_SUBSTR(Freitext,'Region: [A-Za-zÄÖÜäöüß]+' sucht nach dem Muster "Region: " 
--

SELECT KontaktID,
 CASE WHEN 
	REGEXP_LIKE(COALESCE(Telefon,''),'[0-9]') THEN 'vorhanden' ELSE 'fehlt' END Telefonstatus,
	REGEXP_REPLACE(REGEXP_SUBSTR(Freitext,'Region: [A-Za-zÄÖÜäöüß]+'),'^Region: ','') Region
FROM demo.KontaktImport;


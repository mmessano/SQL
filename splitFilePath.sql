--Table Structure
DECLARE @bla TABLE (tmp VARCHAR(500))
  
INSERT @bla VALUES( 'C:\data\old\one.jpg')
INSERT @bla VALUES( 'C:\data\old\one.two.jpg')
INSERT @bla VALUES( 'C:\data\new\newer\three.wav')
INSERT @bla VALUES( 'C:\Documents and Settings\My Music\Amazon MP3\The Doors\Gloria.mp3')
 
--The Code
SELECT
PARSENAME(RIGHT(tmp,(PATINDEX('%\%',REVERSE(tmp)))-1),1) AS Extension,
CASE WHEN PARSENAME(RIGHT(tmp,(PATINDEX('%\%',REVERSE(tmp)))-1),3) IS null
THEN PARSENAME(RIGHT(tmp,(PATINDEX('%\%',REVERSE(tmp)))-1),2)
ELSE PARSENAME(RIGHT(tmp,(PATINDEX('%\%',REVERSE(tmp)))-1),3) END AS NameOfFile,
LEFT(tmp,LEN(tmp) -LEN(RIGHT(tmp,(PATINDEX('%\%',REVERSE(tmp)))-1))) AS TotalPath,
LEN(tmp) -LEN(REPLACE(tmp,'\\','')) -1 AS NumberOfFolders  --the tmp,'\' should be only 1 \ but it won't show
FROM @bla


------------------------------------------------------------------------------------------------------------------
DECLARE @fpath VARCHAR(512)

SET @fpath = 'C:\Dexma\junk\morejunk\bin\badhash.pl'

SELECT 
REVERSE(SUBSTRING(REVERSE(@fpath),CHARINDEX('\', REVERSE(@fpath), 1) + 1,LEN(@fpath) - CHARINDEX('\', REVERSE(@fpath),1))) AS Path,
REVERSE(SUBSTRING(REVERSE(@fpath), 0, CHARINDEX('\', REVERSE(@fpath), 1))) AS FileName


SELECT
REVERSE(SUBSTRING(REVERSE(@fpath),CHARINDEX('\', REVERSE(@fpath), 1) + 1,LEN(@fpath) - CHARINDEX('\', REVERSE(@fpath),1))) AS Path
 
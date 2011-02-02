DECLARE @SSISDir varchar(64)

SELECT @SSISDir = 'e:\dexma\ssis\'

CREATE TABLE #CSSISDir (SSISPackage varchar(64))

EXEC dbamaint.dbo.dbm_ListFiles @SSISDir,'#CSSISDir',NULL,NULL,1

SELECT @@SERVERNAME AS ServerName, SSISPackage, CONVERT(CHAR(10), GetDate(), 111) AS LastUpdate FROM #CSSISDir

DROP TABLE #CSSISDir

/*

USE [dbamaint]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[dbm_ListFiles]
    @PCWrite varchar(2000),
    @DBTable varchar(100)= NULL,
    @PCIntra varchar(100)= NULL,
    @PCExtra varchar(100)= NULL,
    @DBUltra bit = 0

AS

/*
The dbm_ListFiles stored procedure accepts five parameters. Only the first one is required.
Parameter 1 is a path to a directory. The path must be accessible to SQL Server (the service account or the proxy account).
Parameter 2 is a table name in which to insert the file/folder names. It can be a normal user table or a temporary table. If no table name is provided, the list is returned as a result set.
Parameter 3 is a filter for including certain names. Each name is compared to the filter using a LIKE operator, so wildcards are acceptable. For example, the value "%.doc" would include all Word documents.
Parameter 4 is a filter for excluding certain names. Each name is compared to the filter using a NOT LIKE operator, so wildcards are acceptable.
Parameter 5 determines whether files or folders are listed. A value of zero (0) returns files and a value of one (1) returns folders. 

Usage Example:
CREATE TABLE #Files (MyFile varchar(200))

DECLARE @MyFile varchar(200), @SQL varchar(2000), @Path varchar(400)

SET @Path = 'e:\MSSQL.1\MSSQL\DATA\'

EXECUTE dbm_ListFiles @Path,'#Files',NULL,NULL,0

SELECT * FROM #Files

DROP TABLE #Files
*/

SET NOCOUNT ON


DECLARE @Return int
DECLARE @Retain int
DECLARE @Status int


SET @Status = 0

DECLARE @Task varchar(2000)
DECLARE @Work varchar(2000)
DECLARE @Wish varchar(2000)

SET @Work = 'DIR ' + '"' + @PCWrite + '"'


CREATE TABLE #DBAZ (Name varchar(400), Work int IDENTITY(1,1))

INSERT #DBAZ EXECUTE @Return = master.dbo.xp_cmdshell @Work

SET @Retain = @@ERROR


IF @Status = 0 SET @Status = @Retain
IF @Status = 0 SET @Status = @Return

IF (SELECT COUNT(*) FROM #DBAZ) < 4
    BEGIN

    SELECT @Wish = Name FROM #DBAZ WHERE Work = 1
    IF @Wish IS NULL
        BEGIN
        RAISERROR ('General error [%d]',16,1,@Status)
        END
    ELSE
        BEGIN
        RAISERROR (@Wish,16,1)
        END
    END
ELSE
    BEGIN
    DELETE #DBAZ WHERE ISDATE(SUBSTRING(Name,1,10)) = 0 OR SUBSTRING(Name,40,1) = '.' OR Name LIKE '%.lnk'
    IF @DBTable IS NULL
        BEGIN
          SELECT SUBSTRING(Name,40,100) AS Files
            FROM #DBAZ
           WHERE 0 = 0
             AND (@DBUltra  = 0    OR Name     LIKE '%<DIR>%')
             AND (@DBUltra != 0    OR Name NOT LIKE '%<DIR>%')
             AND (@PCIntra IS NULL OR SUBSTRING(Name,40,100) LIKE @PCIntra)
             AND (@PCExtra IS NULL OR SUBSTRING(Name,40,100) NOT LIKE @PCExtra)
        ORDER BY 1
        END
    ELSE
        BEGIN
        SET @Task = ' INSERT ' + REPLACE(@DBTable,CHAR(32),CHAR(95))
                  + ' SELECT SUBSTRING(Name,40,100) AS Files'
                  + '   FROM #DBAZ'
                  + '  WHERE 0 = 0'
                  + CASE WHEN @DBUltra  = 0    THEN '' ELSE ' AND Name LIKE ' + CHAR(39) + '%<DIR>%' + CHAR(39) END
                  + CASE WHEN @DBUltra != 0    THEN '' ELSE ' AND Name NOT LIKE ' + CHAR(39) + '%<DIR>%' + CHAR(39) END
                  + CASE WHEN @PCIntra IS NULL THEN '' ELSE ' AND SUBSTRING(Name,40,100)     LIKE ' + CHAR(39) + @PCIntra + CHAR(39) END
                  + CASE WHEN @PCExtra IS NULL THEN '' ELSE ' AND SUBSTRING(Name,40,100) NOT LIKE ' + CHAR(39) + @PCExtra + CHAR(39) END
                  + ' ORDER BY 1'
        IF @Status = 0 EXECUTE (@Task) SET @Return = @@ERROR
        IF @Status = 0 SET @Status = @Return
        END
    END
DROP TABLE #DBAZ

SET NOCOUNT OFF

RETURN (@Status)


*/
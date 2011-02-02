USE [dbamaint]
GO
/****** Object:  StoredProcedure [dbo].[dbm_CompareDB]    Script Date: 04/09/2009 11:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- sp_CompareDB
--
-- The SP compares structures and data in 2 databases.
-- 1. Compares if all tables in one database have analog (by name) in second database
-- Tables not existing in one of databases won't be used for data comparing
-- 2. Compares if structures for tables with the same names are the same. Shows structural
-- differences like:
-- authors
-- Column Phone: in db1 - char(12), in db2 - char(14)
-- sales
-- Column Location not in db2
-- Tables, having different structures, won't be used for data comparing. However if the tables
-- contain columns of the same type and different length (like Phone in the example above) or
-- tables have compatible data types (have the same type in syscolumns - char and nchar,
-- varchar and nvarchar etc) they will be allowed for data comparing.
-- 3. Data comparison itself.
-- 3.1 Get information about unique keys in the tables. If there are unique keys then one of them
-- (PK is a highest priority candidate for this role) will be used to specify rows with
-- different data.
-- 3.2 Get information about all data columns in the table and form predicates that will be
-- used to compare data.
-- 3.3 Compare data with the criteria:
-- a. if some unique keys from the table from first database do not exist in second db (only
-- for tables with a unique key)
-- b. if some unique keys from the table from second database do not exist in first db (only
-- for tables with a unique key)
-- c. if there are rows with the same values of unique keys and different data in other
-- columns (only for tables with a unique key)
-- d. if there are rows in the table from first database that don't have a twin in the
-- table from second db
-- e. if there are rows in the table from second database that don't have a twin in the
-- table from first db
--------------------------------------------------------------------------------------------
-- Parameters:
-- 1. @db1 - name of first database to compare
-- 2. @db2 - name of second database to compare
-- 3. @TabList - list of tables to compare. if empty - all tables in the databases should be
-- compared
-- 4. @NumbToShow - number of rows with differences to show. Default - 10.
-- 5. @OnlyStructure - flag, if set to 1, allows to avoid data comparing. Only structures should
-- be compared. Default - 0
-- 6. @NoTimestamp - flag, if set to 1, allows to avoid comparing of columns of timestamp
-- data type. Default - 0
-- 7. @VerboseLevel - if set to 1 allows to print querues used for data comparison
--------------------------------------------------------------------------------------------
-- Created by Viktor Gorodnichenko (c)
-- Created on: July 5, 2001
--------------------------------------------------------------------------------------------
CREATE PROC [dbo].[dbm_CompareDB] 
	   @db1 VARCHAR(128), 
	   @db2 VARCHAR(128), 
	   @OnlyStructure bit = 0, 
	   @TabList VARCHAR(8000) = '', 
	   @NumbToShow INT = 10, 
	   @NoTimestamp bit = 0, 
	   @VerboseLevel TINYINT = 0 AS

IF @OnlyStructure <> 0
SET @OnlyStructure = 1
IF @NoTimestamp <> 0
SET @NoTimestamp = 1
IF @VerboseLevel <> 0
SET @VerboseLevel = 1

SET NOCOUNT ON
SET ANSI_WARNINGS ON
SET ANSI_NULLS ON

DECLARE @sqlStr VARCHAR(8000)
SET nocount ON
-- Checking if there are specified databases
DECLARE @SrvName sysname
DECLARE @DBName sysname
SET @db1               = RTRIM(LTRIM(@db1))
SET @db2               = RTRIM(LTRIM(@db2))
SET @SrvName           = @@SERVERNAME
IF CHARINDEX('.',@db1) > 0
BEGIN
        SET @SrvName = LEFT(@db1,CHARINDEX('.',@db1)-1)
        IF NOT EXISTS
        (
               SELECT *
               FROM   master.dbo.sysservers
               WHERE  srvname = @SrvName
        )
        BEGIN
                PRINT 'There is no linked server named '+@SrvName+'. End of work.'
                RETURN
        END
        SET @DBName = RIGHT(@db1,LEN(@db1)-CHARINDEX('.',@db1))
END
ELSE
SET @DBName = @db1
EXEC ('declare @Name sysname select @Name=name from ['+@SrvName+'].master.dbo.sysdatabases where name = '''+@DBName+'''')
IF @@rowcount = 0
BEGIN
        PRINT 'There is no database named '+@db1+'. End of work.'
        RETURN
END
SET @SrvName           = @@SERVERNAME
IF CHARINDEX('.',@db2) > 0
BEGIN
        SET @SrvName = LEFT(@db2,CHARINDEX('.',@db2)-1)
        IF NOT EXISTS
        (
               SELECT *
               FROM   master.dbo.sysservers
               WHERE  srvname = @SrvName
        )
        BEGIN
                PRINT 'There is no linked server named '+@SrvName+'. End of work.'
                RETURN
        END
        SET @DBName = RIGHT(@db2,LEN(@db2)-CHARINDEX('.',@db2))
END
ELSE
SET @DBName = @db2
EXEC ('declare @Name sysname select @Name=name from ['+@SrvName+'].master.dbo.sysdatabases where name = '''+@DBName+'''')
IF @@rowcount = 0
BEGIN
        PRINT 'There is no database named '+@db2+'. End of work.'
        RETURN
END
PRINT REPLICATE('-',LEN(@db1)+LEN(@db2)+25)
PRINT 'Comparing databases ' +@db1+' and '+@db2
PRINT REPLICATE('-',LEN(@db1)+LEN(@db2)+25)
PRINT 'Options specified:'
PRINT ' Compare only structures: '+
CASE
WHEN @OnlyStructure = 0 THEN
        'No'
        ELSE 'Yes'
END
PRINT ' List of tables to compare: '+
CASE
WHEN LEN(@TabList) = 0 THEN
        ' All tables'
        ELSE @TabList
END
PRINT ' Max number of different rows in each table to show: '+LTRIM(STR(@NumbToShow))
PRINT ' Compare timestamp columns: '                         +
CASE
WHEN @NoTimestamp = 0 THEN
        'No'
        ELSE 'Yes'
END
PRINT ' Verbose level: '+
CASE
WHEN @VerboseLevel = 0 THEN
        'Low'
        ELSE 'High'
END
-----------------------------------------------------------------------------------------
-- Comparing structures
-----------------------------------------------------------------------------------------
PRINT CHAR(10)+REPLICATE('-',36)
PRINT 'Comparing structure of the databases'
PRINT REPLICATE('-',36)
IF EXISTS
(
       SELECT *
       FROM   tempdb.dbo.sysobjects
       WHERE  name LIKE '#TabToCheck%'
)
DROP TABLE #TabToCheck
CREATE TABLE #TabToCheck
             (
                          name sysname
             )
DECLARE @NextCommaPos INT
IF LEN(@TabList) > 0
BEGIN
        WHILE 1=1
        BEGIN
                SET @NextCommaPos = CHARINDEX(',',@TabList)
                IF @NextCommaPos  = 0
                BEGIN
                        SET @sqlstr = 'insert into #TabToCheck values('''+@TabList+''')'
                        EXEC (@sqlstr) BREAK
                END
                SET @sqlstr = 'insert into #TabToCheck values('''+LEFT(@TabList,@NextCommaPos-1)+''')'
                EXEC (@sqlstr)
                SET @TabList = RIGHT(@TabList,LEN(@TabList)-@NextCommaPos)
        END
END
ELSE -- then will check all tables
BEGIN
        EXEC ('insert into #TabToCheck select name from '+@db1+'.dbo.sysobjects where type = ''U''')
        EXEC ('insert into #TabToCheck select name from '+@db2+'.dbo.sysobjects where type = ''U''')
END
-- First check if at least one table specified in @TabList exists in db1
EXEC
('declare @Name sysname select @Name=name from '+@db1+'.dbo.sysobjects where name in (select * from #TabToCheck)')
IF @@rowcount = 0
BEGIN
        PRINT 'No tables in '+@db1+' to check. End of work.'
        RETURN
END
-- Check if tables existing in db1 are in db2 (all tables or specified in @TabList)
IF EXISTS
(
       SELECT *
       FROM   tempdb.dbo.sysobjects
       WHERE  name LIKE '#TabNotInDB2%'
)
DROP TABLE #TabNotInDB2
CREATE TABLE #TabNotInDB2
             (
                          name sysname
             )
INSERT
INTO   #TabNotInDB2
EXEC ('select name from '+@db1+'.dbo.sysobjects d1o '+'where name in (select * from #TabToCheck) and '+' d1o.type = ''U'' and not exists '+'(select * from '+@db2+'.dbo.sysobjects d2o'+' where d2o.type = ''U'' and d2o.name = d1o.name)')
IF @@rowcount > 0
BEGIN
        PRINT CHAR(10)+'The table(s) exist in '+@db1+', but do not exist in '+@db2+':'
        SELECT        *
        FROM   #TabNotInDB2
END
DELETE
FROM   #TabToCheck
WHERE  name IN
               (
               SELECT *
               FROM   #TabNotInDB2
               )
DROP TABLE #TabNotInDB2
IF EXISTS
(
       SELECT *
       FROM   tempdb.dbo.sysobjects
       WHERE  name LIKE '#TabNotInDB1%'
)
DROP TABLE #TabNotInDB1
CREATE TABLE #TabNotInDB1
             (
                          name sysname
             )
INSERT
INTO   #TabNotInDB1
EXEC ('select name from '+@db2+'.dbo.sysobjects d1o '+'where name in (select * from #TabToCheck) and '+' d1o.type = ''U'' and not exists '+'(select * from '+@db1+'.dbo.sysobjects d2o'+' where d2o.type = ''U'' and d2o.name = d1o.name)')
IF @@rowcount > 0
BEGIN
        PRINT CHAR(10)+'The table(s) exist in '+@db2+', but do not exist in '+@db1+':'
        SELECT        *
        FROM   #TabNotInDB1
END
DELETE
FROM   #TabToCheck
WHERE  name IN
               (
               SELECT *
               FROM   #TabNotInDB1
               )
DROP TABLE #TabNotInDB1
-- Comparing structures of tables existing in both dbs
PRINT CHAR(10)+'Checking if there are tables existing in both databases having structural differences ...'+CHAR(10)
IF EXISTS
(
       SELECT *
       FROM   tempdb.dbo.sysobjects
       WHERE  name LIKE '#DiffStructure%'
)
DROP TABLE #DiffStructure
CREATE TABLE #DiffStructure
             (
                          name sysname
             )
SET @sqlStr='
DECLARE @TName1 sysname,
        @TName2 sysname,
        @CName1 sysname,
        @CName2 sysname,
        @TypeName1 sysname,
        @TypeName2 sysname,
        @CLen1 SMALLINT,
        @CLen2 SMALLINT,
        @Type1 sysname,
        @Type2 sysname,
        @PrevTName sysname
DECLARE @DiffStructure bit DECLARE Diff
CURSOR fast_forward FOR
        SELECT   d1o.name  ,
                 d2o.name  ,
                 d1c.name  ,
                 d2c.name  ,
                 d1t.name  ,
                 d2t.name  ,
                 d1c.length,
                 d2c.length,
                 d1c.type  ,
                 d2c.type
        FROM ('+@db1+'.dbo.sysobjects d1o
                 JOIN '+@db2+'.dbo.sysobjects d2o2
                 ON       d1o.name      = d2o2.name
                          AND d1o.type  = ''U'' --only tables in both dbs
                          AND d1o.name IN
                                          (
                                          SELECT *
                                          FROM   #TabToCheck
                                          )
                   JOIN '+@db1+'.dbo.syscolumns d1c
                   ON       d1o.id = d1c.id
                   JOIN '+@db1+'.dbo.systypes d1t
                   ON       d1c.xusertype = d1t.xusertype)
                 FULL JOIN ('+@db2+'.dbo.sysobjects d2o
                          JOIN '+@db1+'.dbo.sysobjects d1o2
                          ON       d1o2.name     = d2o.name
                                   AND d2o.type  = ''U'' --only tables in both dbs
                                   AND d2o.name IN
                                                   (
                                                   SELECT *
                                                   FROM   #TabToCheck
                                                   )
                                   JOIN '+@db2+'.dbo.syscolumns d2c
                                   ON       d2c.id = d2o.id
                                   JOIN '+@db2+'.dbo.systypes d2t
                                   ON       d2c.xusertype = d2t.xusertype)
                 ON       d1o.name                        = d2o.name
                          AND d1c.name                    = d2c.name
        WHERE
                 (
                          NOT EXISTS
                          (
                                 SELECT *
                                 FROM   '+@db2+'.dbo.sysobjects d2o2
                                        JOIN '+@db2+'.dbo.syscolumns d2c2
                                        ON     d2o2.id = d2c2.id
                                        JOIN '+@db2+'.dbo.systypes d2t2
                                        ON     d2c2.xusertype = d2t2.xusertype
                                 WHERE  d2o2.type             = ''U''
                                        AND d2o2.name         = d1o.name
                                        AND d2c2.name         = d1c.name
                                        AND d2t2.name         = d1t.name
                                        AND d2c2.length       = d1c.length
                          )
                          OR NOT EXISTS
                          (
                                 SELECT *
                                 FROM   '+@db1+'.dbo.sysobjects d1o2
                                        JOIN '+@db1+'.dbo.syscolumns d1c2
                                        ON     d1o2.id = d1c2.id
                                        JOIN '+@db1+'.dbo.systypes d1t2
                                        ON     d1c2.xusertype = d1t2.xusertype
                                 WHERE  d1o2.type             = ''U''
                                        AND d1o2.name         = d2o.name
                                        AND d1c2.name         = d2c.name
                                        AND d1t2.name         = d2t.name
                                        AND d1c2.length       = d2c.length
                          )
                 )
        ORDER BY COALESCE(d1o.name,d2o.name),
                 d1c.name
        OPEN Diff
        FETCH NEXT
        FROM  Diff
        INTO  @TName1   ,
              @TName2   ,
              @CName1   ,
              @CName2   ,
              @TypeName1,
              @TypeName2,
              @CLen1    ,
              @CLen2    ,
              @Type1    ,
              @Type2
        SET @PrevTName       = ''''
        SET @DiffStructure   = 0
        WHILE @@fetch_status = 0
        BEGIN
                IF COALESCE(@TName1,@TName2) <> @PrevTName
                BEGIN
                        IF @PrevTName     <> ''''
                        AND @DiffStructure = 1
                        BEGIN
                                INSERT
                                INTO   #DiffStructure VALUES
                                       (
                                              @PrevTName
                                       )
                                SET @DiffStructure = 0
                        END
                        SET @PrevTName = COALESCE(@TName1,@TName2)
                        PRINT @PrevTName
                END
                IF @CName2 IS NULL
                PRINT '' Colimn ''+RTRIM(@CName1)+'' NOT IN '+@db2+'''
                ELSE
                IF @CName1 IS NULL
                PRINT '' Colimn ''+RTRIM(@CName2)+'' NOT IN '+@db1+'''
                ELSE
                IF @TypeName1                         <> @TypeName2
                PRINT '' Colimn ''+RTRIM(@CName1)+'': IN '+@db1+' - ''+RTRIM(@TypeName1)+'', IN '+@db2+' - ''+RTRIM(@TypeName2)
                ELSE --the columns are not null(are in both dbs) and types are equal,then length are diff
                PRINT '' Colimn ''+RTRIM(@CName1)+'': IN '+@db1+' - ''+RTRIM(@TypeName1)+''(''+ LTRIM(STR
                (
                        CASE
                        WHEN @TypeName1       =''nChar''
                                OR @TypeName1 = ''nVarChar'' THEN
                                @CLen1/2
                                ELSE @CLen1
                        END
                ))+''), IN '+@db2+' - ''+RTRIM(@TypeName2)+''(''+ LTRIM(STR
                (
                        CASE
                        WHEN @TypeName1       =''nChar''
                                OR @TypeName1 = ''nVarChar'' THEN
                                @CLen2/2
                                ELSE @CLen2
                        END
                ))+'')''
                IF @Type1         = @Type2
                SET @DiffStructure=@DiffStructure -- Do nothing. Cannot invert predicate
                ELSE
                SET @DiffStructure = 1
                FETCH NEXT
                FROM  Diff
                INTO  @TName1   ,
                      @TName2   ,
                      @CName1   ,
                      @CName2   ,
                      @TypeName1,
                      @TypeName2,
                      @CLen1    ,
                      @CLen2    ,
                      @Type1    ,
                      @Type2
        END
        DEALLOCATE Diff
        IF @DiffStructure = 1
        INSERT
        INTO   #DiffStructure VALUES
               (
                      @PrevTName
               )
'
EXEC (@sqlStr)
IF
   (
   SELECT COUNT(*)
   FROM   #DiffStructure
   )
> 0
BEGIN
        PRINT CHAR(10)  +'The table(s) have the same name and different structure in the databases:'
        SELECT DISTINCT *
        FROM            #DiffStructure
        DELETE
        FROM   #TabToCheck
        WHERE  name IN
                       (
                       SELECT *
                       FROM   #DiffStructure
                       )
END
ELSE
PRINT CHAR(10)+'There are no tables with the same name and structural differences in the databases'+CHAR(10)+CHAR(10)
IF @OnlyStructure = 1
BEGIN
        PRINT 'The option ''Only compare structures'' was specified. End of work.'
        RETURN
END EXEC
('declare @Name sysname select @Name=d1o.name
from '+@db1+'.dbo.sysobjects d1o, '+@db2+'.dbo.sysobjects d2o 
where d1o.name = d2o.name and d1o.type = ''U'' and d2o.type = ''U''
and d1o.name not in (''dtproperties'') 
and d1o.name in (select * from #TabToCheck)')
IF @@rowcount = 0
BEGIN
        PRINT 'There are no tables with the same name and structure in the databases to compare. End of work.'
        RETURN
END
-----------------------------------------------------------------------------------------
-- Comparing data
-----------------------------------------------------------------------------------------
-- ##CompareStr - will be used to pass comparing strings into dynamic script
-- to execute the string
IF EXISTS
(
       SELECT *
       FROM   tempdb.dbo.sysobjects
       WHERE  name LIKE '##CompareStr%'
)
DROP TABLE ##CompareStr
CREATE TABLE ##CompareStr
             (
                          Ind        INT,
                          CompareStr VARCHAR(8000)
             )
IF EXISTS
(
       SELECT *
       FROM   tempdb.dbo.sysobjects
       WHERE  name LIKE '#DiffTables%'
)
DROP TABLE #DiffTables
CREATE TABLE #DiffTables
             (
                          Name sysname
             )
IF EXISTS
(
       SELECT *
       FROM   tempdb.dbo.sysobjects
       WHERE  name LIKE '#IdenticalTables%'
)
DROP TABLE #IdenticalTables
CREATE TABLE #IdenticalTables
             (
                          Name sysname
             )
IF EXISTS
(
       SELECT *
       FROM   tempdb.dbo.sysobjects
       WHERE  name LIKE '#EmptyTables%'
)
DROP TABLE #EmptyTables
CREATE TABLE #EmptyTables
             (
                          Name sysname
             )
IF EXISTS
(
       SELECT *
       FROM   tempdb.dbo.sysobjects
       WHERE  name LIKE '#NoPKTables%'
)
DROP TABLE #NoPKTables
CREATE TABLE #NoPKTables
             (
                          Name sysname
             )
IF EXISTS
(
       SELECT *
       FROM   tempdb.dbo.sysobjects
       WHERE  name LIKE '#IndList1%'
)
TRUNCATE TABLE #IndList1
ELSE
CREATE TABLE #IndList1
             (
                          IndId       INT          ,
                          IndStatus   INT          ,
                          KeyAndStr   VARCHAR(7000),
                          KeyCommaStr VARCHAR(1000)
             )
IF EXISTS
(
       SELECT *
       FROM   tempdb.dbo.sysobjects
       WHERE  name LIKE '#IndList2%'
)
TRUNCATE TABLE #IndList2
ELSE
CREATE TABLE #IndList2
             (
                          IndId       SMALLINT     ,
                          IndStatus   INT          ,
                          KeyAndStr   VARCHAR(7000),
                          KeyCommaStr VARCHAR(1000)
             )
PRINT REPLICATE('-',51)
PRINT 'Comparing data in tables with indentical structure:'
PRINT REPLICATE('-',51)
--------------------------------------------------------------------------------------------
-- Cursor for all tables in dbs (or for all specified tables if parameter @TabList is passed)
--------------------------------------------------------------------------------------------
DECLARE @SqlStrGetListOfKeys1       VARCHAR(8000)
DECLARE @SqlStrGetListOfKeys2       VARCHAR(8000)
DECLARE @SqlStrGetListOfColumns     VARCHAR(8000)
DECLARE @SqlStrCompareUKeyTables    VARCHAR(8000)
DECLARE @SqlStrCompareNonUKeyTables VARCHAR(8000)
SET @SqlStrGetListOfKeys1       = ' 
DECLARE @sqlStr VARCHAR(8000)
DECLARE @ExecSqlStr VARCHAR(8000)
DECLARE @PrintSqlStr VARCHAR(8000)
DECLARE @Tab VARCHAR(128)
DECLARE @d1User VARCHAR(128)
DECLARE @d2User VARCHAR(128)
DECLARE @KeyAndStr VARCHAR(8000)
DECLARE @KeyCommaStr VARCHAR(8000)
DECLARE @AndStr VARCHAR(8000)
DECLARE @Eq VARCHAR(8000)
DECLARE @IndId INT
DECLARE @IndStatus INT
DECLARE @CurrIndId SMALLINT
DECLARE @CurrStatus INT
DECLARE @UKey sysname
DECLARE @Col VARCHAR(128)
DECLARE @LastUsedCol VARCHAR(128)
DECLARE @xType INT
DECLARE @Len INT
DECLARE @SelectStr VARCHAR(8000)
DECLARE @ExecSql nvarchar(1000)
DECLARE @NotInDB1 bit
DECLARE @NotInDB2 bit
DECLARE @NotEq bit
DECLARE @Numb INT
DECLARE @Cnt1 INT
DECLARE @Cnt2 INT
SET @Numb = 0
DECLARE @StrInd INT
DECLARE @i INT
DECLARE @PrintStr VARCHAR(8000)
DECLARE @ExecStr VARCHAR(8000)
DECLARE TabCur CURSOR FOR
SELECT   d1o.name,
         d1u.name,
         d2u.name
FROM     '+@db1+'.dbo.sysobjects d1o,
         '+@db2+'.dbo.sysobjects d2o,
         '+@db1+'.dbo.sysusers d1u  ,
         '+@db2+'.dbo.sysusers d2u
WHERE    d1o.name = d2o.name
         AND d1o.type = ''U''
         AND d2o.type = ''U''
         AND d1o.uid = d1u.uid
         AND d2o.uid = d2u.uid
         AND d1o.name NOT IN (''dtproperties'')
         AND d1o.name IN
                         (
                         SELECT *
                         FROM   #TabToCheck
                         )
ORDER BY 1
OPEN TabCur
FETCH NEXT
FROM  TabCur
INTO  @Tab   ,
      @d1User,
      @d2User
WHILE @@fetch_status = 0
BEGIN
        SET @Numb = @Numb + 1
        PRINT CHAR(13)+CHAR(10)+LTRIM(STR(@Numb))+''. TABLE: [''+@Tab+''] ''
        SET @ExecSql = ''
        SELECT @Cnt = COUNT(*)
        FROM   '+@db1+'.[''+@d1User+''].[''+@Tab+'']''
        EXEC sp_executesql @ExecSql,
                N''@Cnt INT output'',
                @Cnt = @Cnt1 output
        PRINT CHAR(10)+STR(@Cnt1)+'' rows IN '+@db1+'''
        SET @ExecSql = ''
        SELECT @Cnt = COUNT(*)
        FROM   '+@db2+'.[''+@d2User+''].[''+@Tab+'']''
        EXEC sp_executesql @ExecSql,
                N''@Cnt INT output'',
                @Cnt = @Cnt2 output
        PRINT STR(@Cnt2)+'' rows IN '+@db2+'''
        IF @Cnt1 = 0
        AND @Cnt2 = 0
        BEGIN
                EXEC (''
                INSERT
                INTO   #EmptyTables VALUES
                       (
                              ''''[''+@Tab+'']''''
                       )
                       '') GOTO NextTab
        END
        SET @KeyAndStr = ''''
        SET @KeyCommaStr = ''''
        SET @NotInDB1 = 0
        SET @NotInDB2 = 0
        SET @NotEq = 0
        SET @KeyAndStr = ''''
        SET @KeyCommaStr = ''''
        TRUNCATE TABLE #IndList1
        DECLARE UKeys CURSOR fast_forward FOR
        SELECT   i.indid ,
                 i.status,
                 c.name  ,
                 c.xType
        FROM     '+@db1+'.dbo.sysobjects o  ,
                 '+@db1+'.dbo.sysindexes i  ,
                 '+@db1+'.dbo.sysindexkeys k,
                 '+@db1+'.dbo.syscolumns c
        WHERE    i.id = o.id
                 AND o.name = @Tab
                 AND
                 (
                          i.status & 2
                 )
                 <>0
                 AND k.id = o.id
                 AND k.indid = i.indid
                 AND c.id = o.id
                 AND c.colid = k.colid
        ORDER BY i.indid,
                 c.name
        OPEN UKeys
        FETCH NEXT
        FROM  UKeys
        INTO  @IndId    ,
              @IndStatus,
              @UKey     ,
              @xType
        SET @CurrIndId = @IndId
        SET @CurrStatus = @IndStatus
        WHILE @@fetch_status = 0
        BEGIN
                IF @KeyAndStr <> ''''
                BEGIN
                        SET @KeyAndStr = @KeyAndStr + ''
                        AND '' + CHAR(10)
                        SET @KeyCommaStr = @KeyCommaStr + '',
                                ''
                END
                IF @xType = 175
                OR @xType = 167
                OR @xType = 239
                OR @xType = 231 -- char, varchar, nchar, nvarchar
                BEGIN
                        SET @KeyAndStr = @KeyAndStr + '' ISNULL(d1.[''+@UKey+''],''''!#null$'''')=ISNULL(d2.[''+@UKey+''],''''!#null$'''') ''
                END
                IF @xType = 173
                OR @xType = 165 -- binary, varbinary
                BEGIN
                        SET @KeyAndStr = @KeyAndStr +''
                        CASE
                        WHEN d1.[''+@UKey+''] IS NULL THEN
                                0x4D4FFB23A49411D5BDDB00A0C906B7B4
                                ELSE d1.[''+@UKey+'']
                        END
                        =''+''
                        CASE
                        WHEN d2.[''+@UKey+''] IS NULL THEN
                                0x4D4FFB23A49411D5BDDB00A0C906B7B4
                                ELSE d2.[''+@UKey+'']
                        END
                        ''
                END
                ELSE
                IF @xType = 56
                OR @xType = 127
                OR @xType = 60
                OR @xType = 122 -- int, 127 - bigint,60 - money, 122 - smallmoney
                BEGIN
                        SET @KeyAndStr = @KeyAndStr + ''
                        CASE
                        WHEN d1.[''+@UKey+''] IS NULL THEN
                                971428763405345098745
                                ELSE d1.[''+@UKey+'']
                        END
                        =''+''
                        CASE
                        WHEN d2.[''+@UKey+''] IS NULL THEN
                                971428763405345098745
                                ELSE d2.[''+@UKey+'']
                        END
                        ''
                END
                ELSE
                IF @xType = 106
                OR @xType = 108 -- int, decimal, numeric
                BEGIN
                        SET @KeyAndStr = @KeyAndStr + ''
                        CASE
                        WHEN d1.[''+@UKey+''] IS NULL THEN
                                71428763405345098745098.8723
                                ELSE d1.[''+@UKey+'']
                        END
                        =''+''
                        CASE
                        WHEN d2.[''+@UKey+''] IS NULL THEN
                                71428763405345098745098.8723
                                ELSE d2.[''+@UKey+'']
                        END
                        ''
                END
                ELSE
                IF @xType = 62
                OR @xType = 59 -- 62 - float, 59 - real
                BEGIN
                        SET @KeyAndStr = @KeyAndStr + ''
                        CASE
                        WHEN d1.[''+@UKey+''] IS NULL THEN
                                8764589764.22708E237
                                ELSE d1.[''+@UKey+'']
                        END
                        =''+''
                        CASE
                        WHEN d2.[''+@UKey+''] IS NULL THEN
                                8764589764.22708E237
                                ELSE d2.[''+@UKey+'']
                        END
                        ''
                END
                ELSE
                IF @xType = 52
                OR @xType = 48
                OR @xType = 104 -- smallint, tinyint, bit
                BEGIN
                        SET @KeyAndStr = @KeyAndStr + ''
                        CASE
                        WHEN d1.[''+@UKey+''] IS NULL THEN
                                99999
                                ELSE d1.[''+@UKey+'']
                        END
                        =''+''
                        CASE
                        WHEN d2.[''+@UKey+''] IS NULL THEN
                                99999
                                ELSE d2.[''+@UKey+'']
                        END
                        ''
                END
                ELSE
                IF @xType = 36 -- 36 - id
                BEGIN
                        SET @KeyAndStr = @KeyAndStr +''
                        CASE
                        WHEN d1.[''+@UKey+''] IS NULL''+'' THEN
                                CONVERT(uniqueidentifier,''''1CD827A0-744A-4866-8401-B9902CF2D4FB'''')''+''
                                ELSE d1.[''+@UKey+'']
                        END
                        =''+''
                        CASE
                        WHEN d2.[''+@UKey+''] IS NULL''+'' THEN
                                CONVERT(uniqueidentifier,''''1CD827A0-744A-4866-8401-B9902CF2D4FB'''')''+''
                                ELSE d2.[''+@UKey+'']
                        END
                        ''
                END
                ELSE
                IF @xType = 61
                OR @xType = 58 -- datetime, smalldatetime
                BEGIN
                        SET @KeyAndStr = @KeyAndStr +''
                        CASE
                        WHEN d1.[''+@UKey+''] IS NULL THEN
                                ''''!#null$''''
                                ELSE CONVERT(VARCHAR(40),d1.[''+@UKey+''],109)
                        END
                        =''+''
                        CASE
                        WHEN d2.[''+@UKey+''] IS NULL THEN
                                ''''!#null$''''
                                ELSE CONVERT(VARCHAR(40),d2.[''+@UKey+''],109)
                        END
                        ''
                END
                ELSE
                IF @xType = 189 -- timestamp (189)
                BEGIN
                        SET @KeyAndStr = @KeyAndStr + '' d1.[''+@UKey+'']=d2.[''+@UKey+''] ''
                END
                ELSE
                IF @xType = 98 -- SQL_variant
                BEGIN
                        SET @KeyAndStr = @KeyAndStr + '' ISNULL(d1.[''+@UKey+''],''''!#null$'''')=ISNULL(d2.[''+@UKey+''],''''!#null$'''') ''
                END
                SET @KeyCommaStr = @KeyCommaStr + '' d1.''+@UKey
                FETCH NEXT
                FROM  UKeys
                INTO  @IndId    ,
                      @IndStatus,
                      @UKey     ,
                      @xType
                IF @IndId <> @CurrIndId
                BEGIN
                        INSERT
                        INTO   #IndList1 VALUES
                               (
                                      @CurrIndId ,
                                      @CurrStatus,
                                      @KeyAndStr ,
                                      @KeyCommaStr
                               )
                        SET @CurrIndId = @IndId
                        SET @CurrStatus = @IndStatus
                        SET @KeyAndStr = ''''
                        SET @KeyCommaStr = ''''
                END
        END
        DEALLOCATE UKeys
        INSERT
        INTO   #IndList1 VALUES
               (
                      @CurrIndId ,
                      @CurrStatus,
                      @KeyAndStr ,
                      @KeyCommaStr
               )'
SET @SqlStrGetListOfKeys2       = ' 
SET @KeyAndStr = ''''
SET @KeyCommaStr = ''''
TRUNCATE TABLE #IndList2
DECLARE UKeys CURSOR fast_forward FOR
SELECT   i.indid ,
         i.status,
         c.name  ,
         c.xType
FROM     '                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              +@db2+'.dbo.sysobjects o,
         '+@db2+'.dbo.sysindexes i                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ,
         '+@db2+'.dbo.sysindexkeys k                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ,
         '+@db2+'.dbo.syscolumns c
WHERE    i.id = o.id
         AND o.name = @Tab
         AND
         (
                  i.status & 2
         )
         <>0
         AND k.id = o.id
         AND k.indid = i.indid
         AND c.id = o.id
         AND c.colid = k.colid
ORDER BY i.indid,
         c.name
OPEN UKeys
FETCH NEXT
FROM  UKeys
INTO  @IndId    ,
      @IndStatus,
      @UKey     ,
      @xType
SET @CurrIndId = @IndId
SET @CurrStatus = @IndStatus
WHILE @@fetch_status = 0
BEGIN
        IF @KeyAndStr <> ''''
        BEGIN
                SET @KeyAndStr = @KeyAndStr + ''
                AND '' + CHAR(10)
                SET @KeyCommaStr = @KeyCommaStr + '',
                        ''
        END
        IF @xType = 175
        OR @xType = 167
        OR @xType = 239
        OR @xType = 231 -- char, varchar, nchar, nvarchar
        BEGIN
                SET @KeyAndStr = @KeyAndStr + '' ISNULL(d1.[''+@UKey+''],''''!#null$'''')=ISNULL(d2.[''+@UKey+''],''''!#null$'''') ''
        END
        IF @xType = 173
        OR @xType = 165 -- binary, varbinary
        BEGIN
                SET @KeyAndStr = @KeyAndStr +''
                CASE
                WHEN d1.[''+@UKey+''] IS NULL THEN
                        0x4D4FFB23A49411D5BDDB00A0C906B7B4
                        ELSE d1.[''+@UKey+'']
                END
                =''+''
                CASE
                WHEN d2.[''+@UKey+''] IS NULL THEN
                        0x4D4FFB23A49411D5BDDB00A0C906B7B4
                        ELSE d2.[''+@UKey+'']
                END
                ''
        END
        ELSE
        IF @xType = 56
        OR @xType = 127
        OR @xType = 60
        OR @xType = 122 -- int, 127 - bigint,60 - money, 122 - smallmoney
        BEGIN
                SET @KeyAndStr = @KeyAndStr + ''
                CASE
                WHEN d1.[''+@UKey+''] IS NULL THEN
                        971428763405345098745
                        ELSE d1.[''+@UKey+'']
                END
                =''+''
                CASE
                WHEN d2.[''+@UKey+''] IS NULL THEN
                        971428763405345098745
                        ELSE d2.[''+@UKey+'']
                END
                ''
        END
        ELSE
        IF @xType = 106
        OR @xType = 108 -- int, decimal, numeric
        BEGIN
                SET @KeyAndStr = @KeyAndStr + ''
                CASE
                WHEN d1.[''+@UKey+''] IS NULL THEN
                        71428763405345098745098.8723
                        ELSE d1.[''+@UKey+'']
                END
                =''+''
                CASE
                WHEN d2.[''+@UKey+''] IS NULL THEN
                        71428763405345098745098.8723
                        ELSE d2.[''+@UKey+'']
                END
                ''
        END
        ELSE
        IF @xType = 62
        OR @xType = 59 -- 62 - float, 59 - real
        BEGIN
                SET @KeyAndStr = @KeyAndStr + ''
                CASE
                WHEN d1.[''+@UKey+''] IS NULL THEN
                        8764589764.22708E237
                        ELSE d1.[''+@UKey+'']
                END
                =''+''
                CASE
                WHEN d2.[''+@UKey+''] IS NULL THEN
                        8764589764.22708E237
                        ELSE d2.[''+@UKey+'']
                END
                ''
        END
        ELSE
        IF @xType = 52
        OR @xType = 48
        OR @xType = 104 -- smallint, tinyint, bit
        BEGIN
                SET @KeyAndStr = @KeyAndStr + ''
                CASE
                WHEN d1.[''+@UKey+''] IS NULL THEN
                        99999
                        ELSE d1.[''+@UKey+'']
                END
                =''+''
                CASE
                WHEN d2.[''+@UKey+''] IS NULL THEN
                        99999
                        ELSE d2.[''+@UKey+'']
                END
                ''
        END
        ELSE
        IF @xType = 36 -- 36 - id
        BEGIN
                SET @KeyAndStr = @KeyAndStr +''
                CASE
                WHEN d1.[''+@UKey+''] IS NULL''+'' THEN
                        CONVERT(uniqueidentifier,''''1CD827A0-744A-4866-8401-B9902CF2D4FB'''')''+''
                        ELSE d1.[''+@UKey+'']
                END
                =''+''
                CASE
                WHEN d2.[''+@UKey+''] IS NULL''+'' THEN
                        CONVERT(uniqueidentifier,''''1CD827A0-744A-4866-8401-B9902CF2D4FB'''')''+''
                        ELSE d2.[''+@UKey+'']
                END
                ''
        END
        ELSE
        IF @xType = 61
        OR @xType = 58 -- datetime, smalldatetime
        BEGIN
                SET @KeyAndStr = @KeyAndStr +''
                CASE
                WHEN d1.[''+@UKey+''] IS NULL THEN
                        ''''!#null$''''
                        ELSE CONVERT(VARCHAR(40),d1.[''+@UKey+''],109)
                END
                =''+''
                CASE
                WHEN d2.[''+@UKey+''] IS NULL THEN
                        ''''!#null$''''
                        ELSE CONVERT(VARCHAR(40),d2.[''+@UKey+''],109)
                END
                ''
        END
        ELSE
        IF @xType = 189 -- timestamp (189)
        BEGIN
                SET @KeyAndStr = @KeyAndStr + '' d1.[''+@UKey+'']=d2.[''+@UKey+''] ''
        END
        ELSE
        IF @xType = 98 -- SQL_variant
        BEGIN
                SET @KeyAndStr = @KeyAndStr + '' ISNULL(d1.[''+@UKey+''],''''!#null$'''')=ISNULL(d2.[''+@UKey+''],''''!#null$'''') ''
        END
        SET @KeyCommaStr = @KeyCommaStr + '' d1.''+@UKey
        FETCH NEXT
        FROM  UKeys
        INTO  @IndId    ,
              @IndStatus,
              @UKey     ,
              @xType
        IF @IndId <> @CurrIndId
        BEGIN
                INSERT
                INTO   #IndList2 VALUES
                       (
                              @CurrIndId ,
                              @CurrStatus,
                              @KeyAndStr ,
                              @KeyCommaStr
                       )
                SET @CurrIndId = @IndId
                SET @CurrStatus = @IndStatus
                SET @KeyAndStr = ''''
                SET @KeyCommaStr = ''''
        END
END
DEALLOCATE UKeys
INSERT
INTO   #IndList2 VALUES
       (
              @CurrIndId ,
              @CurrStatus,
              @KeyAndStr ,
              @KeyCommaStr
       )
SET @KeyCommaStr = NULL
SELECT @KeyCommaStr=i1.KeyCommaStr
FROM   #IndList1 i1
       JOIN #IndList2 i2
       ON     i1.KeyCommaStr = i2.KeyCommaStr
WHERE
       (
              i1.IndStatus & 2048
       )
       <> 0
       AND
       (
              i2.IndStatus & 2048
       )
       <>0
IF @KeyCommaStr IS NULL
SET @KeyCommaStr =
(
       SELECT top 1 i1.KeyCommaStr
       FROM   #IndList1 i1
              JOIN #IndList2 i2
              ON     i1.KeyCommaStr = i2.KeyCommaStr
)
SET @KeyAndStr =
(
       SELECT TOP 1 KeyAndStr
       FROM   #IndList1
       WHERE  KeyCommaStr = @KeyCommaStr
)
IF @KeyCommaStr IS NULL
SET @KeyCommaStr = ''''
IF @KeyAndStr IS NULL
SET @KeyAndStr = '''''
SET @SqlStrGetListOfColumns     = ' 
SET @AndStr = ''''
SET @StrInd = 1
DECLARE Cols CURSOR local fast_forward FOR
SELECT c.name ,
       c.xtype,
       c.length
FROM   '                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        +@db1+'.dbo.sysobjects o,
       '+@db1+'.dbo.syscolumns c
WHERE  o.id = c.id
       AND o.name = @Tab
       AND CHARINDEX(c.name, @KeyCommaStr) = 0
OPEN Cols
FETCH NEXT
FROM  Cols
INTO  @Col  ,
      @xType,
      @len
WHILE @@fetch_status = 0
BEGIN
        IF @xType = 175
        OR @xType = 167
        OR @xType = 239
        OR @xType = 231 -- char, varchar, nchar, nvarchar
        BEGIN
                SET @Eq = ''ISNULL(d1.[''+@Col+''],''''!#null$'''')=ISNULL(d2.[''+@Col+''],''''!#null$'''') ''
        END
        IF @xType = 173
        OR @xType = 165 -- binary, varbinary
        BEGIN
                SET @Eq = ''
                CASE
                WHEN d1.[''+@Col+''] IS NULL THEN
                        0x4D4FFB23A49411D5BDDB00A0C906B7B4
                        ELSE d1.[''+@Col+'']
                END
                =''+''
                CASE
                WHEN d2.[''+@Col+''] IS NULL THEN
                        0x4D4FFB23A49411D5BDDB00A0C906B7B4
                        ELSE d2.[''+@Col+'']
                END
                ''
        END
        ELSE
        IF @xType = 56
        OR @xType = 127
        OR @xType = 60
        OR @xType = 122 -- int, 127 - bigint,60 - money, 122 - smallmoney
        BEGIN
                SET @Eq = ''
                CASE
                WHEN d1.[''+@Col+''] IS NULL THEN
                        971428763405345098745
                        ELSE d1.[''+@Col+'']
                END
                =''+''
                CASE
                WHEN d2.[''+@Col+''] IS NULL THEN
                        971428763405345098745
                        ELSE d2.[''+@Col+'']
                END
                ''
        END
        ELSE
        IF @xType = 106
        OR @xType = 108 -- int, decimal, numeric
        BEGIN
                SET @Eq = ''
                CASE
                WHEN d1.[''+@Col+''] IS NULL THEN
                        71428763405345098745098.8723
                        ELSE d1.[''+@Col+'']
                END
                =''+''
                CASE
                WHEN d2.[''+@Col+''] IS NULL THEN
                        71428763405345098745098.8723
                        ELSE d2.[''+@Col+'']
                END
                ''
        END
        ELSE
        IF @xType = 62
        OR @xType = 59 -- 62 - float, 59 - real
        BEGIN
                SET @Eq = ''
                CASE
                WHEN d1.[''+@Col+''] IS NULL THEN
                        8764589764.22708E237
                        ELSE d1.[''+@Col+'']
                END
                =''+''
                CASE
                WHEN d2.[''+@Col+''] IS NULL THEN
                        8764589764.22708E237
                        ELSE d2.[''+@Col+'']
                END
                ''
        END
        ELSE
        IF @xType = 52
        OR @xType = 48
        OR @xType = 104 -- smallint, tinyint, bit
        BEGIN
                SET @Eq = ''
                CASE
                WHEN d1.[''+@Col+''] IS NULL THEN
                        99999
                        ELSE d1.[''+@Col+'']
                END
                =''+''
                CASE
                WHEN d2.[''+@Col+''] IS NULL THEN
                        99999
                        ELSE d2.[''+@Col+'']
                END
                ''
        END
        ELSE
        IF @xType = 36 -- 36 - id
        BEGIN
                SET @Eq = ''
                CASE
                WHEN d1.[''+@Col+''] IS NULL''+'' THEN
                        CONVERT(uniqueidentifier,''''1CD827A0-744A-4866-8401-B9902CF2D4FB'''')''+''
                        ELSE d1.[''+@Col+'']
                END
                =''+''
                CASE
                WHEN d2.[''+@Col+''] IS NULL''+'' THEN
                        CONVERT(uniqueidentifier,''''1CD827A0-744A-4866-8401-B9902CF2D4FB'''')''+''
                        ELSE d2.[''+@Col+'']
                END
                ''
        END
        ELSE
        IF @xType = 61
        OR @xType = 58 -- datetime, smalldatetime
        BEGIN
                SET @Eq =''
                CASE
                WHEN d1.[''+@Col+''] IS NULL THEN
                        ''''!#null$''''
                        ELSE CONVERT(VARCHAR(40),d1.[''+@Col+''],109)
                END
                =''+''
                CASE
                WHEN d2.[''+@Col+''] IS NULL THEN
                        ''''!#null$''''
                        ELSE CONVERT(VARCHAR(40),d2.[''+@Col+''],109)
                END
                ''
        END
        ELSE
        IF @xType = 34
        BEGIN
                SET @Eq = ''ISNULL(DATALENGTH(d1.[''+@Col+'']),0)=ISNULL(DATALENGTH(d2.[''+@Col+'']),0) ''
        END
        ELSE
        IF @xType = 35
        OR @xType = 99 -- text (35),ntext (99)
        BEGIN
                SET @Eq = ''ISNULL(SUBSTRING(d1.[''+@Col+''],1,DATALENGTH(d1.[''+@Col+''])),''''!#null$'''')=ISNULL(SUBSTRING(d2.[''+@Col+''],1,DATALENGTH(d2.[''+@Col+''])),''''!#null$'''') ''
        END
        ELSE
        IF @xType = 189
        BEGIN
                IF '+STR(@NoTimestamp)+' = 0
                SET @Eq = ''d1.[''+@Col+'']=d2.[''+@Col+''] ''
                ELSE
                SET @Eq = ''1=1''
        END
        ELSE
        IF @xType = 98 -- SQL_variant
        BEGIN
                SET @Eq = ''ISNULL(d1.[''+@Col+''],''''!#null$'''')=ISNULL(d2.[''+@Col+''],''''!#null$'''') ''
        END
        IF @AndStr = ''''
        SET @AndStr = @AndStr + CHAR(10) + '' '' + @Eq
        ELSE
        IF LEN(@AndStr) + LEN(''
        AND '' + @Eq)<8000
        SET @AndStr = @AndStr + ''
        AND '' + CHAR(10) + '' '' + @Eq
        ELSE
        BEGIN
                SET @StrInd = @StrInd + 1
                INSERT
                INTO   ##CompareStr VALUES
                       (
                              @StrInd,
                              @AndStr
                       )
                SET @AndStr = ''
                AND '' + @Eq
        END
        FETCH NEXT
        FROM  Cols
        INTO  @Col  ,
              @xType,
              @len
END
DEALLOCATE Cols '
SET @SqlStrCompareUKeyTables    = ' 
if @KeyAndStr <> ''''
begin
set @SelectStr = ''SELECT ''+ @KeyCommaStr+'' INTO ##NotInDb2 FROM '                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              +@db1+'.[''+@d1User+''].[''+@Tab+''] d1 ''+ 
'' WHERE not exists''+CHAR(10)+'' (SELECT * FROM '+@db2+'.[''+@d2User+''].[''+@Tab+''] d2 ''+ 
'' WHERE ''+CHAR(10)+@KeyAndStr+'')''
if '+STR(@VerboseLevel)+' = 1
print CHAR(10)+''To find rows that are in '+@db1+', but are not in db2:''+CHAR(10)+
REPLACE (@SelectStr, ''into ##NotInDB2'','''')
exec (@SelectStr) 
if @@rowcount > 0 
set @NotInDB2 = 1 
set @SelectStr = ''SELECT ''+@KeyCommaStr+'' INTO ##NotInDB1 FROM '+@db2+'.[''+@d2User+''].[''+@Tab+''] d1 ''+ 
'' WHERE not exists''+CHAR(10)+'' (SELECT * FROM '+@db1+'.[''+@d1User+''].[''+@Tab+''] d2 ''+ 
'' WHERE ''+CHAR(10)+@KeyAndStr+'')'' 
if '+STR(@VerboseLevel)+' = 1
print CHAR(10)+''To find rows that are in '+@db2+', but are not in '+@db1+':''+CHAR(10)+
REPLACE (@SelectStr, ''into ##NotInDB1'','''')
exec (@SelectStr) 
if @@rowcount > 0 
set @NotInDB1 = 1 
-- if there are non-key columns
if @AndStr <> '''' 
begin
set @PrintStr = '' Print ''
set @ExecStr = '' exec (''
set @SqlStr = ''''
Insert into ##CompareStr values(1,
''SELECT ''+ @KeyCommaStr+'' INTO ##NotEq FROM '+@db2+'.[''+@d2User+''].[''+@Tab+''] d1 ''+ 
'' INNER JOIN '+@db1+'.[''+@d1User+''].[''+@Tab+''] d2 ON ''+CHAR(10)+@KeyAndStr+CHAR(10)+''WHERE not('') 
-- Adding last string in temp table containing a comparing string to execute
set @StrInd = @StrInd + 1
Insert into ##CompareStr values(@StrInd,@AndStr+'')'')
set @i = 1
while @i <= @StrInd
begin
set @SqlStr = @SqlStr + '' declare @Str''+LTRIM(STR(@i))+'' varchar(8000) ''+
''select @Str''+LTRIM(STR(@i))+''=CompareStr FROM ##CompareStr WHERE ind = ''+STR(@i)
if @ExecStr <> '' exec (''
set @ExecStr = @ExecStr + ''+''
if @PrintStr <> '' Print ''
set @PrintStr = @PrintStr + ''+''
set @ExecStr = @ExecStr + ''@Str''+LTRIM(STR(@i))
set @PrintStr = @PrintStr + '' REPLACE(@Str''+LTRIM(STR(@i))+'','''' into ##NotEq'''','''''''') ''
set @i = @i + 1
end
set @ExecStr = @ExecStr + '') ''
set @ExecSqlStr = @SqlStr + @ExecStr 
set @PrintSqlStr = @SqlStr + 
'' Print CHAR(10)+''''To find rows that are different in non-key columns:'''' ''+
@PrintStr 
if '+STR(@VerboseLevel)+' = 1
exec (@PrintSqlStr)
exec (@ExecSqlStr)

if @@rowcount > 0 
set @NotEq = 1 
end
else
if '+STR(@VerboseLevel)+' = 1
PRINT CHAR(10)+''There are no non-KEY columns IN the TABLE''
TRUNCATE TABLE ##CompareStr
IF @NotInDB1 = 1
OR @NotInDB2 = 1
OR @NotEq = 1
BEGIN
        PRINT CHAR(10)+''Data are different''
        IF @NotInDB2 = 1
        AND '+STR(@NumbToShow)+' > 0
        BEGIN
                PRINT ''These KEY VALUES exist IN '+@db1+', but DO NOT exist IN '+@db2+': ''
                SET @SelectStr = ''
                SELECT top ''+STR('+STR(@NumbToShow)+')+'' *
                FROM   ##NotInDB2''
                EXEC (@SelectStr)
        END
        IF @NotInDB1 = 1
        AND '+STR(@NumbToShow)+' > 0
        BEGIN
                PRINT ''These KEY VALUES exist IN '+@db2+', but DO NOT exist IN '+@db1+': ''
                SET @SelectStr = ''
                SELECT top ''+STR('+STR(@NumbToShow)+')+'' *
                FROM   ##NotInDB1''
                EXEC (@SelectStr)
        END
        IF @NotEq = 1
        AND '+STR(@NumbToShow)+' > 0
        BEGIN
                PRINT ''Row(s) WITH these KEY VALUES contain differences IN non-KEY columns: ''
                SET @SelectStr = ''
                SELECT top ''+STR('+STR(@NumbToShow)+')+'' *
                FROM   ##NotEq''
                EXEC (@SelectStr)
        END EXEC
(''
INSERT
INTO   #DiffTables VALUES
       (
              ''''[''+@Tab+'']''''
       )
       '')
END
ELSE
BEGIN
        PRINT CHAR(10)+''Data are identical''
        EXEC (''
        INSERT
        INTO   #IdenticalTables VALUES
               (
                      ''''[''+@Tab+'']''''
               )
               '')
END
IF EXISTS
(
       SELECT *
       FROM   tempdb.dbo.sysobjects
       WHERE  name LIKE ''##NotEq%''
)
DROP TABLE ##NotEq
END
ELSE '
SET @SqlStrCompareNonUKeyTables = ' 
BEGIN
        EXEC (''
        INSERT
        INTO   #NoPKTables VALUES
               (
                      ''''[''+@Tab+'']''''
               )
               '')
 SET @PrintStr = ''
 PRINT ''
 SET @ExecStr = ''
 EXEC (''
 SET @SqlStr = ''''
 INSERT
 INTO   ##CompareStr VALUES
        (
               1,
               ''
        SELECT ''+'' *
        INTO   ##NotInDB2
        FROM   '                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   +@db1+'.[''+@d1User+''].[''+@Tab+''] d1
        WHERE  NOT EXISTS ''+CHAR(10)+''
               (
                      SELECT *
                      FROM   '+@db2+'.[''+@d2User+''].[''+@Tab+''] d2
                      WHERE  ''
               )
               SET @StrInd = @StrInd + 1
        INSERT
        INTO   ##CompareStr VALUES
               (
                      @StrInd,
                      @AndStr+''
               )
               ''
        )
 SET @i = 1
 WHILE @i <= @StrInd
 BEGIN
         SET @SqlStr = @SqlStr + ''
         DECLARE @Str''+LTRIM(STR(@i))+'' VARCHAR(8000) ''+''
         SELECT @Str''+LTRIM(STR(@i))+''=CompareStr
         FROM   ##CompareStr
         WHERE  ind = ''+STR(@i)
         IF @ExecStr <> ''
         EXEC (''
         SET @ExecStr = @ExecStr + ''+''
         IF @PrintStr <> ''
         PRINT ''
         SET @PrintStr = @PrintStr + ''+''
         SET @ExecStr = @ExecStr + ''@Str''+LTRIM(STR(@i))
         SET @PrintStr = @PrintStr + '' REPLACE(@Str''+LTRIM(STR(@i))+'','''' INTO ##NotInDB2'''','''''''') ''
         SET @i = @i + 1
 END
 SET @ExecStr = @ExecStr + '') ''
         SET @ExecSqlStr = @SqlStr + @ExecStr
         SET @PrintSqlStr = @SqlStr +
'' Print CHAR(10)+''''To find rows that are in '+@db1+', but are not in '+@db2+':'''' ''+
@PrintStr 
if '+STR(@VerboseLevel)+' = 1
exec (@PrintSqlStr)
exec (@ExecSqlStr)

IF @@rowcount > 0
SET @NotInDB2 = 1
DELETE
FROM   ##CompareStr
WHERE  ind = 1
SET @PrintStr = ''
PRINT ''
SET @ExecStr = ''
EXEC (''
SET @SqlStr = ''''
INSERT
INTO   ##CompareStr VALUES
       (
              1,
              ''
       SELECT ''+'' *
       INTO   ##NotInDB1
       FROM   '+@db2+'.[''+@d2User+''].[''+@Tab+''] d1
       WHERE  NOT EXISTS ''+CHAR(10)+''
              (
                     SELECT *
                     FROM   '+@db1+'.[''+@d1User+''].[''+@Tab+''] d2
                     WHERE  ''
              )
              SET @i = 1 WHILE @i <= @StrInd BEGIN SET @SqlStr = @SqlStr + '' DECLARE @Str''+LTRIM(STR(@i))+'' VARCHAR(8000) ''+''
       SELECT @Str''+LTRIM(STR(@i))+''=CompareStr
       FROM   ##CompareStr
       WHERE  ind = ''+STR(@i) IF @ExecStr <> '' EXEC (''SET @ExecStr = @ExecStr + ''+''IF @PrintStr <> '' PRINT ''SET @PrintStr = @PrintStr + ''+''SET @ExecStr = @ExecStr + ''@Str''+LTRIM(STR(@i)) SET @PrintStr = @PrintStr + '' REPLACE(@Str''+LTRIM(STR(@i))+'','''' INTO ##NotInDB1'''','''''''') ''SET @i = @i + 1
END SET @ExecStr = @ExecStr + '') ''SET @ExecSqlStr = @SqlStr + @ExecStr SET @PrintSqlStr = @SqlStr +
'' Print CHAR(10)+''''To find rows that are in '+@db2+', but are not in '+@db1+':'''' ''+
@PrintStr 
if '+STR(@VerboseLevel)+' = 1
exec (@PrintSqlStr)
exec (@ExecSqlStr)

IF @@rowcount > 0
SET @NotInDB1 = 1
TRUNCATE TABLE ##CompareStr
IF @NotInDB1 = 1
OR @NotInDB2 = 1
BEGIN
        PRINT CHAR(10)+''Data are different''
        IF @NotInDB2             = 1
        AND '+STR(@NumbToShow)+' > 0
        BEGIN
                PRINT ''The row(s) exist IN '+@db1+', but DO NOT exist IN '+@db2+': ''
                SET @SelectStr            = ''
                SELECT top ''+STR('+STR(@NumbToShow)+')+'' *
                FROM   ##NotInDB2''
                EXEC (@SelectStr)
        END
        IF @NotInDB1             = 1
        AND '+STR(@NumbToShow)+' > 0
        BEGIN
                PRINT ''The row(s) exist IN '+@db2+', but DO NOT exist IN '+@db1+': ''
                SET @SelectStr            = ''
                SELECT top ''+STR('+STR(@NumbToShow)+')+'' *
                FROM   ##NotInDB1''
                EXEC (@SelectStr)
        END EXEC
(''
INSERT
INTO   #DiffTables VALUES
       (
              ''''[''+@Tab+'']''''
       )
       '')
END
ELSE
BEGIN
        PRINT CHAR(10)+''Data are identical''
        EXEC (''
        INSERT
        INTO   #IdenticalTables VALUES
               (
                      ''''[''+@Tab+'']''''
               )
               '')
END
END
IF EXISTS
(
       SELECT *
       FROM   tempdb.dbo.sysobjects
       WHERE  name LIKE ''##NotInDB1%''
)
DROP TABLE ##NotInDB1
IF EXISTS
(
       SELECT *
       FROM   tempdb.dbo.sysobjects
       WHERE  name LIKE ''##NotInDB2%''
)
DROP TABLE ##NotInDB2 NextTab:
FETCH NEXT
FROM  TabCur
INTO  @Tab   ,
      @d1User,
      @d2User
END
DEALLOCATE TabCur 
'
EXEC (@SqlStrGetListOfKeys1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        +@SqlStrGetListOfKeys2+@SqlStrGetListOfColumns+ @SqlStrCompareUKeyTables+@SqlStrCompareNonUKeyTables)
PRINT ' '
SET NOCOUNT OFF
IF
   (
   SELECT COUNT(*)
   FROM   #NoPKTables
   )
> 0
BEGIN
        SELECT name AS 'Table(s) without Unique key:'
        FROM   #NoPKTables
END
IF
   (
   SELECT COUNT(*)
   FROM   #DiffTables
   )
> 0
BEGIN
        SELECT name AS 'Table(s) with the same name & structure, but different data:'
        FROM   #DiffTables
END
ELSE
PRINT CHAR(10)+'No tables with the same name & structure, but different data'+CHAR(10)
IF
   (
   SELECT COUNT(*)
   FROM   #IdenticalTables
   )
> 0
BEGIN
        SELECT name AS 'Table(s) with the same name & structure and identical data:'
        FROM   #IdenticalTables
END
IF
   (
   SELECT COUNT(*)
   FROM   #EmptyTables
   )
> 0
BEGIN
        SELECT name AS 'Table(s) with the same name & structure and empty in the both databases:'
        FROM   #EmptyTables
END
DROP TABLE #TabToCheck
DROP TABLE ##CompareStr
DROP TABLE #DiffTables
DROP TABLE #IdenticalTables
DROP TABLE #EmptyTables
DROP TABLE #NoPKTables
DROP TABLE #IndList1
DROP TABLE #IndList2
RETURN

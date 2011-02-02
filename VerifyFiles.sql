-----------------------------------------------------------------------------------
-- create work table
-- cannot be a table variable due to the inner looping
CREATE TABLE #files
  ( PATH VARCHAR(256) )

  
USE [dbamaint]
GO

/****** Object:  Table [dbo].[DirPaths]    Script Date: 01/19/2009 15:51:30 ******/
SET ansi_nulls ON
GO

SET quoted_identifier ON
GO

SET ansi_padding ON
GO

CREATE TABLE [dbo].[DirPaths]
  (
     [PathID] [INT] IDENTITY(1, 1) NOT NULL,
     [Path]   [VARCHAR](256) NOT NULL,
     CONSTRAINT [PK_DirPaths] PRIMARY KEY CLUSTERED ( [PathID] ASC )
  )
ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Files]    Script Date: 01/19/2009 15:51:51 ******/
CREATE TABLE [dbo].[Files]
  (
     [PathID]   [INT] NOT NULL,
     [FilePath] [VARCHAR](256) NOT NULL
  )
ON [PRIMARY]
GO

SET ansi_padding OFF
GO

ALTER TABLE [dbo].[Files] WITH CHECK ADD CONSTRAINT [FK_Files_DirPaths] FOREIGN
KEY([PathID]) REFERENCES [dbo].[DirPaths] ([PathID])
GO

ALTER TABLE [dbo].[Files] CHECK CONSTRAINT [FK_Files_DirPaths]

-----------------------------------------------------------------------------------
DECLARE @DirRoots VARCHAR(64)
DECLARE @DirRoot VARCHAR(32)
DECLARE @Drive VARCHAR(1)
DECLARE @SubDirs VARCHAR(64)
DECLARE @SubDir VARCHAR(32)
DECLARE @DirPath VARCHAR(128)
DECLARE @File VARCHAR(128)
DECLARE @PathID INT
DECLARE @result INT

DECLARE @drives TABLE
  ( drive CHAR(1),
    free  VARCHAR(16)
  )

DECLARE @DBFiles TABLE 
	( ServerName varchar(24)
	, DatabaseName varchar(32)
	, LogicalName varchar(32)
	, FileName varchar(128)
	, LastUpdate datetime
	);

-- populate table with existing databases information
INSERT INTO @DBFiles
EXEC sp_MSForEachDB 
	'SELECT CONVERT(nvarchar(32), SERVERPROPERTY(''Servername'')) AS Server,
		''?'' as DatabaseName,
		[?]..sysfiles.name AS LogicalName, 
		[?]..sysfiles.filename AS FileName,
		GETDATE()
			From [?]..sysfiles'
  
SELECT @DirRoots = ':\mssql' + ',' + ':\mssql.1\mssql' + ',' + ':\MSSQL10.MSSQLSERVER\MSSQL'
SELECT @SubDirs = '\BAK\' + ',' + '\Data\' + ',' + '\LDF\' + ',' + '\'

INSERT INTO @drives
            (drive,
             free)
EXEC MASTER..Xp_fixeddrives

DECLARE drive CURSOR FOR
  SELECT drive
  FROM   @drives
WHERE Drive != 'C'

-- outer loop for each drive letter
OPEN drive

FETCH NEXT FROM drive INTO @Drive

WHILE @@FETCH_STATUS = 0
  BEGIN
      -- work goes here
      DECLARE dirroot CURSOR FOR
        SELECT *
        FROM   [dbamaint].[dbo].[Udf_split](@DirRoots, ',')

      -- 2nd loop for each directory root
      OPEN dirroot

      FETCH NEXT FROM dirroot INTO @DirRoot

      WHILE @@FETCH_STATUS = 0
        BEGIN
            -- work goes here
            DECLARE subdir CURSOR FOR
              SELECT *
              FROM   [dbamaint].[dbo].[Udf_split](@SubDirs, ',')

            -- 3rd loop for each each sub-directory defined
            OPEN subdir

            FETCH NEXT FROM subdir INTO @SubDir

            WHILE @@FETCH_STATUS = 0
              BEGIN
                  -- work goes here
                  PRINT '3rd loop ' + @Drive + @DirRoot + @SubDir
                  SELECT @DirPath = 'dir /B ' + @Drive + @DirRoot + @SubDir
                  --PRINT 'Dirpath exec: ' + @DirPath
                  EXEC @result = MASTER.dbo.Xp_cmdshell @DirPath, NO_OUTPUT

                  IF ( @result = 0 )
                    BEGIN
                        -- re-assign @DirPath
                        SELECT @DirPath = @Drive + @DirRoot + @SubDir

                        INSERT INTO dbamaint.dbo.dirpaths
                                    (PATH)
						VALUES      ( @DirPath )

                        -- directory exists, get the contents
                        SET @PathID = (SELECT pathid
                                       FROM   dbamaint.dbo.dirpaths
                                       WHERE  PATH = @DirPath)

                        PRINT 'Starting file loop for: ' + @DirPath
                        EXEC dbamaint.dbo.Dbm_listfiles @DirPath, '#Files', NULL, NULL, 0

                        -- files loop
                        DECLARE files CURSOR FOR
                          SELECT *
                          FROM   #Files

                        OPEN files

                        FETCH NEXT FROM files INTO @File

                        WHILE @@FETCH_STATUS = 0
                          BEGIN
                              IF @File != ''
                                INSERT INTO dbamaint.dbo.files
                                            (pathid,
                                             filepath)
                                VALUES      (@PathID,
                                             @DirPath + @File)
                              FETCH NEXT FROM files INTO @File
                          END

                        CLOSE files
                        DEALLOCATE files
                        
                        TRUNCATE TABLE #Files
                    END
                  ELSE
                    BEGIN
                        PRINT 'Directory path ' + @DirPath + ' does not exist.' + CHAR(10)
                    END

                  FETCH NEXT FROM subdir INTO @SubDir
              END -- 3rd loop close

            CLOSE subdir
            DEALLOCATE subdir

            FETCH NEXT FROM dirroot INTO @DirRoot
        END -- 2nd loop close
      CLOSE dirroot
      DEALLOCATE dirroot

      FETCH NEXT FROM drive INTO @Drive
  END -- outer loop close
CLOSE drive
DEALLOCATE drive

  
SELECT * FROM   dirpaths
SELECT * FROM   files

--SELECT FilePath
--	FROM DirPaths dp
--	JOIN files f ON dp.PathID = f.PathID
--WHERE FilePath NOT LIKE '%cer' -- ignore certificates
--ORDER BY 1


SELECT @@SERVERNAME AS Servername, DatabaseName, FilePath
	FROM @DBFiles dbf
	FULL JOIN files f ON dbf.FileName = f.FilePath
WHERE FilePath NOT LIKE '%cer' -- ignore certificates
--AND FilePath NOT LIKE '%.bak' -- ignore backup files
ORDER BY 1,2,3



-- cleanup
-----------------------------------------------------------------------------------
DROP TABLE #files
DROP TABLE files
DROP TABLE dirpaths

DECLARE @DTSPKG CURSOR
DECLARE @name varchar (50)
DECLARE @id varchar (100)
DECLARE @DTS varchar (30)
DECLARE @Statement nvarchar(300)
DECLARE @Owner varchar (30)

DECLARE DTSPKG CURSOR FOR
SELECT DISTINCT [name],[id],[owner] FROM msdb..sysdtspackages

OPEN DTSPKG

FETCH NEXT FROM DTSPKG
INTO @name, @id, @owner
	WHILE @@FETCH_STATUS = 0

	BEGIN
	--To allow for the easy rollback, use the statements generated
	PRINT N'EXEC sp_reassign_dtspackageowner ' + char(39) + @name + char(39) + ', ' + char(39) + @id+ char(39) + ', ' + char(39) + @owner + char(39)
		SET @Statement = 'EXEC msdb..sp_reassign_dtspackageowner ' + char(39) + @name + char(39) + ', ' + char(39) + @id+ char(39) + ', ' + 'sa'
		EXEC sp_executesql @Statement
			FETCH NEXT FROM DTSPKG
  			INTO @name, @id, @owner
	END

CLOSE DTSPKG
DEALLOCATE DTSPKG
GO
USE Status
GO

DECLARE @TableID INT
, @TableName VARCHAR(255)
, @SQL VARCHAR(MAX)

DECLARE Tables_cur CURSOR FOR
SELECT tableID, TableName
FROM TablesToDrop
ORDER BY TableName

OPEN Tables_cur
FETCH NEXT FROM Tables_cur INTO @TableID, @TableName

WHILE @@FETCH_STATUS = 0
BEGIN

SELECT @SQL = 'EXEC sp_MSForEachDB ''' + CHAR(10) +
'USE ?
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''''[dbo].[' + @TableName + ']'''') AND type in (N''''U''''))
BEGIN
PRINT ''''Found ' + @TableName + ' in the '''' + DB_NAME() + '''' DB''''
DROP TABLE [dbo].[' + @TableName + ']
END''' + CHAR(10)


PRINT(@SQL)

FETCH NEXT FROM Tables_cur INTO @TableID, @TableName
END

CLOSE Tables_cur
DEALLOCATE Tables_cur


USE MASTER
GO

BEGIN
    DECLARE @databasename VARCHAR(30)
    DECLARE cur CURSOR FOR
      SELECT name
      FROM   sysdatabases

    CREATE TABLE #result
      (
         dbname VARCHAR(120),
         result VARCHAR(300)
      )

    OPEN cur

    FETCH NEXT FROM cur INTO @databasename

    WHILE( @@FETCH_STATUS = 0 )
      BEGIN
          CREATE TABLE #t
            (
               Owner		VARCHAR(120),
               Object		VARCHAR(120),
               Grantee		VARCHAR(120),
               Grantor		VARCHAR(120),
               ProtectType	VARCHAR(120),
               Action		VARCHAR(120),
               AColumn		VARCHAR(120)
            )

          INSERT INTO #t
          EXEC Sp_helprotect @username = NULL

          INSERT INTO #result
          SELECT @databasename,
                 ProtectType + ' ' + Action + ' on [' + Owner + '].[' + Object + ']' + CASE
                 WHEN (
                 Patindex('%All%', AColumn) = 0 )
                 AND
                 ( AColumn <> '.' )
                 THEN
                 ' (' + AColumn + ')' ELSE ''
                 END + ' to [' + Grantee + ']'
          FROM   #t
          WHERE Grantee != 'public'

          DROP TABLE #t

          FETCH NEXT FROM cur INTO @databasename
      END

    SELECT *
    FROM   #result
    ORDER BY 1

    CLOSE cur
    DEALLOCATE cur

    DROP TABLE #result
END
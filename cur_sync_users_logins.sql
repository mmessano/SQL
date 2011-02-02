/*
Synch database names to the master..syslogin id's
Name_cursor to select users
variables needed:
	username
	statement to execute
*/
SET NOCOUNT ON
GO
--USE DATABASENAME -- Change Database Name here!
--GO

DECLARE	@username varchar(30),
		@stmnt varchar(100)

DECLARE Name_cursor CURSOR FOR
  SELECT DISTINCT su.name
  FROM sysusers su JOIN master.dbo.syslogins msl ON
  su.name = msl.name
  WHERE su.sid != msl.sid
  OR su.sid IS NULL
  ORDER BY  su.name

OPEN Name_cursor
FETCH NEXT FROM Name_cursor INTO @username

WHILE @@FETCH_STATUS = 0
BEGIN
	ELECT @stmnt = 'EXEC sp_change_users_login "Update_One", "'
	SELECT @stmnt = @stmnt + @username + '", "' + @username + '"'
	PRINT @stmnt
--	EXEC (@stmnt)
    FETCH NEXT FROM Name_cursor INTO @username
    END
CLOSE Name_cursor
DEALLOCATE Name_cursor

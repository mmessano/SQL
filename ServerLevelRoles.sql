/**************************************************
Script Server Roles

Author:        Rasmus Glibstrup
Company:    it-Craft Denmark
Date:        25-08-2010
Version:    1.0

Script to generate all Server Roles for SQL Server
in the case of migrating logins to other SQL Server

May very well be used together with sp_help_revlogin 

Output is in text and can be cut'n'pasted to the 
new server.
***************************************************/
SET NOCOUNT ON
DECLARE @SQLCmd nvarchar(1000)
DECLARE @RoleName sysname
DECLARE @Login sysname
DECLARE @Count int

Create table #ServerRoles (
ServerRole sysname,
MemberName sysname,
MemberSID varbinary(85))

INSERT INTO #ServerRoles
exec sp_helpsrvrolemember 

DECLARE ServerRoleCursor Cursor 
FOR SELECT ServerRole,MemberName 
FROM #ServerRoles 
WHERE MemberName not like 'NT SERVICE%' AND 
MemberName <> 'sa' AND
MemberName not like 'NT AUTHORITY%'

OPEN ServerRoleCursor

FETCH NEXT FROM ServerRoleCursor
INTO @RoleName, @Login


SET @Count = 0

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQLCmd = 'exec sp_addsrvrolemember ''' + @Login + ''' , ''' + @RoleName + ''''
    PRINT @SQLCmd

    SET @Count = @Count + 1 

    FETCH NEXT FROM ServerRoleCursor
    INTO @RoleName, @Login
END

IF @Count=0
Print 'No logins with serverroles, besides SA'
ELSE
Print CAST(@Count as varchar(5)) + ' Roles scripted'

CLOSE ServerRoleCursor
DEALLOCATE ServerRoleCursor

DROP TABLE #ServerRoles




/****************************************
Script Made by Lester A. Policarpio
For questions and clarifications feel free to email me at
lpolicarpio2005@yahooo.com
*/
SET nocount ON

PRINT '--##############################################################'
PRINT '--Generate Script for Server Log-ins'
PRINT '--Supply  with your Server log-in password'
PRINT '--##############################################################'
PRINT ''

IF EXISTS (SELECT name,
                  dbname
           FROM   MASTER..syslogins
           WHERE  name <> 'sa')
  BEGIN
      DECLARE @name VARCHAR(200)
      DECLARE @default VARCHAR(200)

      PRINT 'DECLARE @login varchar(1024)'
      PRINT 'DECLARE @q varchar(1024)'
      PRINT ''
      PRINT 'CREATE TABLE login'
      PRINT '('
      PRINT 'names varchar(124),'
      PRINT 'pass varchar(124),'
      PRINT 'db varchar(124),'
      PRINT ')'

      --GENERATE SERVER LOG-IN
      DECLARE cursor_master CURSOR FOR
        SELECT name,
               dbname
        FROM   MASTER..syslogins
        WHERE  name <> 'sa'

      OPEN cursor_master

      FETCH NEXT FROM cursor_master INTO @name, @default

      WHILE ( @@FETCH_STATUS = 0 )
        BEGIN
            PRINT 'INSERT INTO login VALUES (' + '''' + @name + '''' + ',' +
                  ''''''
                  + ',' + '''' + @default + '''' + ')'

            FETCH NEXT FROM cursor_master INTO @name, @default
        END

      CLOSE cursor_master

      DEALLOCATE cursor_master

      PRINT 'DECLARE logins CURSOR FOR'
      PRINT 'select ' + '''''''''' + '+names+' + '''''''''' + '+'',''' + '+' +
            '''''''''' +
                  '+pass+' + '''''''''' + '+'',''' + '+' + '''''''''' + '+db+' +
            ''''''''''
            + ' AS ' + '''LOG''' + ' FROM login'
      PRINT 'OPEN logins'
      PRINT 'FETCH NEXT FROM logins INTO @login'
      PRINT 'WHILE (@@FETCH_STATUS = 0)'
      PRINT 'BEGIN'
      PRINT 'SET @q = ''sp_addlogin ''+@login'
      PRINT 'EXEC (@q)'
      PRINT 'FETCH NEXT FROM logins INTO @login'
      PRINT 'END'
      PRINT 'CLOSE logins'
      PRINT 'DEALLOCATE logins'
      PRINT 'DROP TABLE login'
  END

PRINT '--#################################################################'
PRINT '--Generate Script for Server Roles'
PRINT '--#################################################################'
PRINT ''

IF EXISTS (SELECT name,
                  dbname,
                  sysadmin,
                  securityadmin,
                  serveradmin,
                  setupadmin,
                  processadmin,
                  diskadmin,
                  dbcreator,
                  bulkadmin
           FROM   MASTER..syslogins
           WHERE  name <> 'sa')
  BEGIN
      DECLARE @logins VARCHAR(200)
      DECLARE @Default1 VARCHAR(200)
      DECLARE @sysadmin INT
      DECLARE @securityadmin INT
      DECLARE @serveradmin INT
      DECLARE @setupadmin INT
      DECLARE @processadmin INT
      DECLARE @diskadmin INT
      DECLARE @dbcreator INT
      DECLARE @bulkadmin INT
      DECLARE @master INT

      PRINT 'DECLARE @login2 varchar(1024)'
      PRINT 'DECLARE @w varchar(1024)'
      PRINT ''
      PRINT 'CREATE TABLE login2'
      PRINT '('
      PRINT 'names varchar(1024),'
      PRINT 'role varchar(3000)'
      PRINT ')'
      PRINT ''
      PRINT ''

      DECLARE cursor_master2 CURSOR FOR
        SELECT name,
               dbname,
               sysadmin,
               securityadmin,
               serveradmin,
               setupadmin,
               processadmin,
               diskadmin,
               dbcreator,
               bulkadmin
        FROM   MASTER..syslogins
        WHERE  name <> 'sa'

      OPEN cursor_master2

      FETCH NEXT FROM cursor_master2 INTO @logins, @default1, @sysadmin,
      @securityadmin, @serveradmin, @setupadmin, @processadmin, @diskadmin,
      @dbcreator, @bulkadmin

      WHILE ( @@FETCH_STATUS = 0 )
        BEGIN
            --@@@@@@ sysadmin
            IF ( @sysadmin = 1 )
              BEGIN
                  PRINT 'INSERT INTO login2 VALUES (' + '''' + @logins + '''' +
                        ',' +
                        '''sysadmin''' +
                        ')'

                  PRINT ''
              END

            --@@@@@ securityadmin
            IF ( @securityadmin = 1 )
              BEGIN
                  PRINT 'INSERT INTO login2 VALUES (' + '''' + @logins + '''' +
                        ',' +
                              '''securityadmin''' + ')'

                  PRINT ''
              END

            --@@@@@ serveradmin
            IF ( @serveradmin = 1 )
              BEGIN
                  PRINT 'INSERT INTO login2 VALUES (' + '''' + @logins + '''' +
                        ',' +
                        '''serveradmin'''
                        + ')'

                  PRINT ''
              END

            --@@@@@ setupadmin
            IF ( @setupadmin = 1 )
              BEGIN
                  PRINT 'INSERT INTO login2 VALUES (' + '''' + @logins + '''' +
                        ',' +
                        '''setupadmin''' +
                        ')'

                  PRINT ''
              END

            --@@@@@ processadmin
            IF ( @processadmin = 1 )
              BEGIN
                  PRINT 'INSERT INTO login2 VALUES (' + '''' + @logins + '''' +
                        ',' +
                        '''processadmin'''
                        + ')'

                  PRINT ''
              END

            --@@@@@ diskadmin
            IF ( @diskadmin = 1 )
              BEGIN
                  PRINT 'INSERT INTO login2 VALUES (' + '''' + @logins + '''' +
                        ',' +
                        '''diskadmin''' +
                        ')'

                  PRINT ''
              END

            --@@@@@ dbcreator
            IF ( @dbcreator = 1 )
              BEGIN
                  PRINT 'INSERT INTO login2 VALUES (' + '''' + @logins + '''' +
                        ',' +
                        '''dbcreator''' +
                        ')'

                  PRINT ''
              END

            --@@@@@ bulkadmin
            IF ( @bulkadmin = 1 )
              BEGIN
                  PRINT 'INSERT INTO login2 VALUES (' + '''' + @logins + '''' +
                        ',' +
                        '''bulkadmin''' +
                        ')'

                  PRINT ''
              END

            FETCH NEXT FROM cursor_master2 INTO @logins, @default1, @sysadmin,
            @securityadmin, @serveradmin, @setupadmin, @processadmin, @diskadmin
            ,
            @dbcreator, @bulkadmin
        END

      CLOSE cursor_master2

      DEALLOCATE cursor_master2

      PRINT 'DECLARE logins CURSOR FOR'
      PRINT 'select names + ' + ''',''' + '+ role FROM login2'
      PRINT 'OPEN logins'
      PRINT 'FETCH NEXT FROM logins INTO @login2'
      PRINT 'WHILE (@@FETCH_STATUS = 0)'
      PRINT 'BEGIN'
      PRINT 'SET @w = ''sp_addsrvrolemember ''+@login2'
      PRINT 'EXEC (@w)'
      PRINT 'FETCH NEXT FROM logins INTO @login2'
      PRINT 'END'
      PRINT 'CLOSE logins'
      PRINT 'DEALLOCATE logins'
      PRINT 'DROP TABLE login2'
  END

PRINT '--#################################################################'

PRINT '--Generate Script for Database Users/ROles'

PRINT '--#################################################################'

PRINT ''

/****************************************
Script Made by Lester A. Policarpio
For questions and clarifications feel free to email me at
lpolicarpio2005@yahooo.com
*/
DECLARE @dbcomp VARCHAR(1024)
DECLARE @pass VARCHAR(5000)
DECLARE @counter VARCHAR(500)
DECLARE @dbid VARCHAR(100)

CREATE TABLE dbroles
  (
     dbname            SYSNAME NOT NULL,
     username          SYSNAME NOT NULL,
     db_owner          VARCHAR(3) NOT NULL,
     db_accessadmin    VARCHAR(3) NOT NULL,
     db_securityadmin  VARCHAR(3) NOT NULL,
     db_ddladmin       VARCHAR(3) NOT NULL,
     db_datareader     VARCHAR(3) NOT NULL,
     db_datawriter     VARCHAR(3) NOT NULL,
     db_denydatareader VARCHAR(3) NOT NULL,
     db_denydatawriter VARCHAR(3) NOT NULL,
     db_backupoperator VARCHAR(3) NOT NULL
  )

DECLARE @dbname VARCHAR(200)
DECLARE @mSql1 VARCHAR(8000)
DECLARE dbname_cursor CURSOR FOR
  SELECT name
  FROM   MASTER.dbo.sysdatabases
  WHERE  name NOT IN ( 'master', 'tempdb', 'model', 'pubs',
                       'northwind', 'msdb' )
  ORDER  BY name

OPEN dbname_cursor

FETCH NEXT FROM dbname_cursor INTO @dbname

WHILE @@FETCH_STATUS = 0
  BEGIN
      SET @mSQL1 = '    Insert into DBROLES ( DBName, UserName, db_owner, db_accessadmin,   db_securityadmin, db_ddladmin, db_datareader, db_datawriter,      db_denydatareader, db_denydatawriter,db_backupoperator )     SELECT ' + '''' + @dbName + '''' +
                   ' as DBName ,UserName, '
                   + CHAR(13) +
                                '      Max(CASE RoleName WHEN ''db_owner''      THEN ''Yes'' ELSE ''No'' END) AS db_owner,      Max(CASE RoleName WHEN ''db_accessadmin '' THEN ''Yes'' ELSE ''No'' END) AS db_accessadmin ,      Max(CASE RoleName WHEN ''db_securityadmin'' THEN ''Yes'' ELSE ''No'' END) AS db_securityadmin,      Max(CASE RoleName WHEN ''db_ddladmin''      THEN ''Yes'' ELSE ''No'' END) AS db_ddladmin,      Max(CASE RoleName WHEN ''db_datareader''      THEN ''Yes'' ELSE ''No'' END) AS db_datareader,      Max(CASE RoleName WHEN ''db_datawriter''      THEN ''Yes'' ELSE ''No'' END) AS db_datawriter,  Max(CASE RoleName WHEN ''db_denydatareader'' THEN ''Yes'' ELSE ''No'' END) AS db_denydatareader,      Max(CASE RoleName WHEN ''db_denydatawriter'' THEN ''Yes'' ELSE ''No'' END) AS db_denydatawriter,     Max(CASE RoleName WHEN ''db_backupoperator'' THEN ''Yes'' ELSE ''No'' END) AS db_backupoperator     from (  select b.name as USERName, c.name as RoleName       from ' + @dbName + '.dbo.sysmembers a ' +
                   CHAR(13
                   ) +
                                '    join ' + @dbName + '.dbo.sysusers b ' +
                   CHAR(
                   13)
                   +
                                '    on a.memberuid = b.uid     join ' + @dbName
                   +
                   '.dbo.sysusers c      on a.groupuid = c.uid )s               Group by USERName   order by UserName'

      --Print @mSql1
      EXECUTE (@mSql1)

      FETCH NEXT FROM dbname_cursor INTO @dbname
  END

CLOSE dbname_cursor

DEALLOCATE dbname_cursor

DECLARE @db VARCHAR(1024)
DECLARE @name1 VARCHAR(200)
DECLARE @name2 INT
DECLARE @hasdbaccess VARCHAR(200)
DECLARE @islogin VARCHAR(200)
DECLARE @isntname VARCHAR(200)
DECLARE @isntgroup VARCHAR(200)
DECLARE @isntuser VARCHAR(200)
DECLARE @issqluser VARCHAR(200)
DECLARE @isaliased VARCHAR(200)
DECLARE @issqlrole VARCHAR(200)
DECLARE @isapprole VARCHAR(200)

SET @name2 = 1

DECLARE cur CURSOR FOR
  SELECT dbname,
         username,
         db_owner,
         db_accessadmin,
         db_securityadmin,
         db_ddladmin,
         db_datareader,
         db_datawriter,
         db_denydatareader,
         db_denydatawriter,
         db_backupoperator
  FROM   dbroles
  WHERE  username <> 'DBO'

OPEN cur

FETCH NEXT FROM cur INTO @counter, @name1, @hasdbaccess, @islogin, @isntname,
@isntgroup, @isntuser, @issqluser, @isaliased, @issqlrole, @isapprole

WHILE ( @@FETCH_STATUS = 0 )
  BEGIN
      PRINT '--@@@@@' + @name1 + CONVERT(VARCHAR(5), @name2) + '@@@@@--'

      PRINT 'DECLARE @' + @name1 + CONVERT(VARCHAR(5), @name2) +
            ' varchar(1024)'

      PRINT 'DECLARE @' + @name1 + CONVERT(VARCHAR(5), @name2) +
            '2 varchar(1024)'

      PRINT 'DECLARE @' + @name1 + CONVERT(VARCHAR(5), @name2) +
            '3 varchar(1024)'

      PRINT 'DECLARE ' + @name1 + CONVERT(VARCHAR(5), @name2) + ' CURSOR for'

      PRINT 'select name from master..sysdatabases where name IN (' + '''' +
            @counter + ''''
            + ')'

      PRINT 'OPEN ' + @name1 + CONVERT(VARCHAR(5), @name2)

      PRINT 'FETCH NEXT FROM ' + @name1 + CONVERT(VARCHAR(5), @name2) +
            ' INTO @'
            + @name1 +
            CONVERT(VARCHAR(5), @name2)

      PRINT 'WHILE (@@FETCH_STATUS = 0)'

      PRINT 'BEGIN'

      PRINT 'SET @' + @name1 + CONVERT(VARCHAR(5), @name2) + '2 = @' + @name1 +
            CONVERT(
                  VARCHAR(5), @name2) + '+' + '''' + '..sp_grantdbaccess ' +
            ''''
            +
            '+' +
                  '''' + @name1 + ''''

      PRINT 'EXEC (@' + @name1 + CONVERT(VARCHAR(5), @name2) + '2)'

      -- @hasdbaccess
      IF ( @hasdbaccess = 'YES' )
        BEGIN
            PRINT 'SET @' + @name1 + CONVERT(VARCHAR(5), @name2) + '3 = @' +
                  @name1 +
                  CONVERT(
                        VARCHAR(5), @name2) + '+' + '''' + '..sp_addrolemember '
                  +
                  ''''
                  +
                  '+' +
                        '''' + 'db_owner' + ',' + @name1 + ''''

            PRINT 'EXEC (@' + @name1 + CONVERT(VARCHAR(5), @name2) + '3)'
        END

      -- @islogin
      IF ( @islogin = 'YES' )
        BEGIN
            PRINT 'SET @' + @name1 + CONVERT(VARCHAR(5), @name2) + '3 = @' +
                  @name1 +
                  CONVERT(
                        VARCHAR(5), @name2) + '+' + '''' + '..sp_addrolemember '
                  +
                  ''''
                  +
                  '+' +
                        '''' + 'db_accessadmin' + ',' + @name1 + ''''

            PRINT 'EXEC (@' + @name1 + CONVERT(VARCHAR(5), @name2) + '3)'
        END

      -- @isntname
      IF ( @isntname = 'YES' )
        BEGIN
            PRINT 'SET @' + @name1 + CONVERT(VARCHAR(5), @name2) + '3 = @' +
                  @name1 +
                  CONVERT(
                        VARCHAR(5), @name2) + '+' + '''' + '..sp_addrolemember '
                  +
                  ''''
                  +
                  '+' +
                        '''' + 'db_securityadmin' + ',' + @name1 + ''''

            PRINT 'EXEC (@' + @name1 + CONVERT(VARCHAR(5), @name2) + '3)'
        END

      -- @isntgroup
      IF ( @isntgroup = 'YES' )
        BEGIN
            PRINT 'SET @' + @name1 + CONVERT(VARCHAR(5), @name2) + '3 = @' +
                  @name1 +
                  CONVERT(
                        VARCHAR(5), @name2) + '+' + '''' + '..sp_addrolemember '
                  +
                  ''''
                  +
                  '+' +
                        '''' + 'db_ddladmin' + ',' + @name1 + ''''

            PRINT 'EXEC (@' + @name1 + CONVERT(VARCHAR(5), @name2) + '3)'
        END

      -- @isntuser
      IF ( @isntuser = 'YES' )
        BEGIN
            PRINT 'SET @' + @name1 + CONVERT(VARCHAR(5), @name2) + '3 = @' +
                  @name1 +
                  CONVERT(
                        VARCHAR(5), @name2) + '+' + '''' + '..sp_addrolemember '
                  +
                  ''''
                  +
                  '+' +
                        '''' + 'db_datareader' + ',' + @name1 + ''''

            PRINT 'EXEC (@' + @name1 + CONVERT(VARCHAR(5), @name2) + '3)'
        END

      -- @issqluser
      IF ( @issqluser = 'YES' )
        BEGIN
            PRINT 'SET @' + @name1 + CONVERT(VARCHAR(5), @name2) + '3 = @' +
                  @name1 +
                  CONVERT(
                        VARCHAR(5), @name2) + '+' + '''' + '..sp_addrolemember '
                  +
                  ''''
                  +
                  '+' +
                        '''' + 'db_datawriter' + ',' + @name1 + ''''

            PRINT 'EXEC (@' + @name1 + CONVERT(VARCHAR(5), @name2) + '3)'
        END

      -- @isaliased
      IF ( @isaliased = 'YES' )
        BEGIN
            PRINT 'SET @' + @name1 + CONVERT(VARCHAR(5), @name2) + '3 = @' +
                  @name1 +
                  CONVERT(
                        VARCHAR(5), @name2) + '+' + '''' + '..sp_addrolemember '
                  +
                  ''''
                  +
                  '+' +
                        '''' + 'db_denydatareader' + ',' + @name1 + ''''

            PRINT 'EXEC (@' + @name1 + CONVERT(VARCHAR(5), @name2) + '3)'
        END

      -- @issqlrole
      IF ( @issqlrole = 'YES' )
        BEGIN
            PRINT 'SET @' + @name1 + CONVERT(VARCHAR(5), @name2) + '3 = @' +
                  @name1 +
                  CONVERT(
                        VARCHAR(5), @name2) + '+' + '''' + '..sp_addrolemember '
                  +
                  ''''
                  +
                  '+' +
                        '''' + 'db_denydatawriter' + ',' + @name1 + ''''

            PRINT 'EXEC (@' + @name1 + CONVERT(VARCHAR(5), @name2) + '3)'
        END

      -- @isqpprole
      IF ( @isapprole = 'YES' )
        BEGIN
            PRINT 'SET @' + @name1 + CONVERT(VARCHAR(5), @name2) + '3 = @' +
                  @name1 +
                  CONVERT(
                        VARCHAR(5), @name2) + '+' + '''' + '..sp_addrolemember '
                  +
                  ''''
                  +
                  '+' +
                        '''' + 'db_backupoperator' + ',' + @name1 + ''''

            PRINT 'EXEC (@' + @name1 + CONVERT(VARCHAR(5), @name2) + '3)'
        END

      PRINT 'FETCH NEXT FROM ' + @name1 + CONVERT(VARCHAR(5), @name2) +
            ' INTO @'
            + @name1 +
            CONVERT(VARCHAR(5), @name2)

      PRINT 'END'

      PRINT 'CLOSE ' + @name1 + CONVERT(VARCHAR(5), @name2)

      PRINT 'DEALLOCATE ' + @name1 + CONVERT(VARCHAR(5), @name2)

      SET @name2 = @name2 + 1

      FETCH NEXT FROM cur INTO @counter, @name1, @hasdbaccess, @islogin,
      @isntname
      , @isntgroup, @isntuser, @issqluser, @isaliased, @issqlrole, @isapprole
  END

CLOSE cur

DEALLOCATE cur

DROP TABLE dbroles
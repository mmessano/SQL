-------------------------------------------------------------------------------------
--Name        : Get all user information at the database level
--Description : Captures database user info. 
--            : Works in ISQL/W, ISQL, OSQL & Query Analyzer
--Date        : 07/29/2001
--Origional
--Author      : Clint Herring
--Modified by : Wes Brown
--
--History     : 04/09/2002 WCH Joined to syslogins to get the users 
--                  login name for sp_grantdbaccess. Fixed some typos.
--	          : 05/18/2004 Added loop for all databases also added file output with
--					master restore script that uses osql to restore the permissions
-------------------------------------------------------------------------------------


Set NOCOUNT On

DECLARE @dbname varchar(60)
DECLARE @path varchar(255)
DECLARE @server_name varchar(255)
DECLARE @user varchar(255)
DECLARE @Status int
DECLARE @bcp varchar(8000)


set @server_name = cast(serverproperty('servername') as varchar(255))
--server name won't work on MSDE version of sql replace with @@SERVERNAME
--set @path = '\\messano338\inbox\SQLPerms\ select @user = loginame from master.dbo.sysprocesses where spid = @@SPID'
-- local to the remote server
set @path = 'E:\dexma\logs\'
--path to save to UNC works just fine must have trailing select @user = loginame from master.dbo.sysprocesses where spid = @@SPID
--pulls the login name of the current user to fill out some of the self documentation

create table ##osql_holding
(
	sid int IDENTITY(1,1),
	text varchar(255)
)
insert into ##osql_holding (text)
values('declare @cmd varchar(8000)')


DECLARE dbperm CURSOR
READ_ONLY
FOR select name from master.dbo.sysdatabases


OPEN dbperm

FETCH NEXT FROM dbperm INTO @dbname
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
		create table ##cmdhold
		(
		cmdid int IDENTITY(1,1),
		text varchar(8000)
		)
		insert into ##cmdhold (text)
		values('-- Server: ' + @@servername)
		insert into ##cmdhold (text)
		values('-- Database: ' + @dbname)
		insert into ##cmdhold (text)
		values('-- Date captured: ' + convert(varchar(26), GetDate(),113))
		
		--Getting database user info
		insert into ##cmdhold (text)
		values('-- Scripts for restoring database user info...')
		insert into ##cmdhold (text)
		values('use ' + @dbname)
		exec( 'If exists(select * ' +
		                  'from ' + @dbname + '.dbo.sysusers ' +
		                 'where sid not in(select sid from master.dbo.syslogins) ' +
		                    'and name <> ''guest'') ' +
		         'Begin ' +
		            'insert into ##cmdhold (text) values(''-- These users have sids that are different than their login sids:'') ' +
		            'insert into ##cmdhold (text) Select ''-- '' + name ' +
		              'from ' + @dbname + '.dbo.sysusers ' +
		             'where sid not in(select sid from master.dbo.syslogins) ' +
		               'and name <> ''guest'' ' +
		         'End')
		insert into ##cmdhold (text)
		values('     -- Scripts for adding roles')
		insert into ##cmdhold (text)
		exec( 'select ''     exec sp_addrole N'''''' + name + ''''''''' + 
		      ' from ' + @dbname + 
		      '.dbo.sysusers where uid > 16393')
		insert into ##cmdhold (text)
		values('     -- Scripts for adding users')
		insert into ##cmdhold (text)
		exec( 'select ''     exec sp_grantdbaccess N'''''' + b.loginname + '''''',N'''''' + a.name + ''''''''' + 
		      ' from ' + @dbname + 
		      '.dbo.sysusers a join master.dbo.syslogins b on a.sid = b.sid where a.uid > 3 and a.uid < 16384')
		insert into ##cmdhold (text)
		values('     -- Scripts for adding role members')
		insert into ##cmdhold (text)
		exec( 'select ''     exec sp_addrolemember N'''''' + b.name + '''''',N'''''' + a.name + ''''''''' + 
		      ' from ' + @dbname + 
		      '.dbo.sysusers a, ' +
		      @dbname + '.dbo.sysusers b, ' +
		      @dbname + '.dbo.sysmembers c ' +
		      'where a.uid = c.memberuid ' +
		      'and a.uid > 3 ' + --and a.uid < 16384 ' +
		      'and b.uid = c.groupuid')
		insert into ##cmdhold (text)
		 values('     -- Scripts for granting user & role permissions')
		insert into ##cmdhold (text)
		Exec ('select case when action = 26  then ''     Grant REFERENCES'' ' +
		                   'when action = 193 then ''     Grant SELECT'' ' +
		                   'when action = 195 then ''     Grant INSERT'' ' +
		                   'when action = 196 then ''     Grant DELETE'' ' +
		                   'when action = 197 then ''     Grant UPDATE'' ' +
		                   'when action = 198 then ''     Grant CREATE TABLE'' ' +
		                   'when action = 203 then ''     Grant CREATE DATABASE'' ' +
		                   'when action = 207 then ''     Grant CREATE VIEW'' ' +
		                   'when action = 222 then ''     Grant CREATE PROCEDURE'' ' +
		                   'when action = 224 then ''     Grant EXECUTE'' ' +
		                   'when action = 228 then ''     Grant DUMP DATABASE'' ' +
		                   'when action = 233 then ''     Grant CREATE DEFAULT'' ' +
		                   'when action = 235 then ''     Grant DUMP TRANSACTION'' ' +
		                   'when action = 236 then ''     Grant CREATE RULE'' ' +
		                   'else '''' ' +
		              'end + ' +
		              ''' on '' + d.name + ''.'' + b.name + '' to '' + c.name + char(13) + char(10) + ''     go'' ' +
		       'from ' + @dbname + '.dbo.sysprotects a,  ' +
		            @dbname + '.dbo.sysobjects b,  ' +
		            @dbname + '.dbo.sysusers c,  ' +
		            @dbname + '.dbo.sysusers d  ' +
		       'where a.id = b.id  ' +
		         'and a.uid = c.uid ' + 
		         'and a.uid >= 0  ' +
		         'and a.protecttype = 205 ' +
		         'and b.uid = d.uid ' + 
		         'and b.xtype <> ''S'' ' + 
		         'and b.status >= 0 ' + 
		       'order by c.name, ' + 
		                'b.name,  ' +
		                'action ')

			SELECT @bcp = 'bcp "SELECT rtrim(text) FROM ' + @dbname + '.dbo.##cmdhold" QUERYOUT "'+@path+'UserPermissions_' + @server_name +'_'+ @dbname+ '.sql" -T -c'
			EXEC @Status = master.dbo.xp_cmdshell @bcp, no_output
	
			IF @Status <> 0
			BEGIN
				PRINT 'An error ocurred while generating the SQL file.'
			END 
			ELSE 
			begin
				set @bcp = 'set @cmd = ''osql -S '+@server_name+' -E -d '+@dbname+' -i "'+@path+'UserPermissions_' + @server_name +'_'+@dbname+  '.sql"'''
				PRINT ''+@path+'UserPermissions_' + @server_name +'_'+@dbname+  '.sql file generated succesfully.'
				insert into ##osql_holding values(@bcp)
				insert into ##osql_holding values('exec master..xp_cmdshell @cmd')
			end
		drop table ##cmdhold
	END
	FETCH NEXT FROM dbperm INTO @dbname
END
CLOSE dbperm
DEALLOCATE dbperm

if (select count(*) from ##osql_holding) > 1
begin
	SELECT @bcp = 'bcp "SELECT rtrim(text) FROM ' + @dbname + '.dbo.##osql_holding" QUERYOUT "'+@path+'Restore_UserPermissions_'+ @server_name+'.sql" -T -c'
	EXEC @Status = master.dbo.xp_cmdshell @bcp, no_output
			IF @Status <> 0
			BEGIN
				PRINT 'An error ocurred while generating the SQL file.'
			END 
			ELSE 
			begin
				PRINT ''+@path+'Restore_UserPermissions_'+ @server_name+'.sql file generated succesfully.'
			end
end

drop table ##osql_holding
GO
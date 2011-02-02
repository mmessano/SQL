 
declare @RegPathParams sysname
declare @Arg sysname
declare @Param sysname
declare @MasterPath nvarchar(512)
declare @LogPath nvarchar(512)
declare @ErrorLogPath nvarchar(512)
declare @n int

select @n=0
select @RegPathParams=N'Software\Microsoft\MSSQLServer\MSSQLServer'+'\Parameters'
select @Param='dummy'
while(not @Param is null)
	begin
		select @Param=null
		select @Arg='SqlArg'+convert(nvarchar,@n)

		exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', @RegPathParams, @Arg, @Param OUTPUT
		if(@Param like '-d%')
			begin
				select @Param=substring(@Param, 3, 255)
				select @MasterPath=substring(@Param, 1, len(@Param) - charindex('\', reverse(@Param)))
			end
			else if(@Param like '-l%')
			begin
				select @Param=substring(@Param, 3, 255)
				select @LogPath=substring(@Param, 1, len(@Param) - charindex('\', reverse(@Param)))
			end
			else if(@Param like '-e%')
			begin
				select @Param=substring(@Param, 3, 255)
				select @ErrorLogPath=substring(@Param, 1, len(@Param) - charindex('\', reverse(@Param)))
			end
					
			select @n=@n+1
	end

declare @SmoRoot nvarchar(512)
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\Setup', N'SQLPath', @SmoRoot OUTPUT

DECLARE @BackupLoc nvarchar(255) 
EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer', N'BackupDirectory', @param = @BackupLoc OUTPUT 

--INSERT newton.Status.dbo.SQLServerSettings 

SELECT
CAST(SERVERPROPERTY(N'MachineName') AS sysname) AS [NetName],
@LogPath AS [MasterDBLogPath],
@MasterPath AS [MasterDBPath],
@BackupLoc AS [BackupDir],
@ErrorLogPath AS [ErrorLogPath],
@SmoRoot AS [RootDirectory],
SERVERPROPERTY(N'ProductVersion') AS [VersionString],
CAST(SERVERPROPERTY(N'Edition') AS sysname) AS [Edition],
CAST(SERVERPROPERTY(N'ProductLevel') AS sysname) AS [ProductLevel]

-- ***************************************************************************
-- Copyright (C) 1991-2003 SQLDEV.NET
-- 
-- file:	SQL Server location functions.sql
-- descr.:	SQL Server Location Functions
-- author:	Gert E.R. Drapers (GertD@SQLDev.Net)
--
-- nvarchar(4000) = dbo.fn_SQLServerInstallDir()
-- nvarchar(4000) = dbo.fn_SQLServerDataDir()
-- nvarchar(4000) = dbo.fn_SQLServerLogDir()
-- nvarchar(4000) = dbo.fn_SQLServerBackupDir()
-- 
-- @@bof_revsion_marker
-- revision history
-- yyyy/mm/dd  by       description
-- ==========  =======  ==========================================================
-- 2003/07/06  gertd    v1.0.0.0 created
-- @@eof_revsion_marker
-- ***************************************************************************
use master
go

set nocount on

-- ***************************************************************************
-- nvarchar(4000) = dbo.fn_SQLServerInstallDir()
-- ***************************************************************************
if object_id('dbo.fn_SQLServerInstallDir') is not null
	drop function dbo.fn_SQLServerInstallDir
go

create function dbo.fn_SQLServerInstallDir()
returns nvarchar(4000)
as
begin

declare @rc int,
		@dir nvarchar(4000)

exec @rc = master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\Setup',N'SQLPath', @dir output, 'no_output'
return @dir

end
go

select fn_SQLServerInstallDir = dbo.fn_SQLServerInstallDir()
go

-- ***************************************************************************
-- nvarchar(4000) = dbo.fn_SQLServerDataDir()
-- ***************************************************************************
if object_id('dbo.fn_SQLServerDataDir') is not null
	drop function dbo.fn_SQLServerDataDir
go

create function dbo.fn_SQLServerDataDir()
returns nvarchar(4000)
as
begin

declare @rc int,
		@dir nvarchar(4000)
exec @rc = master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer',N'DefaultData', @dir output, 'no_output'

if (@dir is null)
begin
	exec @rc = master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\Setup',N'SQLDataRoot', @dir output, 'no_output'
	select @dir = @dir + N'\Data'
end

return @dir

end
go

select fn_SQLServerDataDir = dbo.fn_SQLServerDataDir()
go

-- ***************************************************************************
-- nvarchar(4000) = dbo.fn_SQLServerLogDir()
-- ***************************************************************************
if object_id('dbo.fn_SQLServerLogDir') is not null
	drop function dbo.fn_SQLServerLogDir
go

create function dbo.fn_SQLServerLogDir()
returns nvarchar(4000)
as
begin

declare @rc int,
		@dir nvarchar(4000)

exec @rc = master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer',N'DefaultLog', @dir output, 'no_output'

if (@dir is null)
begin
	exec @rc = master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\Setup',N'SQLDataRoot', @dir output, 'no_output'
	select @dir = @dir + N'\Data'
end

return @dir

end
go

select fn_SQLServerLogDir = dbo.fn_SQLServerLogDir()
go

-- ***************************************************************************
-- nvarchar(4000) = dbo.fn_SQLServerBackupDir()
-- ***************************************************************************
if object_id('dbo.fn_SQLServerBackupDir') is not null
	drop function dbo.fn_SQLServerBackupDir
go

create function dbo.fn_SQLServerBackupDir()
returns nvarchar(4000)
as
begin

declare @rc int,
		@dir nvarchar(4000)

exec @rc = master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer',N'BackupDirectory', @dir output, 'no_output'
return @dir

end
go

select fn_SQLServerBackupDir = dbo.fn_SQLServerBackupDir()
go

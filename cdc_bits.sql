sys.sp_cdc_get_captured_columns
SELECT * FROM sys.dm_cdc_errors


-- SELECT * FROM sys.databases


SELECT	@@SERVERNAME AS ServerName,
		name, 
		is_cdc_enabled
	FROM sys.databases
	WHERE name NOT IN ('master', 'model', 'msdb', 'tempdb', 'dbamaint')
	AND name NOT LIKE '%Management'
	AND name NOT LIKE 'distribution' 
	AND is_cdc_enabled = '1'
ORDER BY is_cdc_enabled desc, 1,2


SELECT * FROM sys.dm_os_waiting_tasks
where blocking_session_id IS NOT NULL
order by 2


Select [name], is_tracked_by_cdc from sys.tables
WHERE is_tracked_by_cdc = '1'
order by 1
GO

-- disable commands
/*
EXECUTE sys.sp_cdc_disable_db;
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

if exists ( select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_CDCGetColumnList]' ) )
BEGIN
	DROP FUNCTION [dbo].[fn_CDCGetColumnList] 
END
GO

if exists ( select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_CDCGetTableList]' ) )
BEGIN
	DROP FUNCTION [dbo].[fn_CDCGetTableList] 
END
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[usp_CDCDisable]') and OBJECTPROPERTY(id, N'IsProcedure') = 1) 
BEGIN
	DROP PROCEDURE [dbo].[usp_CDCDisable]
END
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[usp_CDCEnable]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
BEGIN
	DROP PROCEDURE [dbo].[usp_CDCEnable]
END
GO
*/
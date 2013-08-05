DECLARE @dbname VARCHAR(128)
DECLARE @cmd VARCHAR(MAX)

DECLARE Datadbs CURSOR FOR
	SELECT name from sys.databases
	WHERE name LIKE 'DMart%Data'
	AND name NOT LIKE '%Template%'
	ORDER BY 1
	
OPEN Datadbs
FETCH NEXT FROM Datadbs INTO @dbname
WHILE @@fetch_status = 0

BEGIN

SELECT @cmd = 'E:\Dexma\powershell_bits\Compare-DMartSchema2.ps1 -SqlServerOne ' + @@SERVERNAME + ' -FirstDatabase DMart_Template_Data -SqlServerTwo ' + @@SERVERNAME + ' -DatabaseList "DMart_ABECU_Data, DMart_Addison_Data, DMart_AmericaFirst_Data, DMart_AmericanAirlines_Data" -Column -Log'

PRINT (@cmd)

FETCH NEXT FROM Datadbs INTO @dbname
END
 
CLOSE Datadbs
DEALLOCATE Datadbs

------------------------------------------------------------------------------------------------------------------------
-- all databases compared against DMart_Template_*
/*
DECLARE @EmployeeList varchar(100)

SELECT @EmployeeList = COALESCE(@EmployeeList + ', ', '') + 
   CAST(Emp_UniqueID AS varchar(5))
FROM SalesCallsEmployees
WHERE SalCal_UniqueID = 1

SELECT @EmployeeList
*/
-- old package
DECLARE @dblistStage NVARCHAR(MAX)
DECLARE @dblistData NVARCHAR(MAX)
DECLARE @cmd2 VARCHAR(MAX)
DECLARE @cmd3 VARCHAR(MAX)

SELECT @dblistData = COALESCE(@dblistData + ', ', '') +	name 
				FROM sys.databases
				WHERE name LIKE 'DMart%Data'
				AND name NOT LIKE '%Template%'
				GROUP BY name

SELECT @dblistStage = COALESCE(@dblistStage + ', ', '') +	name 
				FROM sys.databases
				WHERE name LIKE 'DMart%Stage'
				AND name NOT LIKE '%Template%'
				GROUP BY name

SELECT @cmd2 = 'E:\Dexma\powershell_bits\Compare-DMartSchema2.ps1 -SqlServerOne ' + 
				@@SERVERNAME + ' -FirstDatabase DMart_Template_Data -SqlServerTwo ' + 
				@@SERVERNAME + ' -DatabaseList ' + @dblistData + ' -Column -Log'

SELECT @cmd3 = 'E:\Dexma\powershell_bits\Compare-DMartSchema2.ps1 -SqlServerOne ' + 
				@@SERVERNAME + ' -FirstDatabase DMart_Template_Stage -SqlServerTwo ' + 
				@@SERVERNAME + ' -DatabaseList ' + @dblistStage + ' -Column -Log'

PRINT (@cmd2)
PRINT (@cmd3)
------------------------------------------------------------------------------------------------------------------------
-- CDC package
DECLARE @CDCData NVARCHAR(MAX)
DECLARE @CDCcmd VARCHAR(MAX)

SELECT @CDCData = COALESCE(@CDCData + ', ', '') +	name 
				FROM sys.databases
				WHERE name LIKE 'DMart%CDC%Data'
				AND name NOT LIKE '%Template%'
				GROUP BY name

SELECT @CDCcmd = 'E:\Dexma\powershell_bits\Compare-DMartSchema2.ps1 -SqlServerOne ' + 
				@@SERVERNAME + ' -FirstDatabase DMart_TemplateCDC_Data -SqlServerTwo ' + 
				@@SERVERNAME + ' -DatabaseList ' + @CDCData + ' -Column -Log'

PRINT (@CDCcmd)
------------------------------------------------------------------------------------------------------------------------
-- XSQLUTIL18.dbo.Status
USE Status
GO

DECLARE @ServerList NVARCHAR(MAX)
DECLARE @cmd NVARCHAR(MAX)

SELECT @ServerList = COALESCE(@ServerList + ', ', '') + RTRIM(LTRIM([server_name]))
FROM Status.dbo.t_server s
	INNER JOIN [t_server_type_assoc] sta		on s.server_id = sta.server_id 
	INNER JOIN [t_server_type] st			on sta.type_id = sT.type_id 
	INNER JOIN [t_environment] e			on s.environment_id = e.environment_id 
	INNER JOIN [t_monitoring] m			on s.server_id = m.server_id 
where type_name = 'DB' AND active = 1
GROUP BY server_name
ORDER BY server_name

--print @ServerList

SELECT @cmd =	'E:\Dexma\powershell_bits\Compare-DbamaintSchema.ps1 ' +
				'-ServerList ' + @ServerList + ' -Column -Log'
				
PRINT (@cmd)				
------------------------------------------------------------------------------------------------------------------------
-- XSQLUTIL18.Status
--USE Status
--GO

--DECLARE @Server VARCHAR(128)
--DECLARE @cmd VARCHAR(MAX)

--DECLARE dbamaintdbs CURSOR FOR
--	SELECT distinct RTRIM(LTRIM([server_name])) AS ServerName
--		FROM [t_server] s 
--		INNER JOIN [t_server_type_assoc] sta		on s.server_id = sta.server_id 
--		INNER JOIN [t_server_type] st			on sta.type_id = sT.type_id 
--		INNER JOIN [t_environment] e			on s.environment_id = e.environment_id 
--		INNER JOIN [t_monitoring] m			on s.server_id = m.server_id 
--		where type_name = 'DB' AND active = 1
--	ORDER BY 1
	
--OPEN dbamaintdbs
--FETCH NEXT FROM dbamaintdbs INTO @Server
--WHILE @@fetch_status = 0 

--BEGIN

----SELECT @cmd = 'C:\Dexma\powershell_bits\Compare-DMartSchema.ps1 -SqlServerOne XSQLUTIL18 -FirstDatabase dbamaint -SqlServerTwo ' + @Server + ' -SecondDatabase dbamaint -Column -Log'
--SELECT @cmd = 'dbm_CompareDB @db1 = ''dbamaint'', @db2 = ''' + @Server + '.dbamaint'', @NumbToShow = ''100'', @OnlyStructure = ''1'', @NoTimeStamp = ''1'', @VerboseLevel = ''1'''
--PRINT (@cmd)

--FETCH NEXT FROM dbamaintdbs INTO @Server
--END
 
--CLOSE dbamaintdbs
--DEALLOCATE dbamaintdbs
------------------------------------------------------------------------------------------------------------------------
-- PSQLSMC30
DECLARE @dblistStage NVARCHAR(MAX)
DECLARE @dblistData NVARCHAR(MAX)
DECLARE @cmd2 VARCHAR(MAX)
DECLARE @cmd3 VARCHAR(MAX)

SELECT @dblistData = COALESCE(@dblistData + ', ', '') +	name 
				FROM sys.databases
				WHERE name LIKE '%SMC'
				AND name NOT LIKE '%Test%'
				GROUP BY name

SELECT @dblistStage = COALESCE(@dblistStage + ', ', '') +	name 
				FROM sys.databases
				WHERE name LIKE '%SMC'
				AND name NOT LIKE '%Test%'
				GROUP BY name

SELECT @cmd2 = 'E:\Dexma\powershell_bits\Compare-DMartSchema2.ps1 -SqlServerOne ' + 
				@@SERVERNAME + ' -FirstDatabase RLCSMC -SqlServerTwo ' + 
				@@SERVERNAME + ' -DatabaseList ' + @dblistData + ' -Column -Log'

-- use the Dev current version
SELECT @cmd3 = 'E:\Dexma\powershell_bits\Compare-DMartSchema2.ps1 -SqlServerOne ' + 
				'ISQLDEV610 -FirstDatabase SMCCurrent -SqlServerTwo ' + 
				@@SERVERNAME + ' -DatabaseList ' + @dblistStage + ' -Column -Log'

PRINT (@cmd2)
PRINT (@cmd3)


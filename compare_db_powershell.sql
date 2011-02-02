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

SELECT @cmd = 'C:\Dexma\powershell_bits\Compare-DMartSchema.ps1 -SqlServerOne PSQLRPT22 -FirstDatabase DMart_Template_Data -SqlServerTwo PSQLRPT22 -SecondDatabase ' + @dbname + ' -Column -Log'

PRINT (@cmd)

FETCH NEXT FROM Datadbs INTO @dbname
END
 
CLOSE Datadbs
DEALLOCATE Datadbs

------------------------------------------------------------------------------------------------------------------------

--DECLARE @dbname VARCHAR(128)
--DECLARE @cmd VARCHAR(MAX)

DECLARE Datadbs CURSOR FOR
	SELECT name from sys.databases
	WHERE name LIKE 'DMart%Stage'
	AND name NOT LIKE '%Template%'
	ORDER BY 1
	
OPEN Datadbs
FETCH NEXT FROM Datadbs INTO @dbname
WHILE @@fetch_status = 0 

BEGIN

SELECT @cmd = 'C:\Dexma\powershell_bits\Compare-DMartSchema.ps1 -SqlServerOne PSQLRPT22 -FirstDatabase DMart_Template_Stage -SqlServerTwo PSQLRPT22 -SecondDatabase ' + @dbname + ' -Column -Log'

PRINT (@cmd)

FETCH NEXT FROM Datadbs INTO @dbname
END
 
CLOSE Datadbs
DEALLOCATE Datadbs

------------------------------------------------------------------------------------------------------------------------

DECLARE @Server VARCHAR(128)
DECLARE @cmd VARCHAR(MAX)

DECLARE dbamaintdbs CURSOR FOR
	SELECT distinct RTRIM(LTRIM([server_name])) 
		AS ServerName--, s.server_id AS ServerID 
		FROM [t_server] s 
		INNER JOIN [t_server_type_assoc] sta		on s.server_id = sta.server_id 
		INNER JOIN [t_server_type] st			on sta.type_id = st.type_id 
		INNER JOIN [t_environment] e			on s.environment_id = e.environment_id 
		INNER JOIN [t_monitoring] m			on s.server_id = m.server_id 
		where type_name = 'DB' AND active = 1
	ORDER BY 1
	
OPEN dbamaintdbs
FETCH NEXT FROM dbamaintdbs INTO @Server
WHILE @@fetch_status = 0 

BEGIN

--SELECT @cmd = 'C:\Dexma\powershell_bits\Compare-DMartSchema.ps1 -SqlServerOne XSQLUTIL18 -FirstDatabase dbamaint -SqlServerTwo ' + @Server + ' -SecondDatabase dbamaint -Column -Log'
SELECT @cmd = 'dbm_CompareDB @db1 = ''dbamaint'', @db2 = ''' + @Server + '.dbamaint'', @NumbToShow = ''100'', @OnlyStructure = ''1'', @NoTimeStamp = ''1'', @VerboseLevel = ''1'''
PRINT (@cmd)

FETCH NEXT FROM dbamaintdbs INTO @Server
END
 
CLOSE dbamaintdbs
DEALLOCATE dbamaintdbs

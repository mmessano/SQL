SELECT database_name
		, linked_database_name
FROM client_data_sources
ORDER BY 1

-------------------------------------------------------------------------------------------------------------
Declare @cmd nvarchar(4000), @params nvarchar(4000) Declare @envint varchar(2) Declare @cdetext varchar(16)
DECLARE @Err_Client VARCHAR(64)
DECLARE @Err_DBServer VARCHAR(64)

SELECT @Err_Client = 'BECU'

Set @envint = '21'
Set @cdetext = 'Prod Site'

SELECT @cmd =
N' SELECT @DBServer = dv10.dv_value ' +
N' FROM ' +
N' xsqlutil18.DexmaSites.dbo.clients cl LEFT JOIN ' + 
N' xsqlutil18.DexmaSites.dbo.data_values dv10 ON dv10.di_id = ''' + @envint + ''' ' + N' AND ' + 
N' dv10.dv_id = (select dv_id from xsqlutil18.DexmaSites.dbo.client_data_xref where cl_id = cl.cl_id and di_id = ''' + @envint + ''') ' + 
N' LEFT JOIN (SELECT cl_name, cde_value ' + 
N' FROM xsqlutil18.DexmaSites.dbo.clients cl2 JOIN ' + 
N' xsqlutil18.DexmaSites.dbo.client_data_elements cde ON cl2.cl_id = cde.cl_id ' + 
N' AND cde.cde_key = ''' + @cdetext + ''') e5 ON cl.cl_name = e5.cl_name ' + 
N' WHERE ' + N' e5.cde_value LIKE ''%' + @Err_Client + '%'' '

SELECT @params = N'@DBServer varchar(16) OUTPUT'

EXEC sp_executesql @cmd, @params, @DBServer = @Err_DBServer OUTPUT
print @Err_DBServer
-------------------------------------------------------------------------------------------------------------
-- works 8/10/2011
SELECT cl.cl_name AS ClientName, dv10.dv_value AS DBServer, dv11.dv_value AS DBName
FROM xsqlutil18.DexmaSites.dbo.clients cl 
	LEFT JOIN xsqlutil18.DexmaSites.dbo.data_values dv10 ON dv10.di_id = '21' 
		AND dv10.dv_id = (select dv_id from xsqlutil18.DexmaSites.dbo.client_data_xref where cl_id = cl.cl_id and di_id = '21')
	LEFT JOIN xsqlutil18.DexmaSites.dbo.data_values dv11 ON dv11.di_id = '62'
		AND dv11.dv_id = (select dv_id from xsqlutil18.DexmaSites.dbo.client_data_xref where cl_id = cl.cl_id and di_id = '62')
	LEFT JOIN (SELECT cl_name, cde_value
				FROM xsqlutil18.DexmaSites.dbo.clients cl2 
				JOIN xsqlutil18.DexmaSites.dbo.client_data_elements cde ON cl2.cl_id = cde.cl_id 
					AND cde.cde_key = 'Prod Site') e5 ON cl.cl_name = e5.cl_name 
WHERE e5.cl_name IS NOT NULL
		AND dv10.dv_value IS NOT NULL
		AND dv11.dv_value IS NOT NULL
		-- trim non-PA or old clients etc
		AND dv10.dv_value NOT IN ('PLUTO', 'MERCURY', 'ORION', 'GEDB1', 'VEGA', 'PEGASUS')
ORDER BY 1

-------------------------------------------------------------------------------------------------------------
-- needs additional field added for dbname
SELECT *
FROM XSQLUTIL18.CBSSites.dbo.Servers s
  JOIN XSQLUTIL18.CBSSites.dbo.Library l on l.Library_ID = s.Server_Library_ID
  JOIN XSQLUTIL18.CBSSites.dbo.Server_Types st on st.ServerType_ID = s.Server_ServerType_ID AND st.ServerType_Description = 'DB'
  JOIN XSQLUTIL18.CBSSites.dbo.Client_Environments ce on ce.ClientEnv_ID = s.Server_ClientEnv_ID
  JOIN XSQLUTIL18.CBSSites.dbo.Clients c ON c.Client_ID = ce.ClientEnv_Client_ID 
  JOIN XSQLUTIL18.CBSSites.dbo.Environments e on e.Env_ID = ce.ClientEnv_Env_ID AND e.Env_Name LIKE '%PROD%'
  --JOIN XSQLUTIL18.CBSSites.dbo.Links lnk on lnk.Link_ClientEnv_ID = s.Server_ClientEnv_ID
 

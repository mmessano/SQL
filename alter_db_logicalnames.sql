/*
exec dbamaint.dbo.dbm_filespacestats

sp_helptext sel_sql_filelocations


select server_name, dbname, Name as LogicalName, FileName, convert(char(10), report_date, 101) AS ReportDate 
from sql_spacestats  
 where convert(char(10), report_date, 101) = convert(char(10), GetDate(), 101) 
and server_name = 'xspi2kdb2' 
--and dbname IN ('AltaOne','ArizonaStateCU','BayFederal','Bellco32','Boeing4','ColonialRLC','ConfigurationManagement','CUAnswers','DenverPublicSchools','DexmaRLC','FirstFarmers','Kinecta','Merchants','MidMinnesota','PADemoDU','PADemoLP','PAPrototype_DataMart','PremierAmerica','Purdue','PWBDefaultClient','RLC','sdtConditionsManagement','SecurityServices','SPI10','spiQAbase','SPToolTest','TLETrain','Weyerhaeuser')
 order by server_name, dbname  

*/

Declare @cmd varchar(8000)
Declare @dbs varchar(3000)
Declare @logical_dataname varchar(128)
Declare @logical_logname varchar(128)
Declare @dbname varchar(32)

Set @dbs = 'StatusStage'



declare dbname cursor for 
	select * from [dbamaint].[dbo].[udf_split](@dbs,',')

open dbname 
	fetch next from dbname into @dbname 
	while @@fetch_status=0 
begin 


--SELECT @logical_dataname = ( SELECT TOP 1 Name FROM dbamaint..sql_spacestats WHERE dbname = @dbname and FileName LIKE '%.mdf' )
--SELECT @logical_logname = ( SELECT TOP 1 Name FROM dbamaint..sql_spacestats WHERE dbname = @dbname and FileID = '2' )

SELECT @logical_dataname = ( SELECT TOP 1 Name FROM dbamaint..filespacestats WHERE dbname = @dbname and FileName LIKE '%.mdf' )
SELECT @logical_logname = ( SELECT TOP 1 Name FROM dbamaint..filespacestats WHERE dbname = @dbname and FileID = '2' )

--print @dbname
--print @logical_dataname
--print @logical_logname + char(13)


select @cmd =		' ALTER DATABASE [' + @dbname + ']' + char(13) +
					' MODIFY FILE (NAME=N''' + @logical_dataname + ''', NEWNAME=N''' + @dbname +'_Data'')' + char(13) +
					' GO ' + char(13) +
					' ALTER DATABASE [' + @dbname + ']' + char(13) +
					' MODIFY FILE (NAME=N''' + RTRIM(@logical_logname) + ''', NEWNAME=N''' + @dbname +'_Log'')' + char(13) +
					' GO ' + char(13)
/*

ALTER DATABASE [AEA] MODIFY FILE (NAME=N'AEA_Data', NEWNAME=N'AEA_Data2')
GO
ALTER DATABASE [AEA] MODIFY FILE (NAME=N'AEA_Log', NEWNAME=N'AEA_Log2')
GO

*/
print(@cmd)
fetch next from dbname into @dbname 
end
 
CLOSE dbname 
DEALLOCATE dbname 

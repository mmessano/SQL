DECLARE @Servers varchar(128)
DECLARE @Server varchar(16)
DECLARE @cmd varchar(384)

SET @Servers = 'ISQLDEV512,PSQLDIRECT20,PSQLOPS10,PSQLPA20,PSQLPA21,PSQLPA22,PSQLSVC20,QSQL510,STGSQL511'

--TRUNCATE TABLE ReplicationMonitors

DECLARE servername CURSOR FOR 
	SELECT * FROM [dbamaint].[dbo].[udf_split](@Servers,',')
	
OPEN servername
	FETCH NEXT FROM servername INTO @Server
	WHILE @@fetch_status = 0

BEGIN
-- retrieve the last 3 samples(5 minute increments)
SELECT @cmd = '
--INSERT INTO ReplicationMonitors
SELECT MonitorDate, PublicationName, PublicationDB, Iteration, TracerID, DistributorLatency, Subscriber, SubscriberDB, SubscriberLatency, OverallLatency 
FROM [' + @Server + '].[dbamaint].[dbo].[ReplicationMonitor]
WHERE MonitorDate BETWEEN DATEADD(mi,-15,GETDATE()) AND GETDATE()
AND OverallLatency > 5
ORDER BY 1
'

PRINT @cmd
--EXEC(@cmd)

FETCH NEXT FROM servername INTO @Server
END;	

CLOSE servername
DEALLOCATE servername

SELECT * FROM ReplicationMonitors
ORDER BY 1,3
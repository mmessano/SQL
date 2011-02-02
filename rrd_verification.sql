--DECLARE @CPUDir VARCHAR(64)
--DECLARE @MemoryDir VARCHAR(64)
DECLARE @IISConn VARCHAR(64)

--SELECT @CPUDir = '\\oapputil10\dexma\support\monitoring\CPU'
--SELECT @MemoryDir = '\\oapputil10\dexma\support\monitoring\Memory'
SELECT @IISConn = '\\oapputil10\dexma\Support\Monitoring\Connections'

-------------------------------------------------------------------------------
-- ##Summary needs to be global for the dbmail sproc to work
-------------------------------------------------------------------------------
--CREATE TABLE #CPUDir (MyFile varchar(32))  
--CREATE TABLE #MemoryDir (MyFile varchar(32))  
CREATE TABLE #IISConn (MyFile varchar(32))
CREATE TABLE ##Summary (ServerName VARCHAR(16), RRDFileName VARCHAR(32), ACTION VARCHAR(34))
-------------------------------------------------------------------------------
-- gather rrd files
-------------------------------------------------------------------------------
--EXEC dbamaint.dbo.dbm_ListFiles @CPUDir,'#CPUDir','%.rrd','NULL',0
--EXEC dbamaint.dbo.dbm_ListFiles @MemoryDir,'#MemoryDir','%.rrd','NULL',0
EXEC dbamaint.dbo.dbm_ListFiles @IISConn,'#IISConn','%.rrd','NULL',0
-------------------------------------------------------------------------------
-- aggregate action items
-- insert into ##Summary temp table
-------------------------------------------------------------------------------
-- CPU
-------------------------------------------------------------------------------
--INSERT INTO ##Summary   
--select CONVERT(VARCHAR(16),s.server_name) AS ServerName, c.MyFile AS RRDFileName, 'Create CPU RRD' AS Action 
--				from	status.dbo.t_server s	LEFT OUTER join 
--				status.dbo.t_monitoring m	ON s.server_id = m.server_id		LEFT OUTER join  
--				#CPUDir c			ON c.Myfile LIKE (s.server_name + '%.rrd') 
--				where 	s.Active = 1 
--				and cpu = 1 
--				AND c.MyFile IS NULL
--UNION
--SELECT CONVERT(VARCHAR(16),s.server_name) AS ServerName, c.MyFile AS RRDFileName, 'Remove CPU RRD - No Server' AS Action 
--				from	status.dbo.t_server s	RIGHT OUTER join 
--				status.dbo.t_monitoring m ON s.server_id = m.server_id	RIGHT OUTER join  
--				#CPUDir c ON c.Myfile LIKE (s.server_name + '%.rrd') 
--				WHERE s.server_name IS NULL
--UNION
--SELECT CONVERT(VARCHAR(16),s.server_name) AS ServerName, c.MyFile AS RRDFileName, 'Remove CPU RRD - Not Monitored' AS Action 
--				from	status.dbo.t_server s	  LEFT OUTER join
--				status.dbo.t_monitoring m	ON s.server_id = m.server_id		LEFT OUTER  join  
--				#CPUDir c			ON c.Myfile LIKE (s.server_name + '%.rrd') 
--				where cpu = 0
--				AND ( c.MyFile IS NOT NULL OR s.server_name IS NULL )
-------------------------------------------------------------------------------
-- Memory
-------------------------------------------------------------------------------
--INSERT INTO ##Summary 
--SELECT CONVERT(VARCHAR(16),s.server_name) AS ServerName, md.MyFile AS RRDFileName, 'Create Memory RRD' AS Action
--				from	status.dbo.t_server s	LEFT OUTER join
--				status.dbo.t_monitoring m	ON s.server_id = m.server_id		LEFT OUTER join  
--				#MemoryDir md			ON md.Myfile LIKE (s.server_name + '%.rrd')
--				where 	s.Active = 1 
--				and m.memory = 1 
--				AND md.MyFile IS NULL 
--UNION
--SELECT CONVERT(VARCHAR(16),s.server_name) AS ServerName, md.MyFile AS RRDFileName, 'Remove Memory RRD - No Server' AS Action 
--				from	status.dbo.t_server s	RIGHT OUTER join 
--				status.dbo.t_monitoring m ON s.server_id = m.server_id	RIGHT OUTER join  
--				#MemoryDir md ON md.Myfile LIKE (s.server_name + '%.rrd') 
--				WHERE s.server_name IS NULL
--UNION
--SELECT CONVERT(VARCHAR(16),s.server_name) AS ServerName, md.MyFile AS RRDFileName, 'Remove Memory RRD - Not Monitored' AS Action 
--				from	status.dbo.t_server s	  LEFT OUTER join 
--				status.dbo.t_monitoring m	ON s.server_id = m.server_id		LEFT OUTER  join  
--				#MemoryDir md			ON md.Myfile LIKE (s.server_name + '%.rrd') 
--				where cpu = 0
--				AND ( md.MyFile IS NOT NULL OR s.server_name IS NULL )
-------------------------------------------------------------------------------
-- IISConnection
-------------------------------------------------------------------------------
INSERT INTO ##Summary 
SELECT CONVERT(VARCHAR(16),s.server_name) AS ServerName, i.MyFile AS RRDFileName, 'Create IISConn RRD' AS Action
				from	status.dbo.t_server s	LEFT OUTER join 
				status.dbo.t_monitoring m	ON s.server_id = m.server_id		LEFT OUTER join  
				#IISConn i			ON i.Myfile LIKE (s.server_name + '%.rrd') 
				where 	s.Active = 1 
				and m.iissites = 1 
				AND i.MyFile IS NULL 
UNION
SELECT CONVERT(VARCHAR(16),s.server_name) AS ServerName, i.MyFile AS RRDFileName, 'Remove IISConn RRD - No Server' AS Action 
				from	status.dbo.t_server s	RIGHT OUTER join 
				status.dbo.t_monitoring m ON s.server_id = m.server_id	RIGHT OUTER join  
				#IISConn i ON i.Myfile LIKE (s.server_name + '%.rrd') 
				WHERE s.server_name IS NULL
UNION
SELECT CONVERT(VARCHAR(16),s.server_name) AS ServerName, i.MyFile AS RRDFileName, 'Remove IISConn RRD - Not Monitored' AS Action 
				from	status.dbo.t_server s	  LEFT OUTER join 
				status.dbo.t_monitoring m	ON s.server_id = m.server_id		LEFT OUTER  join  
				#IISConn i			ON i.Myfile LIKE (s.server_name + '%.rrd')
				where m.iissites = 0
				AND ( i.MyFile IS NOT NULL OR s.server_name IS NULL )
-------------------------------------------------------------------------------
-- check @@ROWCOUNT, send email if greater than 0
-------------------------------------------------------------------------------
SELECT * FROM ##Summary
IF @@ROWCOUNT > 0
EXEC msdb.dbo.sp_send_dbmail @recipients='productoperations@dexma.com',
    @subject = 'RRD Verification',
    @body = '
RRD FILE Locations:			
CPU		= \\oapputil10\dexma\support\monitoring\CPU
Memory	= \\oapputil10\dexma\support\monitoring\Memory
IISConn	= \\oapputil10\dexma\Support\Monitoring\Connections

Script Locations:
CPU		- \\oapputil10\dexma\Support\Monitoring\create_cpu_rrd.pl
Memory	- \\oapputil10\dexma\Support\Monitoring\create_memory_rrd.pl
IISConn	- \\oapputil10\dexma\Support\Monitoring\create_IIS_connections_rrd.pl

',
    @query =	'SELECT * FROM ##Summary order by 3,1',
    @body_format = 'TEXT' ;
-------------------------------------------------------------------------------
-- clean up temp tables
-------------------------------------------------------------------------------
--DROP TABLE #CPUDir
--DROP TABLE #MemoryDir
DROP TABLE #IISConn
DROP TABLE ##Summary
-----------------

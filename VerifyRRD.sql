DECLARE @CPUDir VARCHAR(64)
DECLARE @MemoryDir VARCHAR(64)
DECLARE @IISConn VARCHAR(64)

SELECT @CPUDir = '\\oapputil10\dexma\support\monitoring\CPU'
SELECT @MemoryDir = '\\oapputil10\dexma\support\monitoring\Memory'
SELECT @IISConn = '\\oapputil10\dexma\Support\Monitoring\Connections'

CREATE TABLE ##CPUDir (MyFile varchar(200))  
CREATE TABLE ##MemoryDir (MyFile varchar(200))  
CREATE TABLE ##IISConn (MyFile varchar(200))  
/*
The dbm_ListFiles stored procedure accepts five parameters. Only the first one is required.  
Parameter 1 is a path to a directory. The path must be accessible to SQL Server (the service account or the proxy account).  
Parameter 2 is a table name in which to insert the file/folder names. It can be a normal user table or a temporary table. If no table name is provided, the list is returned as a result set.  
Parameter 3 is a filter for including certain names. Each name is compared to the filter using a LIKE operator, so wildcards are acceptable. For example, the value "%.doc" would include all Word documents.  
Parameter 4 is a filter for excluding certain names. Each name is compared to the filter using a NOT LIKE operator, so wildcards are acceptable.  
Parameter 5 determines whether files or folders are listed. A value of zero (0) returns files and a value of one (1) returns folders.   
*/
-- gather rrd files
EXEC dbamaint.dbo.dbm_ListFiles @CPUDir,'##CPUDir','%.rrd','NULL',0
EXEC dbamaint.dbo.dbm_ListFiles @MemoryDir,'##MemoryDir','%.rrd','NULL',0
EXEC dbamaint.dbo.dbm_ListFiles @IISConn,'##IISConn','%.rrd','NULL',0
-------------------------------------------------------------------------------
-- send CPU mail
-------------------------------------------------------------------------------
EXEC msdb.dbo.sp_send_dbmail @recipients='mmessano@primealliancesolutions.com',
    @subject = 'Servers needing CPU RRD',
    @query =	'select s.server_name AS ServerName--, c.MyFile AS CPURRD 
				from	status.dbo.t_server s	LEFT OUTER join 
				status.dbo.t_monitoring m	ON s.server_id = m.server_id		LEFT OUTER join  
				##CPUDir c			ON c.Myfile LIKE (s.server_name + ''%.rrd'') 
				where 	s.Active = 1 
				and cpu = 1 
				AND c.MyFile IS NULL 
				order by 1 ',
    @body_format = 'TEXT' ;
-------------------------------------------------------------------------------
-- send Memory mail
-------------------------------------------------------------------------------
EXEC msdb.dbo.sp_send_dbmail @recipients='mmessano@primealliancesolutions.com',
    @subject = 'Servers needing Memory RRD',
    @query =	'select s.server_name AS ServerName
				from	status.dbo.t_server s	LEFT OUTER join 
				status.dbo.t_monitoring m	ON s.server_id = m.server_id		LEFT OUTER join  
				##MemoryDir md			ON md.Myfile LIKE (s.server_name + ''%.rrd'')
				where 	s.Active = 1 
				and m.memory = 1 
				AND md.MyFile IS NULL 
				order by 1 ',
    @body_format = 'TEXT' ;
-------------------------------------------------------------------------------
-- send IISConn mail
-------------------------------------------------------------------------------
EXEC msdb.dbo.sp_send_dbmail @recipients='mmessano@primealliancesolutions.com',
    @subject = 'Servers needing IISConn RRD',
    @query =	'select s.server_name AS ServerName
				from	status.dbo.t_server s	LEFT OUTER join 
				status.dbo.t_monitoring m	ON s.server_id = m.server_id		LEFT OUTER join  
				##IISConn i			ON i.Myfile LIKE (s.server_name + ''%.rrd'') 
				where 	s.Active = 1 
				and m.iissites = 1 
				AND i.MyFile IS NULL 
				order by 1 ',
    @body_format = 'TEXT' ;
-------------------------------------------------------------------------------
DROP TABLE ##CPUDir
DROP TABLE ##MemoryDir
DROP TABLE ##IISConn


----------------

dbm_CompareTables(@table1 varchar(100),
 @table2 Varchar(100), @T1ColumnList varchar(1000),
 @T2ColumnList varchar(1000) = '')



dbm_CompareTables @table1='OSQLUTIL12.Status.dbo.t_server',@T1ColumnList='server_id,server_name,environment_id,description,active,LastUpdate',@table2='ISQLCBS510.StatusIMP.dbo.t_server'


select TOP 5 * from OSQLUTIL12.Status.dbo.t_server

SELECT MAX(TableName) as TableName, server_id, server_name, environment_id, description, active, LastUpdate
FROM
(
  SELECT 'OSQLUTIL12.Status.dbo.t_server' as TableName, server_id, server_name, environment_id, description,active, LastUpdate
  FROM OSQLUTIL12.Status.dbo.t_server
  UNION ALL
  SELECT 'ISQLCBS510.StatusIMP.dbo.t_server' as TableName, server_id, server_name, environment_id, description, active, LastUpdate
  FROM ISQLCBS510.StatusIMP.dbo.t_server
) tmp
GROUP BY server_id, server_name, environment_id, description, active, LastUpdate
HAVING COUNT(*) = 1
ORDER BY server_id

/*
SELECT Max(TableName) as TableName, server_id, server_name, environment_id,description,active,LastUpdate 
FROM 
(SELECT 'OSQLUTIL12.Status.dbo.t_server' AS TableName, server_id,server_name,environment_id,description,active,LastUpdate 
FROM OSQLUTIL12.Status.dbo.t_server 
UNION ALL 
SELECT 'ISQLCBS510.StatusIMP.dbo.t_server' As TableName, server_id,server_name,environment_id,description,active,LastUpdate 
FROM ISQLCBS510.StatusIMP.dbo.t_server) A 
GROUP BY server_id,server_name,environment_id,description,active,LastUpdate 
HAVING COUNT(*) = 1
*/


/*
server_id,server_name,environment_id,description,active,LastUpdate
1	1850HS1	10	 	0	2004-04-14 14:54:49.427
2	1850HS2	10	 	0	2004-04-14 14:54:49.427
3	360HS1	10	 	0	2004-04-14 14:54:49.427
4	360HS2	10	 	0	2004-04-14 14:54:49.427
5	380HS1	10	 	0	2004-04-14 14:54:49.427
*/
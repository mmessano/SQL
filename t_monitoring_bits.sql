use status

-- shows all servers and their types including those not classified by type
SELECT top 100 percent s.server_id, s.server_name, st.type_name, st.type_id, e.environment_name
from 	dbo.t_server s FULL OUTER JOIN
	dbo.t_server_type_assoc sta ON sta.server_id = s.server_id FULL OUTER JOIN
	dbo.t_server_type st ON st.type_id = sta.type_id FULL OUTER JOIN
	dbo.t_environment e ON e.environment_id = s.environment_id
where st.type_id IS NULL
and s.active = '1'
--where environment_name = 'Unknown'
--and type_name  like 'Workstation'
--order by st.type_id
order by s.server_name

sp_ins_environment 'Workstation'
sp_ins_server_type 'Blackberry'
sp_ins_component 'ConditionsAndTasksGenerator'
sp_ins_server_type 'VMWare Client'
select * from t_server
select * from t_server_type_assoc

--update t_server set environment_id = (select environment_id from t_environment where environment_name = 'Workstation') where server_name in (select server_name from t_server where type_id = (select type_id from t_server_type where type_name = 'Workstation'))

select server_id, server_name from t_server where environment_id = '11' and active = '1'

update t_server set environment_id = '12' where server_id IN ('725','810','783','813','777','805','769','781','771')

select * from t_component order by component_name

insert into t_monitoring (server_id) select server_id from t_server where active = '1'

--truncate table t_monitoring
select * from t_monitoring

SELECT distinct s.server_name, s.server_id,  st.type_name, st.type_id
from 	dbo.t_server s FULL OUTER JOIN
	dbo.t_server_type_assoc sta ON sta.server_id = s.server_id FULL OUTER JOIN
	dbo.t_server_type st ON st.type_id = sta.type_id
where s.active = '1'
and st.type_id not like '18'
--and st.type_name is not NULL
order by s.server_name



select distinct s.server_id
from	dbo.t_server s FULL OUTER JOIN
	dbo.t_server_type_assoc sta ON sta.server_id = s.server_id FULL OUTER JOIN
	dbo.t_server_type st ON st.type_id = sta.type_id
where s.active = '1'
and st.type_id not like '18'
and s.server_name not like '%dexma.com'
--order by s.server_name

select distinct s.server_name
from	dbo.t_server s INNER JOIN
	dbo.t_monitoring m ON s.server_id = m.server_id

select s.server_name, m.cpu, m.memory, m.diskspace, m.network
from dbo.t_monitoring m INNER JOIN
     dbo.t_server s ON m.server_id = s.server_id

-- all servers set up in t_monitoring
select s.server_name, m.server_id 
from 	dbo.t_monitoring m INNER JOIN 
	dbo.t_server s ON s.server_id = m.server_id
where s.active = '1'
order by server_name

-- all servers regardless of t_monitoring
-- excluding workstations and Infrastructure
select e.environment_name AS Environment, s.server_name, s.server_id, s.active AS Active, m.*--m.memory, m.diskspace 
from 	dbo.t_monitoring m 
FULL OUTER JOIN dbo.t_server s ON s.server_id = m.server_id
FULL OUTER JOIN dbo.t_environment e ON s.environment_id = e.environment_id
where s.active = '1'
and e.environment_name NOT IN ('Workstation', 'Infrastructure')
--order by server_name, e.environment_name
order by e.environment_name, server_name

-------------------------------------------------------------------------------------
select s.server_name AS Server, e.environment_name AS Environment, m.cpu AS CPU, m.memory AS Mem, m.diskspace AS HDisk, m.dsn AS DSN, m.dcom AS DCOM, m.sched_tasks AS SchedTasks, m.queues AS Queues, s.active from dbo.t_monitoring m FULL OUTER JOIN dbo.t_server s ON s.server_id = m.server_id FULL OUTER JOIN dbo.t_environment e ON s.environment_id = e.environment_id where s.active = '1'and e.environment_name NOT IN ('Workstation', 'Infrastructure', 'Non Dexma') AND s.server_name not like '%.dexma.com' order by s.active, s.server_name asc
-------------------------------------------------------------------------------------

--update t_monitoring set cpu = '0' 
--	where server_id IN 
--	(select server_id from t_server where server_name IN ('SPICA'))
update t_monitoring set DCOM = '0' 
	where server_id IN 
	(select server_id from t_server where server_name IN ('PDOC10'))	
--update t_monitoring set memory = '0' 
--	where server_id IN 
--	(select server_id from t_server where server_name IN ('SPICA'))
--update t_monitoring set diskspace = '0' 
--	where server_id IN 
--	(select server_id from t_server where server_name IN ('PDOC10'))
update t_monitoring set perfmon = '1' 
	where server_id IN 
	(select server_id from t_server where server_name IN ('PSQLSVC21'))
update t_monitoring set IISSites = '0' 
	where server_id IN 
	(select server_id from t_server where server_name IN ('PSQLSVC21'))
update t_monitoring set DSN = '0' 
	where server_id IN 
	(select server_id from t_server where server_name IN ('PDOC10'))
update t_monitoring set sched_tasks = '0' 
	where server_id IN 
	(select server_id from t_server where server_name IN ('PDOC10'))
update t_monitoring set drm = '1' 
	where server_id IN 
	(select server_id from t_server where server_name IN ('PSQLRPT24'))
----------------------------------------------------------------------------------------
-- cleanup t_monitoring
-- select * from t_monitoring
----------------------------------------------------------------------------------------
DELETE FROM t_monitoring WHERE server_id IN (
	select DISTINCT m.server_id
	from	dbo.t_server s  
			RIGHT OUTER JOIN dbo.t_monitoring m ON s.server_id = m.server_id
	WHERE s.active = '0')
-------------------------------------------------------------------------------------------------
DELETE FROM t_monitoring where server_id IN (
	SELECT server_id from t_server where server_name = 'EWEBPROD1')
-------------------------------------------------------------------------------------------------
-- add records for # of CPU's, only needed for rrd graphs
--exec sp_ins_server_properties 'PSQLRPT21', '2'
--update t_server_properties set cpu_num = '4' where server_id = '632'

-- add new server to t_monitoring
Declare @server_id int
Declare @server_name varchar(64)

Set @server_name = 'STGSQLMET620'

Set @server_id = (select server_id from t_server where server_name = @server_name)
BEGIN
	if  exists ( select * from t_monitoring where server_id = @server_id ) 
		BEGIN
			print 'Exists in t_monitoring ' + @server_name 
			update t_monitoring SET 
				--CPU = '0', 
				--Memory = '0', 
				--DiskSpace = '1', 
				DSN = '1', 
				DCOM = '1', 
				Sched_Tasks = '1', 
				PerfMon = '0', 
				IISSites = '0',
				DRM = '1' 
			where server_id = @server_id --IN (select server_id from t_server where server_name = ( @server_name))
		END
	else
		BEGIN
			print 'Adding ' + @server_name + ' to the t_monitoring table' + char(13)
			insert into t_monitoring (server_id,LastUpdate) values (@server_id,GetDate())
			update t_monitoring set 
				--CPU = '1', 
				--Memory = '1', 
				--DiskSpace = '1', 
				DSN = '1', 
				DCOM = '1', 
				Sched_Tasks = '1', 
				PerfMon='1',
				IISSites = '0',
				DRM = '1'
			where server_id = @server_id --IN (select server_id from t_server where server_name IN ( @server_name))
		END
END
-------------------------------------------------------------------------------------------------
update t_monitoring set
	IISSites = '0',
	DRM = '0'
where server_id = ( select server_id from t_server where server_name = 'ISQLDEV512' )

update t_monitoring set
	--cpu = '0'
	--Memory = '0'
	PerfMon = '0',
	Sched_Tasks = '1',
	DCOM = '1',
	DRM = '1',
	DSN = '1'
	--DiskSpace = '1'
where server_id IN(select server_id from t_server where server_name like ('ISQLDEV512'))


-------------------------------------------------------------------------------------------------
-- only add for querying via scheduled scripts
Declare @server_id int
Declare @server_name varchar(64)

Set @server_name = 'PAPP15'

Set @server_id = (select server_id from t_server where server_name = @server_name)
BEGIN
	if  exists ( select * from t_monitoring where server_id = @server_id ) 
		BEGIN
			print 'Exists in t_monitoring ' + @server_name 
			update t_monitoring 
			set dsn = '1'
				, dcom = '1'
				, sched_tasks = '1' 
			where server_id = @server_id --IN (select server_id from t_server where server_name IN ( @server_name))
		END
	else
		BEGIN
			print 'Adding ' + @server_name + ' to the t_monitoring table' + char(13)
			insert into t_monitoring (server_id,LastUpdate) values (@server_id,GetDate())
			update t_monitoring 
			set dsn = '1'
				, dcom = '1'
				, sched_tasks = '1'
			where server_id = @server_id --IN (select server_id from t_server where server_name IN ( @server_name))
		END
END
-------------------------------------------------------------------------------------------------
-- disable all polling/monitoring for a server
update t_monitoring 
	set 
	perfmon = '0', 
	dsn = '1', 
	dcom = '1',
	sched_tasks = '1',
	IISSites = '0',
	drm = '1'
	where server_id IN (select server_id from t_server where server_name IN ('ISQLCBS611'))
-------------------------------------------------------------------------------------------------


select * from t_server where server_name like 'PVM400%'
select * from t_server_properties order by server_id desc
select * from t_monitoring order by monitor_id
delete from t_monitoring where monitor_id = 252
delete from t_monitoring where server_id = '1314'

-- search for duplicates
select count(*),server_id from t_monitoring
	group by server_id
	having count(*) > '1'
	order by server_id 

select server_id from t_server where server_name = 'PVM400'
select server_name from t_server where server_id = '863'
select * from t_monitoring where server_id = '1311'
delete from t_monitoring where server_id = '1311' and LastUpdate = '2010-12-22 13:15:04.430'

select * from t_server_properties where server_id = '880'

update t_server set environment_id = (select environment_id from t_environment where environment_name = 'DEMO')
	where server_name = 'STGWEBPA613'

update t_server_properties
	set cpu_num = '2' 
where server_id IN ( select server_id from t_server where server_name IN
('STGWEBPA610', 'STGWEBPA611', 'STGWEBPA612', 'STGWEBPA613', 'STGWEBSVC510', 'STGWEBSVC511'))




	
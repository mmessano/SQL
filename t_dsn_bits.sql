-- trim the DSN table by age(greaater than a day old by default)
select * from t_dsn where DATEDIFF(day, timestamp, GETDATE()) > 1
delete from t_dsn where DATEDIFF(day, timestamp, GETDATE()) > 1

-- NON-FUNCTIONAL
select  distinct s.server_name, d.dsn_name, rs.server_name AS remote_server, d.database_name
from	dbo.t_dsn d INNER JOIN
	dbo.t_server s  ON d.server_id = s.server_id INNER JOIN
	dbo.t_server rs  ON d.remote_server_id = rs.server_id

--- only display rows if the remote server is NOT in the database table ---
-- NON-FUNCTIONAL
where d.remote_server_id NOT in 
	(
	select server_id from t_db
	)
	--- and if the remote server is NOT a known alias ---
	and rs.server_name not in ( 'opsdb.dexma.com', 'opsdb.demo.dexma.com', 'impopsdb.dexma.com', '(local)', 'OPSFH.DEXMA.COM')
order by 3,1
GO



-- source server for a DSN
-- NON-FUNCTIONAL
select distinct s.server_name
from	dbo.t_server s INNER JOIN
	dbo.t_dsn d ON d.server_id = s.server_id
where s.server_name NOT in ( 'opsdb.dexma.com', 'opsdb.demo.dexma.com', 'impopsdb.dexma.com', '(local)', 'OPSFH.DEXMA.COM')
order by server_name


-- destination server for a DSN
-- NON-FUNCTIONAL
select distinct rs.server_name AS remote_server
from	dbo.t_server rs INNER JOIN
	dbo.t_dsn d ON d.remote_server_id = rs.server_id
where rs.server_name NOT in ( 'opsdb.dexma.com', 'opsdb.demo.dexma.com', 'impopsdb.dexma.com', '(local)', 'OPSFH.DEXMA.COM')
order by server_name


-- unique server list for DSN collection
-- NON-FUNCTIONAL
select s.server_name
from	dbo.t_server s INNER JOIN
	dbo.t_dsn d ON d.server_id = s.server_id 
where s.server_name NOT in ( 'opsdb.dexma.com', 'opsdb.demo.dexma.com', 'impopsdb.dexma.com', '(local)', 'OPSFH.DEXMA.COM')
union
select s.server_name
from	dbo.t_server s INNER JOIN
	dbo.t_dsn rs ON rs.remote_server_id = s.server_id
where s.server_name NOT in ( 'opsdb.dexma.com', 'opsdb.demo.dexma.com', 'impopsdb.dexma.com', '(local)', 'OPSFH.DEXMA.COM')
order by server_name



-- all DSN's with the server_name
-- NON-FUNCTIONAL
select s.server_name, d.dsn_name, rs.server_name AS remote_server, d.database_name
from	dbo.t_dsn d INNER JOIN
	dbo.t_server s  ON d.server_id = s.server_id INNER JOIN
	dbo.t_server rs  ON d.remote_server_id = rs.server_id
	--- and if the remote server is NOT a known alias ---
	and rs.server_name not in ( 'opsdb.dexma.com', 'opsdb.demo.dexma.com', 'impopsdb.dexma.com', '(local)', 'OPSFH.DEXMA.COM')
and (s.server_name = 'yarg' OR rs.server_name = 'yarg')
order by 1
GO


-- all DSN's where remote_server_name is not a DNS
-- tieing the remote_server_name to the server table excludes 
-- the DNS names since they do not exist in t_server
select s.server_name, d.dsn_name, rs.server_name AS remote_server, d.database_name, d.timestamp AS DSN_timestamp
from	dbo.t_dsn d INNER JOIN
	dbo.t_server s  ON d.server_id = s.server_id INNER JOIN
	dbo.t_server rs  ON d.remote_server_name = rs.server_name
	--- and if the remote server is NOT a known alias ---
where --(s.server_name = 'yarg' OR rs.server_name = 'yarg')
	rs.server_name not in ( 'opsdb.dexma.com', 'opsdb.demo.dexma.com', 'impopsdb.dexma.com', '(local)', 'OPSFH.DEXMA.COM')
and rs.server_name not like '%.dexma.com'
order by 1


-- this returns all records with server names
-- this does not tie the remote_server_name to t_server
select s.server_name, d.dsn_name, d.database_name, d.remote_server_name, d.timestamp AS DSN_timestamp
from	dbo.t_dsn d INNER JOIN
		dbo.t_server s  ON d.server_id = s.server_id --INNER JOIN
--where d.remote_server_name like 'Vela'
where d.remote_server_name not like '%.dexma.com'
order by 3,1


select * from t_dsn 
where remote_server_name not in (select distinct server_name from t_server where active = '1') 
and 
remote_server_name not like '%.dexma.com'






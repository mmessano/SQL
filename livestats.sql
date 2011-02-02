select * from t_livestats_cfg
select * from t_websites 

select distinct lc.login_id, lc.url, lc.logdir_1, lc.logdir_2
from	dbo.t_livestats_cfg lc  INNER JOIN
	dbo.t_websites w ON lc.url like w.ip_address


order by s.server_name   


select distinct ip_address from t_websites where ip_address = '192.168.96.44'


select * from t_websites  where ip_address like '192.168.96.26'
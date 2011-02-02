SELECT c.client_name, ds.machine_name, ds.database_name, ds.environment, ds.client_id
FROM 
	[ops].[dbo].[client_data_sources] ds inner join
	[ops].[dbo].[clients] c on c.client_id = ds.client_id
order by client_name
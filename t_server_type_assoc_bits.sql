SELECT * FROM t_server WHERE server_name = 'apollo'

SELECT * FROM dbo.t_server_type_assoc
WHERE server_id = ( SELECT server_id FROM t_server WHERE server_name = 'apollo' )

SELECT *
	FROM t_server s JOIN
	dbo.t_server_type_assoc sta ON s.server_id = sta.server_id JOIN
	dbo.t_server_type st ON st.[type_id] = sta.[type_id]
	WHERE sta.server_id = ( SELECT server_id FROM t_server WHERE server_name = 'xops4' )

DELETE FROM dbo.t_server_type_assoc 
WHERE server_id = '8'
AND [type_id] = '2'
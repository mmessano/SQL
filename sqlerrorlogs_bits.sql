-- find old servers
select distinct servername from SQLErrorLogs sel
INNER JOIN t_server s ON s.server_name = sel.servername
WHERE s.active  = '0'
-- remove old records
DELETE FROM SQLErrorLogs
	WHERE ServerName IN ('XVSS2')
	AND Message LIKE '%Changing the status to % for full-text catalog%'

select distinct ServerName from SQLErrorLogs

SELECT distinct RTRIM(LTRIM([server_name])) AS ServerName, sel.ServerName --ISNULL(sel.ServerName, RTRIM(LTRIM([server_name])))
FROM [Status].[dbo].[t_server] s
JOIN [t_server_type_assoc] sta 		on s.server_id 	= sta.server_id
JOIN [t_server_type] st 			on sta.type_id		= st.type_id
JOIN [t_monitoring] m			on s.server_id 	= m.server_id
FULL OUTER JOIN [SQLErrorLogs] sel on sel.servername = s.server_name
where active = 1
AND type_name = 'DB'
ORDER BY 1

/*
ServerName	Date	spid	Message	LastUpdate
OSQLUTIL12	2009-08-18 00:00:00.000	spid57	SQL Trace ID 2 was started by login "HOME_OFFICE\dexprosql".	2009-08-18 06:00:05.903
OSQLUTIL12	2009-08-18 00:00:00.000	spid57	SQL Trace ID 2 was started by login "HOME_OFFICE\dexprosql".	2009-08-18 10:22:42.697
*/
INSERT INTO SQLErrorLogs (ServerName, Date, spid, Message, LastUpdate) 
	VALUES ('STGSQLBO510', 2009-08-18, 'spid0', '', GetDate())
PSQLRPT10	NULL
PSQLRPT20	NULL
PSQLSMC10	NULL
PSQLSVC20	NULL
PSQLUSB11	NULL
QSQL510	NULL
QSQL511	NULL
STGSQL511	NULL
STGSQL512	NULL
	
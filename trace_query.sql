SELECT
   GT.loginname,
   MIN(GT.StartTime) AS FirstLogin,
   MAX(GT.StartTime) AS LastLogin
FROM
   sys.traces T CROSS Apply
   ::fn_trace_gettable(T.path, 5) GT
WHERE
   GT.loginname IS NOT NULL 
GROUP BY
   GT.LoginName
   
----------------------------------------------------
   
SELECT DISTINCT
   I.NTUserName,
   I.loginname,
   I.SessionLoginName,
   I.databasename,
   S.*
FROM
   sys.traces T CROSS Apply
   ::fn_trace_gettable(T.path, 5) I LEFT JOIN
   sys.syslogins S ON
       CONVERT(VARBINARY(MAX), I.loginsid) = S.sid    
WHERE
   S.sid IS NULL
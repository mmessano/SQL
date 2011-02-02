/*
  OSQLUTIL12
PSQLCBS10
PSQLCBS11
PSQLDIRECT20
PSQLMET10
PSQLOPS10
PSQLOPS11
PSQLPA12
PSQLPA20
PSQLPA21
PSQLPA22
PSQLPA23
PSQLPA24
PSQLRPT10
PSQLRPT20
PSQLSMC10
PSQLSVC10
PSQLSVC20
PSQLUSB11
XOPSMONITOR2
XSQLUTIL10
XSQLUTIL11
ZABIT
*/

--------------------------------------------------------------
-- Retrieve Operator(s)
--------------------------------------------------------------
SELECT	 @@SERVERNAME AS Server,
         name AS OperatorName,
         email_address,
         pager_address,
         netsend_address
  FROM msdb.dbo.sysoperators
  ORDER BY name
--------------------------------------------------------------  
--EXEC msdb.dbo.sp_help_operator
--------------------------------------------------------------
-- Retrieve Alerts
--------------------------------------------------------------
select id, Name from  msdb.dbo.sysalerts 
--select * from  msdb.dbo.sysalerts 
--------------------------------------------------------------
-- Drop operators
--------------------------------------------------------------
/*
IF  EXISTS (SELECT name FROM msdb.dbo.sysoperators WHERE name = N'mmessano')
EXEC msdb.dbo.sp_delete_operator @name=N'mmessano'
GO
--------------------------------------------------------------
IF  EXISTS (SELECT name FROM msdb.dbo.sysoperators WHERE name = N'rhaag')
EXEC msdb.dbo.sp_delete_operator @name=N'rhaag'
GO
--------------------------------------------------------------
IF  EXISTS (SELECT name FROM msdb.dbo.sysoperators WHERE name = N'sbrown')
EXEC msdb.dbo.sp_delete_operator @name=N'sbrown'
GO
*/
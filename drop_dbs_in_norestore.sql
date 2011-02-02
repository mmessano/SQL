USE [master]
GO

Declare @cmd varchar(3000)
Declare @DBNAME varchar(64)

--@dbs = 'MissionFed40,BayFederal,ColonialRLC,CUAnswers,CUCompanies,PATrain,SpaceCoast,Lockheed32,WrightPatt32,McDillAFB,Meriwest32,MidwestLoan32,Visions,Weokie,CornellFingerLake,SFFCU,GTE32,WesCom,Kinecta,Verity,ConstructionLoanCompany,FirstAmerican,AmericanAirlines,MembersMortgage,Travis40,MidwestFinancial,Purdue,Numerica'

DECLARE dbnames_cursor CURSOR FOR SELECT name FROM master.dbo.sysdatabases
	WHERE name not in ('dbamaint','master','model','msdb','OPS','PADemoDU','PAMonitoring','PAReporting','PASolutions','ScriptErrors','tempdb','WorkFlowManagementCurrent','WebServiceMaintenance','ViewStateManagementCurrent','TaskManagementCurrent','SecurityManagementCurrent','ReportManagementCurrent','Prod_Logs','PASCAdmin','LoanWizardManagementCurrent','FormsManagementCurrent','DynamicScreenManagementCurrent','DocumentManagementCurrent','DirStructure','DataFieldManagementCurrent','ConditionsManagementCurrent','CacheManagementCurrent','AuditFuture','AuditCurrent')
	and (select DATABASEPROPERTYEX(name,'STATUS')) = 'Restoring'

OPEN dbnames_cursor

FETCH NEXT FROM dbnames_cursor INTO @DBNAME
WHILE (@@fetch_status <> -1)



BEGIN

print @DBNAME

Select @cmd = 'IF  EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = N''' + @DBNAME + ''')' +
				' DROP DATABASE ' + @DBNAME

print @cmd

exec(@cmd)





FETCH NEXT FROM dbnames_cursor INTO @DBNAME
END

CLOSE dbnames_cursor
DEALLOCATE dbnames_cursor




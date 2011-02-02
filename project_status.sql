SELECT [PDID]
      ,[PSID]
      ,[TechID]
      ,[PDComment]
      ,[HoursWorked]
      ,[MinutesWorked]
      ,[PDLastUpdate]
  FROM [Status].[dbo].[ProjectDetail]
  order by pdlastupdate desc
GO

update [Status].[dbo].[ProjectDetail]
set pdlastupdate = '2011-01-21 16:28:00'
where pdlastupdate = '2011-01-23 23:31:00'

--5849	2533	4	Migrated to Prod.	30	0	2010-11-15 20:43:00
--update [Status].[dbo].[ProjectDetail]
--SET HoursWorked = '0', MinutesWorked = '30'
--WHERE PDID = '5849' AND PSID = '2533'

SELECT [PSID]
      ,[TechID]
      ,[PID]
      ,[PSTitle]
      ,[PSTicketNumber]
      ,[PSTicketCat]
      ,[PSPriority]
      ,[PSStatusID]
      ,[PSActive]
      ,[PSTargetDate]
      ,[PSLastUpdate]
  FROM [Status].[dbo].[ProjectStatus]
  order by pslastupdate desc
GO



SELECT [PID]
      ,[PTicketNumber]
      ,[PTicketTitle]
      ,[PTargetDate]
      ,[PLastUpdate]
      ,[PActive]
  FROM [Status].[dbo].[Project]
  order by [PLastUpdate] desc
GO


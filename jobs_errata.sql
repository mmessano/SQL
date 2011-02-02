
msdb.dbo.sp_help_job


msdb.dbo.sp_get_composite_job_info

SELECT * FROM msdb.dbo.sysjobs WHERE enabled <> 0 ORDER BY name



exec master.dbo.xp_sqlagent_enum_jobs 1,garbage
exec msdb.dbo.sp_help_maintenance_plan
sp_helprotect

sp_MSForEachDb

--------------------------------------------------------------
create table #enum_job ( 
Job_ID uniqueidentifier, 
Last_Run_Date int, 
Last_Run_Time int, 
Next_Run_Date int, 
Next_Run_Time int, 
Next_Run_Schedule_ID int, 
Requested_To_Run int, 
Request_Source int, 
Request_Source_ID varchar(100), 
Running int, 
Current_Step int, 
Current_Retry_Attempt int, 
State int 
)       
insert into #enum_job 
     exec master.dbo.xp_sqlagent_enum_jobs 1,garbage  
select * from #enum_job
drop table #enum_job

-----------------------------------------------------------------
create table #enum_job ( 
Origin_Server varchar (64), 
Name varchar (), 
Last_Run_Time int, 
Next_Run_Date int, 
Next_Run_Time int, 
Next_Run_Schedule_ID int, 
Requested_To_Run int, 
Request_Source int, 
Request_Source_ID varchar(100), 
Running int, 
Current_Step int, 
Current_Retry_Attempt int, 
State int 
)   

-----------------------------------------------------------------

SELECT b.name as job_name, c.Schedule,c.next_run_time, step_name, subsystem, command, database_name 
 FROM msdb..sysjobsteps a
INNER JOIN (SELECT name,job_id 
                FROM msdb..sysjobs 
                WHERE enabled = 1) b ON a.job_id =b.job_id 
INNER JOIN (SELECT job_id
                  ,(CASE WHEN freq_type = 4 THEN 'Daily' 
                         WHEN freq_type =16 THEN 'Monthly'
                         WHEN freq_type =8  THEN 'Weekly' 
                         END )as Schedule
                  ,left(right('000000'+convert(varchar,next_run_time),6),4) as next_run_time
              FROM msdb..sysjobschedules ) c ON a.job_id =c.job_id
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------

-- randy
IF OBJECT_ID('Jobs_Report') IS NOT NULL
   BEGIN
      TRUNCATE TABLE Jobs_Report
   END
ELSE
   BEGIN
CREATE TABLE [dbo].[Jobs_Report](
	[ServerName] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Schedule] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[JobName] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
--	[Command] [varchar](3200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[LastRunDate] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Last_Run_Outcome] [int] NULL,
	[NextRunDate] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Duration] [int] NULL,
	[timestamp] [datetime] NOT NULL CONSTRAINT [DF_Jobs_Report_timestamp]  DEFAULT (getdate())
) ON [PRIMARY]
	END

--insert Jobs_Report (ServerName,Schedule,JobName,Command,LastRunDate,Last_Run_Outcome,NextRunDate,Duration)
insert Jobs_Report (ServerName,Schedule,JobName,LastRunDate,Last_Run_Outcome,NextRunDate,Duration)
SELECT @@SERVERNAME, 
CASE WHEN freq_type = 4 THEN 'Daily' 
     WHEN freq_type =16 THEN 'Monthly'
     WHEN freq_type =8  THEN 'Weekly' 
     END as Schedule,
sj.name as JobName,
--steps.command AS Command,
SUBSTRING(CAST(sjs.last_run_date AS CHAR(8)),5,2) + '/' + 
	RIGHT(CAST(sjs.last_run_date AS CHAR(8)),2) + '/' + 
	LEFT(CAST(sjs.last_run_date AS CHAR(8)),4)as LastRunDate,
sjs.last_run_outcome,
SUBSTRING(CAST(sjsch.next_run_date AS CHAR(8)),5,2) + '/' + 
	RIGHT(CAST(sjsch.next_run_date AS CHAR(8)),2) + '/' + 
	LEFT(CAST(sjsch.next_run_date AS CHAR(8)),4) as NextRunDate,
sjs.last_run_duration as "Duration (sec)"
FROM msdb.dbo.sysjobs sj
JOIN msdb.dbo.sysjobservers sjs on sj.job_id = sjs.job_id
JOIN msdb.dbo.sysjobschedules sjsch on sj.job_id = sjsch.job_id AND (sjsch.enabled <> 0 AND sj.enabled <> 0)
--INNER JOIN (select job_id, command from msdb.dbo.sysjobsteps) steps ON steps.job_id = sj.job_id
order by 1


select * from Jobs_Report

--------------------------------------------------------------------------------
--Convert Integer date to regular datetime
SUBSTRING(CAST(sjh.run_date AS CHAR(8)),5,2) + '/' + 
RIGHT(CAST(sjh.run_date AS CHAR(8)),2) + '/' + 
LEFT(CAST(sjh.run_date AS CHAR(8)),4)
--------------------------------------------------------------------------------
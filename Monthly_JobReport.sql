/*=========================================================================
Title:               Monthly SQL Server Agent Jobs report
Script               C:\DBA\SCRIPTS\sp_monthly_jobreport.sql 

Purpose:             Monthly SQL Server Agent Jobs report  
					 output to be copied to excel files
Author:              Amit Jethva
Date Created:        2003-10-28
Date Last Updated: 
By: 
Note: 
=========================================================================*/

--create proc sp_monthly_jobreport ( @year int , @month tinyint )
--as
DECLARE @Year int,
		@Month tinyint

SET @Year = '2011'
SET @Month = '4'

	select  j.name as [JobName], substring( convert(varchar, run_date )  , 7, 2) as  [Day] ,
	max( case run_status  when 1 then 'S' when 0 then 'F' when 2 then 'R' when 3 then 'C' else 'P' end  ) as [Status]
	into #jobs
	from msdb..sysjobhistory h , msdb..sysjobs j 
	where j.enabled = 1
	and   j.job_id  = h.job_id 
	and   run_date between ( ( @year * 10000 ) + ( @month * 100 ) + 1 ) and 
	( ( @year * 10000 ) + ( @month * 100 ) + 32 )
	and h.step_id = 0
	group by j.name , substring( convert(varchar, run_date )  , 7, 2)

	

	select JobName , 
	max(case Day when '01' then Status  else '' end )  As [01],
	max(case Day when '02' then Status  else '' end )  As [02],
	max(case Day when '03' then Status  else '' end )  As [03],
	max(case Day when '04' then Status  else '' end )  As [04],
	max(case Day when '05' then Status  else '' end )  As [05],
	max(case Day when '06' then Status  else '' end )  As [06],
	max(case Day when '07' then Status  else '' end )  As [07],
	max(case Day when '08' then Status  else '' end )  As [08],
	max(case Day when '09' then Status  else '' end )  As [09],
	max(case Day when '10' then Status  else '' end )  As [10],
	max(case Day when '11' then Status  else '' end )  As [11],
	max(case Day when '12' then Status  else '' end )  As [12],
	max(case Day when '13' then Status  else '' end )  As [13],
	max(case Day when '14' then Status  else '' end )  As [14],
	max(case Day when '15' then Status  else '' end )  As [15],
	max(case Day when '16' then Status  else '' end )  As [16],
	max(case Day when '17' then Status  else '' end )  As [17],
	max(case Day when '18' then Status  else '' end )  As [18],
	max(case Day when '19' then Status  else '' end )  As [19],
	max(case Day when '20' then Status  else '' end )  As [20],
	max(case Day when '21' then Status  else '' end )  As [21],
	max(case Day when '22' then Status  else '' end )  As [22],
	max(case Day when '23' then Status  else '' end )  As [23],
	max(case Day when '24' then Status  else '' end )  As [24],
	max(case Day when '25' then Status  else '' end )  As [25],
	max(case Day when '26' then Status  else '' end )  As [26],
	max(case Day when '27' then Status  else '' end )  As [27],
	max(case Day when '28' then Status  else '' end )  As [28],
	max(case Day when '29' then Status  else '' end )  As [29],
	max(case Day when '30' then Status  else '' end )  As [30],
	max(case Day when '31' then Status  else '' end )  As [31]
	from #jobs
	group by JobName

	drop table #jobs
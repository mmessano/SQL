declare @stem varchar(128)
declare @startdate datetime
declare @enddate datetime

Set @stem = '/WebUI/Common/Ajax/AjaxService.asmx'
Set @startdate = '3/20/2008'
Set @enddate = '3/26/2008'

SELECT distinct server, iisuser, csUriStem, cast(avg(((Avg * Hits)-(Min + Max))/(Hits - 2)) as varchar(20)) AS AvgTime, cast(LastUpdate as varchar(20)) 
FROM IISLog_metrics WHERE csUriStem = @stem 
and LastUpdate BETWEEN @startdate 
AND @enddate 
GROUP BY server, iisuser, csUriStem, LastUpdate 
--order by LastUpdate
order by server, iisuser, cast(LastUpdate as varchar(20))

/*
select top 10 * from IISLog_metrics
*/
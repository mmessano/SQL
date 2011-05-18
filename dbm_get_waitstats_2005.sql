use dbamaint

if exists (select * from sys.objects where object_id = object_id(N'[dbo].[dbm_get_waitstats_2005]') and OBJECTPROPERTY(object_id, N'IsProcedure') = 1)
	drop procedure [dbo].[get_waitstats_2005]
GO
CREATE proc [dbo].[dbm_get_waitstats_2005] (@report_format varchar(20)='all', @report_order varchar(20)='resource')
as

-- this proc will create waitstats report listing wait types by percentage.  
-- 	(1) total wait time is the sum of resource & signal waits, @report_format='all' reports resource & signal
--	(2) Basics of execution model (simplified)
--	    a. spid is running then needs unavailable resource, moves to resource wait list at time T0
--	    b. a signal indicates resource available, spid moves to runnable queue at time T1
--	    c. spid awaits running status until T2 as cpu works its way through runnable queue in order of arrival
--	(3) resource wait time is the actual time waiting for the resource to be available, T1-T0
--	(4) signal wait time is the time it takes from the point the resource is available (T1)
--	      to the point in which the process is running again at T2.  Thus, signal waits are T2-T1
--	(5) Key questions: Are Resource and Signal time significant?
--	    a. Highest waits indicate the bottleneck you need to solve for scalability
--	    b. Generally if you have LOW% SIGNAL WAITS, the CPU is handling the workload e.g. spids spend move through runnable queue quickly
--	    c. HIGH % SIGNAL WAITS indicates CPU can't keep up, significant time for spids to move up the runnable queue to reach running status
-- 	(6) This proc can be run when track_waitstats is executing
-- Revision 4/19/2005
-- (1) add computation for CPU Resource Waits = Sum(signal waits / total waits)
-- (2) add @report_order parm to allow sorting by resource, signal or total waits
set nocount on

declare @now datetime, @totalwait numeric(20,1), @totalsignalwait numeric(20,1), @totalresourcewait numeric(20,1)
	,@endtime datetime,@begintime datetime
	,@hr int, @min int, @sec int

if not exists (select 1 from sysobjects where id = object_id ( N'[dbo].[waitstats]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
begin
		raiserror('Error [dbo].[waitstats] table does not exist', 16, 1) with nowait
		return
end
if lower(@report_format) not in ('all','detail','simple')
	begin
		raiserror ('@report_format must be either ''all'',''detail'', or ''simple''',16,1) with nowait
		return
	end
if lower(@report_order) not in ('resource','signal','total')
	begin
		raiserror ('@report_order must be either ''resource'', ''signal'', or ''total''',16,1) with nowait
		return
	end
if lower(@report_format) = 'simple' and lower(@report_order) <> 'total'
	begin
		raiserror ('@report_format is simple so order defaults to ''total''',16,1) with nowait
		select @report_order = 'total'
	end
select  @now=max(now),@begintime=min(now),@endtime=max(now)
from [dbo].[waitstats] where [wait_type] = 'Total'

--- subtract waitfor, sleep, and resource_queue from Total
select @totalwait = sum([wait_time_ms]) + 1, @totalsignalwait = sum([signal_wait_time_ms]) + 1 from waitstats 
--where [wait_type] not in ('WAITFOR','SLEEP','RESOURCE_QUEUE', 'Total', '***total***') and now = @now
where [wait_type] not in ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK','SLEEP_SYSTEMTASK','Total','WAITFOR', '***total***') and now = @now
select @totalresourcewait = 1 + @totalwait - @totalsignalwait
-- insert adjusted totals, rank by percentage descending
delete waitstats where [wait_type] = '***total***' and now = @now
insert into waitstats select '***total***',0,@totalwait,0,@totalsignalwait,@now 
select 'start time'=@begintime,'end time'=@endtime
		,'duration (hh:mm:ss:ms)'=convert(varchar(50),@endtime-@begintime,14)
		,'report format'=@report_format, 'report order'=@report_order
if lower(@report_format) in ('all','detail') 
	begin
----- format=detail, column order is resource, signal, total.  order by resource desc
	if lower(@report_order) = 'resource'
	select [wait_type],[waiting_tasks_count]
		,'Resource wt (T1-T0)'=[wait_time_ms]-[signal_wait_time_ms]
		,'res_wt_%'=cast (100*([wait_time_ms] - [signal_wait_time_ms]) /@totalresourcewait as numeric(20,1))
		,'Signal wt (T2-T1)'=[signal_wait_time_ms]
		,'sig_wt_%'=cast (100*[signal_wait_time_ms]/@totalsignalwait as numeric(20,1))
		,'Total wt (T2-T0)'=[wait_time_ms]
		,'wt_%'=cast (100*[wait_time_ms]/@totalwait as numeric(20,1))
	from waitstats 
	where [wait_type] not in ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK','SLEEP_SYSTEMTASK','Total','WAITFOR')
	and now = @now
	order by 'res_wt_%' desc
----- format=detail, column order signal, resource, total.  order by signal desc
	if lower(@report_order) = 'signal'
	select [wait_type],[waiting_tasks_count]
		,'Signal wt (T2-T1)'=[signal_wait_time_ms]
		,'sig_wt_%'=cast (100*[signal_wait_time_ms]/@totalsignalwait as numeric(20,1))
		,'Resource wt (T1-T0)'=[wait_time_ms]-[signal_wait_time_ms]
		,'res_wt_%'=cast (100*([wait_time_ms] - [signal_wait_time_ms]) /@totalresourcewait as numeric(20,1))
		,'Total wt (T2-T0)'=[wait_time_ms]
		,'wt_%'=cast (100*[wait_time_ms]/@totalwait as numeric(20,1))
	from waitstats 
	where [wait_type] not in ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK','SLEEP_SYSTEMTASK','Total','WAITFOR')
	and now = @now
	order by 'sig_wt_%' desc
----- format=detail, column order total, resource, signal.  order by total desc
	if lower(@report_order) = 'total'
	select [wait_type],[waiting_tasks_count]
		,'Total wt (T2-T0)'=[wait_time_ms]
		,'wt_%'=cast (100*[wait_time_ms]/@totalwait as numeric(20,1))
		,'Resource wt (T1-T0)'=[wait_time_ms]-[signal_wait_time_ms]
		,'res_wt_%'=cast (100*([wait_time_ms] - [signal_wait_time_ms]) /@totalresourcewait as numeric(20,1))
		,'Signal wt (T2-T1)'=[signal_wait_time_ms]
		,'sig_wt_%'=cast (100*[signal_wait_time_ms]/@totalsignalwait as numeric(20,1))
	from waitstats 
	where [wait_type] not in ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK','SLEEP_SYSTEMTASK','Total','WAITFOR')
	and now = @now
	order by 'wt_%' desc
end
else
---- simple format, total waits only
	select [wait_type],[wait_time_ms]
			,percentage=cast (100*[wait_time_ms]/@totalwait as numeric(20,1))
	from waitstats 
	where [wait_type] not in ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK','SLEEP_SYSTEMTASK','Total','WAITFOR')
	and now = @now
	order by percentage desc
---- compute cpu resource waits
select 'total waits'=[wait_time_ms],'total signal=CPU waits'=[signal_wait_time_ms]
	,'CPU resource waits % = signal waits / total waits'=cast (100*[signal_wait_time_ms]/[wait_time_ms] as numeric(20,1)), now
from [dbo].[waitstats]
where [wait_type] = '***total***'
order by now
GO
exec [dbo].[get_waitstats_2005] @report_format='detail',@report_order='resource'
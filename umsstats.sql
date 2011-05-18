set nocount on
declare @statistics varchar(32)
declare @value float
declare @Scheduler_ID int
declare @Online int
declare @Num_tasks int
declare @Num_runnable int
declare @Num_workers int
declare @Active_workers int
declare @Work_queued int
declare @cntxt_switches float
declare @cntxt_switches_idle float
declare @preemptive_switches float

create table #umsstats
(
	[Statistics] varchar(32) not null,
	[Value] float not null
)
create table #umsstats2
(
	[Scheduler_ID] int not null,
	[Online] int not null,
	[Num_tasks] int not null,
	[Num_runnable] int not null,
	[Num_workers] int not null,
	[Active_workers] int not null,
	[Work_queued] int not null,
	[Cntxt_switches] float not null,
	[Cntxt_switches_idle] float not null,
	[Preemptive_switches] float not null,
	[Datetime] datetime default getdate()
)
insert into #umsstats exec('dbcc sqlperf(umsstats) with no_infomsgs')
declare umsstats_cursor cursor for select * from #umsstats
open umsstats_cursor
fetch next from umsstats_cursor into @statistics,@value
while @@fetch_status = 0
begin
	if ltrim(rtrim(@statistics)) = 'Scheduler ID' 	set @scheduler_id = @value
	if ltrim(rtrim(@statistics)) = 'online' 		set @online = @value
	if ltrim(rtrim(@statistics)) = 'num tasks' 		set @num_tasks = @value
	if ltrim(rtrim(@statistics)) = 'num runnable' 	set @num_runnable = @value
	if ltrim(rtrim(@statistics)) = 'num workers' 	set @num_workers = @value
	if ltrim(rtrim(@statistics)) = 'active workers' set @active_workers = @value
	if ltrim(rtrim(@statistics)) = 'work queued' 	set @work_queued = @value
	if ltrim(rtrim(@statistics)) = 'cntxt switches' set @cntxt_switches = @value
	if ltrim(rtrim(@statistics)) = 'cntxt switches(idle)' set @cntxt_switches_idle = @value
	if ltrim(rtrim(@statistics)) = 'preemptive switches' 
	begin
		set @preemptive_switches = @value
		insert into #umsstats2(Scheduler_ID,[Online],Num_tasks,Num_runnable,Num_workers,
			Active_workers,Work_queued,cntxt_switches,cntxt_switches_idle,preemptive_switches)
			values(@Scheduler_ID,@Online,@Num_tasks,@Num_runnable,@Num_workers,
			@Active_workers,@Work_queued,@cntxt_switches,@cntxt_switches_idle,@preemptive_switches)
	end
	fetch next from umsstats_cursor into @statistics,@value
end
select * from #umsstats2

drop table #umsstats
drop table #umsstats2
close umsstats_cursor
deallocate umsstats_cursor

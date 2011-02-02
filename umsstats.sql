set nocount on
declare @statistics varchar(32)
declare @value float
declare @Scheduler_ID int
declare @Num_users int
declare @Num_runnable int
declare @Num_workers int
declare @Idle_workers int
declare @Work_queued int
declare @cntxt_switches float
declare @cntxt_switches_idle float

create table #umsstats
(
	[Statistics] varchar(32) not null,
	[Value] float not null
)
create table #umsstats2
(
	[Scheduler_ID] int not null,
	[Num_users] int not null,
	[Num_runnable] int not null,
	[Num_workers] int not null,
	[Idle_workers] int not null,
	[Work_queued] int not null,
	[Cntxt_switches] float not null,
	[Cntxt_switches_idle] float not null,
	[Datetime] datetime default getdate()
)
insert into #umsstats exec('dbcc sqlperf(umsstats) with tableresults, no_infomsgs')
declare umsstats_cursor cursor for select * from #umsstats
open umsstats_cursor
fetch next from umsstats_cursor into @statistics,@value
while @@fetch_status = 0
begin
	if ltrim(rtrim(@statistics)) = 'Scheduler ID' 	set @scheduler_id = @value
	if ltrim(rtrim(@statistics)) = 'num users' 	set @num_users = @value
	if ltrim(rtrim(@statistics)) = 'num runnable' 	set @num_runnable = @value
	if ltrim(rtrim(@statistics)) = 'num workers' 	set @num_workers = @value
	if ltrim(rtrim(@statistics)) = 'idle workers' 	set @idle_workers = @value
	if ltrim(rtrim(@statistics)) = 'work queued' 	set @work_queued = @value
	if ltrim(rtrim(@statistics)) = 'cntxt switches' set @cntxt_switches = @value
	if ltrim(rtrim(@statistics)) = 'cntxt switches(idle)'
	begin
		set @cntxt_switches_idle = @value
		insert into #umsstats2(Scheduler_ID,Num_users,Num_runnable,Num_workers,
			Idle_workers,Work_queued,cntxt_switches,cntxt_switches_idle)
			values(@Scheduler_ID,@Num_users,@Num_runnable,@Num_workers,
			@Idle_workers,@Work_queued,@cntxt_switches,@cntxt_switches_idle)
	end


	fetch next from umsstats_cursor into @statistics,@value
end
select * from #umsstats2

drop table #umsstats
drop table #umsstats2
close umsstats_cursor
deallocate umsstats_cursor


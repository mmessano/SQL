/*
Statistic of SQL-Server - System parameters for dynamic collection.

@@cpu_busy/1000 - Returns the time in seconds that the CPU has spent working since SQL Server was last started.
@@io_busy/1000  - Returns the time in seconds that SQL Server has spent performing 
                  input and output operations since it was last started.
@@idle/1000     - Returns the time in seconds that SQL Server has been idle since last started.
@@pack_received - Returns the number of input packets read from the network by SQL Server since last started.
@@pack_sent     - Returns the number of output packets written to the network by SQL Server since last started.
@@packet_errors - Returns the number of network packet errors that have occurred on
                  SQL Server connections since SQL Server was last started.
@@connections   - Returns the number of connections, or attempted connections, since SQL Server was last started.
@@total_read    - Returns the number of disk reads (not cache reads) by SQL Server since last started.
@@total_write   - Returns the number of disk writes by SQL Server since last started.
@@total_errors  - Returns the number of disk read/write errors encountered by SQL Server since last started. 
*/
/*
Daily Version.

Output - Table ServerStatistics. A Table include Row per run per Procedure,except Saturday.
Sunday statistic include Saturday.
In the table ServerStatistics_Prior save SQL Server statistic since last started. 
Delete history statistic rows - more than one year. 
Return Code: 1 - BAD, 0 - GOOD.

Author  - Mushkatin Vadim,DBA,Israel.
Created - 09/03/2003. 
*/

IF EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = 'dbm_ServerStatsDaily')
   DROP  Procedure  dbm_ServerStatsDaily
GO

Create PROCEDURE dbm_ServerStatsDaily  ( @BIT_DELETE_RESULTS BIT = 0 )
AS

SET NOCOUNT ON

Declare @weekday 			INT
		, @count 		INT
		, @sql_started		datetime

Declare @id_prior 			INT
	, @sampletime_prior		datetime
	, @cpu_busy_prior 		INT
        , @io_busy_prior 		INT
        , @idle_prior 			INT
        , @pack_received_prior 		INT
        , @pack_send_prior 		INT
        , @packed_errors_prior 		INT
        , @connections_prior 		INT
        , @total_read_prior 		INT
        , @total_write_prior 		INT
        , @total_errors_prior 		INT

------------------------------------------ 
Set @sql_started   = ( select login_time  from master..sysprocesses where spid = 1 )
Set @weekday = (select DATEPART ( weekday , getdate() ))
IF  @weekday  <>  7 
BEGIN
------------------------------------------
   IF OBJECT_ID('ServerStatistics_Prior') IS  NULL      
      CREATE TABLE  ServerStatistics_Prior (
          [ID]          INT IDENTITY,
          SQL_Started   datetime,
          SAMPLETIME    datetime,
          cpu_busy      INT,
          io_busy       INT,
          idle          INT,
          pack_received INT,
          pack_send     INT,
          packed_errors INT,
          connections   INT,
          total_read    INT,
          total_write   INT,
          total_errors  INT )
    
   Set @count = ( select count(*) from ServerStatistics_Prior )
   If @count = 0
   Begin
      TRUNCATE TABLE ServerStatistics_Prior
      INSERT INTO ServerStatistics_Prior  
      select @sql_started,getdate(),@@cpu_busy/1000,@@io_busy/1000,  @@idle /1000,
             @@pack_received  ,@@pack_sent, @@packet_errors  , @@connections , @@total_read ,
             @@total_write , @@total_errors 
   End

   IF OBJECT_ID('ServerStatistics') IS NOT NULL
      Begin
         IF @BIT_DELETE_RESULTS = 1     --Warning !!!
            TRUNCATE TABLE ServerStatistics
   End  
   ELSE  
      CREATE TABLE  ServerStatistics (
          [ID]          INT IDENTITY,
          LastRunTIME   datetime,
          SAMPLETIME    datetime,
          cpu_busy      INT,
          io_busy       INT,
          idle          INT,
          pack_received INT,
          pack_send     INT,
          packed_errors INT,
          connections   INT,
          total_read    INT,
          total_write   INT,
          total_errors  INT )

   If exists ( select sampletime  from ServerStatistics_Prior   where id = 1 )
      Set @sampletime_prior = (select sampletime  from ServerStatistics_Prior 
                                                  where id = 1)
   Else  Begin
      Print 'Data not found in table ServerStatistics_Prior.' 
      Return 1
   End

   If   @sql_started <= @sampletime_prior  
   Begin
      Declare c_table_prior cursor for 
	 select cpu_busy, io_busy, idle, pack_received, pack_send,packed_errors,
                connections, total_read, total_write, total_errors
         FROM ServerStatistics_Prior
         where [id] = 1

       open c_table_prior 
       fetch next from c_table_prior 
          into @cpu_busy_prior,@io_busy_prior,@idle_prior,@pack_received_prior,@pack_send_prior,
               @packed_errors_prior, @connections_prior, @total_read_prior, 
               @total_write_prior, @total_errors_prior 
     
       INSERT INTO ServerStatistics
          select @sampletime_prior,getdate(),@@cpu_busy/1000 - @cpu_busy_prior,@@io_busy/1000 - @io_busy_prior, 
                 @@idle/1000 - @idle_prior,@@pack_received - @pack_received_prior ,
                 @@pack_sent - @pack_send_prior , @@packet_errors - @packed_errors_prior ,
                 @@connections - @connections_prior , @@total_read - @total_read_prior,
                 @@total_write - @total_write_prior, @@total_errors - @total_errors_prior 
         
       close c_table_prior
       deallocate c_table_prior       
   END
   Else Begin
      Print 'Daily statistic Row not inserted because of REBOOT server.' 
      Print 'SQL Server started - ' + cast(@sql_started as char(17))
   End 
--since SQL Server last started   
   Truncate table ServerStatistics_Prior
   INSERT INTO ServerStatistics_Prior
      select @sql_started,getdate(),@@cpu_busy/1000 ,@@io_busy/1000, @@idle/1000 ,@@pack_received ,@@pack_sent ,
             @@packet_errors ,@@connections , @@total_read,@@total_write, @@total_errors 

END  --Close First IF

--Delete history statistic rows (more than one year)
Delete 
   From ServerStatistics
   Where SAMPLETIME < ( getdate() - 365 )  

Return 0
GO



-- remove duplicates from SQLErrorLogs table
alter table SQLErrorLogs
  add seq_num int identity
go
delete from a
from SQLErrorLogs a join
     (select ServerName, Date, spid, Message, max(seq_num) AS max_seq_num 
     	     from SQLErrorLogs
             group by ServerName, Date, spid, Message
             having count(*) > 1) b
      on a.ServerName = b.ServerName and
         a.Date = b.Date and
         a.spid = b.spid and
         a.Message = b.Message and
         a.seq_num < b.max_seq_num
go 
alter table SQLErrorLogs
 drop column seq_num
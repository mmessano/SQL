Declare @table varchar(128)
Declare @cmd varchar(256)

declare tablenames cursor for
	SELECT name from sys.tables order by 1

OPEN tablenames
FETCH NEXT FROM tablenames INTO @table
while @@fetch_status=0
begin

select @cmd = 'DBCC CHECKTABLE(' + @table + ')'
print @cmd
--exec @cmd

FETCH NEXT FROM tablenames INTO @table
END

CLOSE tablenames
DEALLOCATE tablenames


-------------------------------------------------

select OBJECT_NAME(1157579162)

DBCC CHECKTABLE(loan_price_history)
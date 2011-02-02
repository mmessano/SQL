select * from 
(
	select convert(char(10), Err_time, 101) as Day, datepart(hh, Err_time) as Hour, count(*) as [Occurences]
	from scripterrors
	where err_description like '%timeout expired%'
	group by convert(char(10), Err_time, 101), datepart(hh, Err_time)
) AS DerivedTable
where Occurences > 25
order by 1

select * from 
(
	select convert(char(10), Err_time, 101) as Day, substring(cast(max(err_time) AS varchar), 13, 5) as Hour, count(*) as [Occurences]
	from scripterrors
	where err_description like '%timeout expired%'
	group by convert(char(10), Err_time, 101)--, substring(cast(max(err_time) AS varchar), 13, 5)
) AS DerivedTable
where Occurences > 25
order by 1,2

select max(err_time) from scripterrors
select convert(char(10), max(err_time), 101) from scripterrors

select  substring(cast(max(err_time) AS varchar), 13, 5) from scripterrors
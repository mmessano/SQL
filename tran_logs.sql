select * from sql_spacestats where server_name IN ('Folsom', 'bellatrix') and report_date > '4/13/2007' order by 3, 11




dbcc sqlperf(logspace)

sp_helpfile
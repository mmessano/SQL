--****************************************************************************************
-- List index information for all databases
--****************************************************************************************
-- Version: 	1.0
-- Author:	Theo Ekelmans 
-- Email:	theo@ekelmans.com
-- Date:	2005-10-07
--****************************************************************************************

use master 

DECLARE @db_name varchar(128)
DECLARE @DbID int
DECLARE @sql_string nvarchar(4000)

set nocount on

CREATE TABLE [#tblHistoryIndex] (
	[DbName] [varchar] (128) NOT NULL ,
	[TableName] [varchar] (128) NOT NULL ,
	[IndexName] [varchar] (128) NOT NULL ,
	[Indexid] [int] NOT NULL ,
	[Primary] [int] NULL ,
	[Clustered] [int] NULL ,
	[Unique] [int] NULL ,
	[IgnoreDupKey] [int] NULL ,
	[IgnoreDupRow] [int] NULL ,
	[NoRecompute] [int] NULL ,
	[FillFactor] [int] NULL ,
	[EstRowCount] [bigint] NULL ,
	[ReservedKB] [bigint] NULL ,
	[UsedKB] [bigint] NULL ,
	[KeyNumber] [int] NULL ,
	[ColumnName] [varchar] (128) NULL ,
	[DataType] [varchar] (128) NULL ,
	[Precision] [int] NULL ,
	[Scale] [int] NULL ,
	[IsComputed] [int] NULL ,
	[IsNullable] [int] NULL ,
	[Collation] [varchar] (128) NULL ) 

declare db_cursor cursor forward_only for
	
	SELECT 	name, DbID 
	FROM 	master..sysdatabases
	WHERE 	name NOT IN ('northwind', 'pubs')
	AND 	(status & 32) <> 32  	   --loading.
	AND		(status & 64) <> 64 	   --pre recovery.
	AND		(status & 128) <> 128      --recovering.
	AND		(status & 256) <> 256      --not recovered.
	AND		(status & 512) <> 512 	   --Offline
	AND		(status & 32768) <> 32768  --emergency mode.
	AND 	DbID > 4

open db_cursor

fetch next from db_cursor into @db_name, @DbID


while @@FETCH_STATUS = 0
begin

	set @sql_string = ''
	+'	Insert into #tblHistoryIndex '
	+'	select 	''' + @db_name + ''' as ''DbName'',  '
	+'	       	o.name as ''TableName'',  '
	+'		i.name as ''IndexName'',  '
	+'		i.indid as ''Indexid'',  '
	+'		CASE WHEN (i.status & 0x800)     = 0 THEN 0 ELSE 1 END AS ''Primary'',   '
	+'		CASE WHEN (i.status & 0x10)      = 0 THEN 0 ELSE 1 END AS ''Clustered'',   '
	+'		CASE WHEN (i.status & 0x2)       = 0 THEN 0 ELSE 1 END AS ''Unique'',   '
	+'		CASE WHEN (i.status & 0x1)       = 0 THEN 0 ELSE 1 END AS ''IgnoreDupKey'',   '
	+'		CASE WHEN (i.status & 0x4)       = 0 THEN 0 ELSE 1 END AS ''IgnoreDupRow'',   '
	+'		CASE WHEN (i.status & 0x1000000) = 0 THEN 0 ELSE 1 END AS ''NoRecompute'',   '
	+'		i.OrigFillFactor AS ''FillFactor'',  '
	+'		i.rowcnt as ''EstRowCount'',  '
	+'		i.reserved * cast(8 as bigint) as ''ReservedKB'',    '
	+'		i.used * cast(8 as bigint) as ''UsedKB'',    '
	+'		k.keyno as ''KeyNumber'',  '
	+'		c.name as ''ColumnName'',  '
	+'		t.name as ''DataType'',   '
	+'		c.xprec as ''Precision'',  '
	+'		c.xscale as ''Scale'',   '
	+'		c.iscomputed as ''IsComputed'',   '
	+'		c.isnullable as ''IsNullable'',   '
	+'		c.collation as ''Collation''  '
	+'  '
	+'	from 	           [' + @db_name + ']..sysobjects   o with(nolock)  '
	+'		inner join [' + @db_name + ']..sysindexes   i with(nolock) on o.id    =  i.id  '
	+'		inner join [' + @db_name + ']..sysindexkeys k with(nolock) on i.id    =  k.id    and    i.indid =  k.indid  '
	+'		inner join [' + @db_name + ']..syscolumns   c with(nolock) on k.id    =  c.id    and    k.colid =  c.colid   '
	+'		inner join [' + @db_name + ']..systypes     t with(nolock) on c.xtype =  t.xtype   '
	+'  '
	+'	where 	o.xtype <> ''S''  '  -- Ignore system objects
	+'	and 	i.name not like ''_wa_sys_%''   ' -- Ignore statistics
	+'  '
	+'	order by  '
	+'		o.name,   '
	+'		k.indid,  '
	+'		k.keyno  '

	execute sp_executesql @sql_string

	fetch next from db_cursor into @db_name, @DbID
end 

deallocate db_cursor

select * from #tblHistoryIndex

drop table #tblHistoryIndex





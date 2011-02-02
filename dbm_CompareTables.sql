USE [dbamaint]
GO

/****** Object:  StoredProcedure [dbo].[dbm_CompareTables]    Script Date: 06/09/2009 15:29:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Sync StatusIMP with Prod
-- Update records locally

CREATE PROCEDURE [dbo].[dbm_CompareTables](@table1 varchar(100),
 @table2 Varchar(100), @T1ColumnList varchar(1000),
 @T2ColumnList varchar(1000) = '')

AS

-- Table1, Table2 are the tables or views to compare.
-- T1ColumnList is the list of columns to compare, from table1.
-- Just list them comma-separated, like in a GROUP BY clause.
-- If T2ColumnList is not specified, it is assumed to be the same
-- as T1ColumnList.  Otherwise, list the columns of Table2 in
-- the same order as the columns in table1 that you wish to compare.
--
-- The result is all rows from either table that do NOT match
-- the other table in all columns specified, along with which table that
-- row is from.

declare @SQL varchar(8000);

IF @t2ColumnList = '' SET @T2ColumnList = @T1ColumnList

set @SQL = 'SELECT ''' + @table1 + ''' AS TableName, ' + @t1ColumnList +
 ' FROM ' + @Table1 + ' UNION ALL SELECT ''' + @table2 + ''' As TableName, ' +
 @t2ColumnList + ' FROM ' + @Table2

set @SQL = 'SELECT Max(TableName) as TableName, ' + @t1ColumnList +
 ' FROM (' + @SQL + ') A GROUP BY ' + @t1ColumnList +
 ' HAVING COUNT(*) = 1'

exec ( @SQL)
GO



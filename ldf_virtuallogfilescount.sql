-- Create a temp table to hold log info
CREATE TABLE #tmp_log_info
(
      FileId INTEGER,
      FileSize BIGINT,
      StartOffSet BIGINT,
      [Status] INTEGER,
      FSeqNo INTEGER,
      Parity SMALLINT,
      CreateLSN NUMERIC(38,0)
);
 
-- Same as above but with database name
-- Can insert in one statement
CREATE TABLE #log_info
(
      FileId INTEGER,
      FileSize BIGINT,
      StartOffSet BIGINT,
      [Status] INTEGER,
      FSeqNo INTEGER,
      Parity SMALLINT,
      CreateLSN NUMERIC(38,0),
      [Database] VARCHAR(128)
);
 
EXEC sp_MsForEachDb 'INSERT INTO #tmp_log_info EXEC(''DBCC LOGINFO(?)'');
                              INSERT INTO #log_info
                               SELECT *, ''?''
                              FROM #tmp_log_info;
                              TRUNCATE TABLE #tmp_log_info;';
 
SELECT [Database],
            COUNT(*) AS Vlf_count,
            CAST(MAX(FileSize) AS FLOAT) / 1048576  AS biggest_vlf_MB,
            CAST(MIN(FileSize) AS FLOAT) / 1048576 AS smallest_vlf_MB
FROM #log_info
GROUP BY [Database]
ORDER BY COUNT(*) DESC;
 
 
-- Clean up
DROP TABLE #tmp_log_info;
DROP TABLE #log_info;
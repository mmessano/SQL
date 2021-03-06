USE [dbamaint]
GO


-- CREATE THE FUNCTION TO DO THE CONVERSION
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Number2 (John Nelson) - http://number2blog.com
-- Create date: 2009-07-02
-- Description: Convert bytes from one byte-based unit of measure
--              (Bytes, KB, MB, GB, TB, PB, EB, ZB, YB, BB, Geopbytes)
--              to any other byte-based unit of measure in human-
--              readable format...meaning the output is a number
--              followed by a UOM, not just a number.
--              example: 21.409023 GB
-- INPUT: @InputNumber - Decimal(38,7)
--        @InputUOM - VARCHAR(11)
--        @OutputUOM - VARCHAR(11)
--
-- OUTPUT: VARCHAR(64)
--
--
--AND TEST IT TO MAKE SURE IT WORKS (CONVERT THE DISK SIZE MB TO GB)
--SELECT
--   ResourceID,
--   dbo.udf_ConvertBytes(Size0,'MB','GB') AS Size
--FROM
--   dbo.v_GS_Logical_Disk
--WHERE
--   Name0 = 'C:'
-- =============================================
CREATE FUNCTION [dbo].[udf_ConvertBytes]
(
   @InputNumber   DECIMAL(38,7),
   @InputUOM      VARCHAR(11) = 'Bytes',
   @OutputUOM     VARCHAR(11) = 'Gigabytes'
)
RETURNS VARCHAR(64)
WITH SCHEMABINDING
AS
BEGIN
   DECLARE @Result VARCHAR(64);
  
   DECLARE @InputMultiplier DECIMAL(38,0);
   DECLARE @OutputDivisor DECIMAL(38,0);
   DECLARE @OutputSuffix VARCHAR(11);

SELECT
   @InputMultiplier = 
      CASE @InputUOM
         WHEN 'Bytes'         THEN 1
         WHEN 'Byte'          THEN 1
         WHEN 'B'             THEN 1
         WHEN 'Kilobytes'     THEN 1024
         WHEN 'Kilobyte'      THEN 1024
         WHEN 'KB'            THEN 1024
         WHEN 'Megabytes'     THEN 1048576
         WHEN 'Megabyte'      THEN 1048576
         WHEN 'MB'            THEN 1048576
         WHEN 'Gigabytes'     THEN 1073741824
         WHEN 'Gigabyte'      THEN 1073741824
         WHEN 'GB'            THEN 1073741824
         WHEN 'Terabytes'     THEN 1099511627776
         WHEN 'Terabyte'      THEN 1099511627776
         WHEN 'TB'            THEN 1099511627776
         WHEN 'Petabytes'     THEN 1125899906842624
         WHEN 'Petabyte'      THEN 1125899906842624
         WHEN 'PB'            THEN 1125899906842624
         WHEN 'Exabytes'      THEN 1152921504606846976
         WHEN 'Exabyte'       THEN 1152921504606846976
         WHEN 'EB'            THEN 1152921504606846976
         WHEN 'Zettabytes'    THEN 1180591620717411303424
         WHEN 'Zettabyte'     THEN 1180591620717411303424
         WHEN 'ZB'            THEN 1180591620717411303424
         WHEN 'Yottabytes'    THEN 1208925819614629174706176
         WHEN 'Yottabyte'     THEN 1208925819614629174706176
         WHEN 'YB'            THEN 1208925819614629174706176
         WHEN 'Brontobytes'   THEN 1237940039285380274899124224
         WHEN 'Brontobyte'    THEN 1237940039285380274899124224
         WHEN 'BB'            THEN 1237940039285380274899124224
         WHEN 'Geopbytes'     THEN 1267650600228229401496703205376
         WHEN 'Geopbyte'      THEN 1267650600228229401496703205376
      END,
   @OutputDivisor =
      CASE @OutputUOM
         WHEN 'Bytes'         THEN 1
         WHEN 'Byte'          THEN 1
         WHEN 'B'             THEN 1
         WHEN 'Kilobytes'     THEN 1024
         WHEN 'Kilobyte'      THEN 1024
         WHEN 'KB'            THEN 1024
         WHEN 'Megabytes'     THEN 1048576
         WHEN 'Megabyte'      THEN 1048576
         WHEN 'MB'            THEN 1048576
         WHEN 'Gigabytes'     THEN 1073741824
         WHEN 'Gigabyte'      THEN 1073741824
         WHEN 'GB'            THEN 1073741824
         WHEN 'Terabytes'     THEN 1099511627776
         WHEN 'Terabyte'      THEN 1099511627776
         WHEN 'TB'            THEN 1099511627776
         WHEN 'Petabytes'     THEN 1125899906842624
         WHEN 'Petabyte'      THEN 1125899906842624
         WHEN 'PB'            THEN 1125899906842624
         WHEN 'Exabytes'      THEN 1152921504606846976
         WHEN 'Exabyte'       THEN 1152921504606846976
         WHEN 'EB'            THEN 1152921504606846976
         WHEN 'Zettabytes'    THEN 1180591620717411303424
         WHEN 'Zettabyte'     THEN 1180591620717411303424
         WHEN 'ZB'            THEN 1180591620717411303424
         WHEN 'Yottabytes'    THEN 1208925819614629174706176
         WHEN 'Yottabyte'     THEN 1208925819614629174706176
         WHEN 'YB'            THEN 1208925819614629174706176
         WHEN 'Brontobytes'   THEN 1237940039285380274899124224
         WHEN 'Brontobyte'    THEN 1237940039285380274899124224
         WHEN 'BB'            THEN 1237940039285380274899124224
         WHEN 'Geopbytes'     THEN 1267650600228229401496703205376
         WHEN 'Geopbyte'      THEN 1267650600228229401496703205376
      END,
   @OutputSuffix =
      CASE @OutputUOM
         WHEN 'Bytes'         THEN ' Bytes'     
         WHEN 'Byte'          THEN ' Bytes'
         WHEN 'B'             THEN ' Bytes'
         WHEN 'Kilobytes'     THEN ' KB'
         WHEN 'Kilobyte'      THEN ' KB'
         WHEN 'KB'            THEN ' KB'
         WHEN 'Megabytes'     THEN ' MB'
         WHEN 'Megabyte'      THEN ' MB'
         WHEN 'MB'            THEN ' MB'
         WHEN 'Gigabytes'     THEN ' GB'
         WHEN 'Gigabyte'      THEN ' GB'
         WHEN 'GB'            THEN ' GB'
         WHEN 'Terabytes'     THEN ' TB'
         WHEN 'Terabyte'      THEN ' TB'
         WHEN 'TB'            THEN ' TB'
         WHEN 'Petabytes'     THEN ' PB'
         WHEN 'Petabyte'      THEN ' PB'
         WHEN 'PB'            THEN ' PB'
         WHEN 'Exabytes'      THEN ' EB'
         WHEN 'Exabyte'       THEN ' EB'
         WHEN 'EB'            THEN ' EB'
         WHEN 'Zettabytes'    THEN ' ZB'
         WHEN 'Zettabyte'     THEN ' ZB'
         WHEN 'ZB'            THEN ' ZB'
         WHEN 'Yottabytes'    THEN ' YB'
         WHEN 'Yottabyte'     THEN ' YB'
         WHEN 'YB'            THEN ' YB'
         WHEN 'Brontobytes'   THEN ' BB'
         WHEN 'Brontobyte'    THEN ' BB'
         WHEN 'BB'            THEN ' BB'
         WHEN 'Geopbytes'     THEN ' GeopBytes'
         WHEN 'Geopbyte'      THEN ' GeopBytes'
      END
     
   SELECT @Result = CAST((@InputNumber * @InputMultiplier)/@OutputDivisor AS VARCHAR(49)) + @OutputSuffix;
  
   RETURN @Result;
END;

-- GRANT RIGHTS TO SMS/ConfigMgr REPORTS TO EXECUTE THE FUNCTION
--GRANT EXECUTE ON dbo.udf_ConvertBytes TO smsschm_users, webreport_approle;
--GO



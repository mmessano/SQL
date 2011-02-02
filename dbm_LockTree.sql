USE dbamaint
GO
/*
PART ONE:	USER DEFINED FUNCTION dbo.udf_LockTree
			RUN THIS FIRST
*/


/*****************************************************************************/
/**      Object:  User Defined Function dbo.udf_LockTree			******/
/** Script Date:  07/23/2002 10:21:32									******/
/** 	 Author:  Keith Mac Lure										******/
/**		Purpose:  Used in conjuction with dbm_LockTree. Accepts @BLKID	******/
/**				  and recurses through tree listing to determine level  ******/
/**				  and path.												******/
/*****************************************************************************/

IF EXISTS (SELECT * FROM DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'[DBO].[udf_LockTree]') AND XTYPE IN (N'FN', N'IF', N'TF'))
DROP FUNCTION [DBO].[udf_LockTree]
GO

CREATE FUNCTION udf_LockTree
(
  @BLKID AS INT
)

RETURNS @TREE TABLE    --Uses Table Data type to return results
(
  SPID   INT          NOT NULL,		--SPID of process being blocked by @BLKID
  BLOCKED   INT          NULL,		--ID of process blocking SPID
  HOSTNAME VARCHAR(25)  NOT NULL,	--SQL Hostname i.e. username
  LVL     INT          NOT NULL,	--Used for recursion
  PATH    VARCHAR(900) NOT NULL		--Used to display tree level
)
AS

BEGIN
  
  DECLARE @LVL AS INT, @PATH AS VARCHAR(1000)
  SELECT @LVL = 0, @PATH = '.'

  INSERT INTO @TREE
    SELECT SPID, BLOCKED, HOSTNAME,
           @LVL, '.' + CAST(SPID AS VARCHAR(10)) + '.'
    FROM MASTER..LOCKS			--MASTERS..LOCKS is created by the Calling USP
    WHERE SPID = @BLKID

  WHILE @@ROWCOUNT > 0
  BEGIN
    SET @LVL = @LVL + 1

    INSERT INTO @TREE
      SELECT E.SPID, E.BLOCKED, E.HOSTNAME,
             @LVL, T.PATH + CAST(E.SPID AS VARCHAR(10)) + '.'
      FROM MASTER..LOCKS AS E JOIN @TREE AS T
        ON  E.BLOCKED = T.SPID AND T.LVL = @LVL - 1
  END  
  
  RETURN

END
GO


/*
PART TWO:	USER DEFINED STORED PROCEDURE dbo.dbm_LockTree
			RUN THIS SECOND
*/


/*****************************************************************************/
/**      Object:  USER DEFINED STORED PROCEDURE dbo.dbm_LockTree		******/
/** Script Date:  07/23/2002 10:25:40									******/
/** 	 Author:  Keith Mac Lure										******/
/**		Purpose:  Displays a "locking chain" in tree format. Creates	******/
/**				  MASTER..LOCKS Table with info on locking processes,  	******/
/**				  calls dbo.udf_LockTree which recurses locking 	******/
/**				  info and creates locking tree.						******/
/*****************************************************************************/


IF EXISTS (SELECT * FROM DBO.SYSOBJECTS WHERE ID = OBJECT_ID(N'[DBO].[dbm_LockTree]') AND OBJECTPROPERTY(ID, N'ISPROCEDURE') = 1)
DROP PROCEDURE DBO.dbm_LockTree
GO

CREATE PROCEDURE dbm_LockTree
AS
SET NOCOUNT ON
  BEGIN
    SELECT P.SPID, P.BLOCKED, RTRIM(P.HOSTNAME) HOSTNAME
	  INTO MASTER..LOCKS
      FROM MASTER..SYSPROCESSES P 
	  WHERE P.BLOCKED <> 0
        OR SPID IN (SELECT BLOCKED FROM MASTER..SYSPROCESSES)
          AND BLOCKED=0
      ORDER BY P.BLOCKED, P.SPID

    DECLARE @COUNT INT
    SET @COUNT = (SELECT SPID FROM MASTER..LOCKS WHERE BLOCKED = 0)

    SELECT ' ' + REPLICATE ('   ', LVL) + RTRIM(HOSTNAME)+ ' ('+ CAST(SPID AS VARCHAR)+')' AS "BLOCKING LOCKS"
      FROM udf_LockTree(@COUNT)
      ORDER BY PATH

    DROP TABLE MASTER..LOCKS

  END

SET NOCOUNT OFF
GO

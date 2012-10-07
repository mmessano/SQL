SET NOCOUNT ON

DECLARE @DB VARCHAR(128)
DECLARE @ObjectName VARCHAR(128)
DECLARE @IndexName VARCHAR(128)
DECLARE @SQL VARCHAR(MAX)

DECLARE @Indexes TABLE 
(
	ObjectName VARCHAR(128) NULL,
	IndexName VARCHAR(128) NULL
)

INSERT INTO @Indexes (ObjectName, IndexName) VALUES ('loan_price_history', 'IX_LoanPriceHistory_LnLoanId_LphId')
INSERT INTO @Indexes (ObjectName, IndexName) VALUES ('institution_association', 'IX_InstAssoc_IAInst_IaParentInst')
INSERT INTO @Indexes (ObjectName, IndexName) VALUES ('Underwriting', 'IX_Underwriting_LoanId')
INSERT INTO @Indexes (ObjectName, IndexName) VALUES ('Funding', 'IX_Funding_LoanId')
INSERT INTO @Indexes (ObjectName, IndexName) VALUES ('br_liability', 'IX_BrLiability_LnLoanID_BtLiabId')
INSERT INTO @Indexes (ObjectName, IndexName) VALUES ('br_income', 'IX_BrIncome_LnLoanID_BiId')
INSERT INTO @Indexes (ObjectName, IndexName) VALUES ('br_address', 'IX_BrAddress_LnLoanID_BaID')
INSERT INTO @Indexes (ObjectName, IndexName) VALUES ('br_expense', 'IX_BrExpense_LnLoanID_BexId')
INSERT INTO @Indexes (ObjectName, IndexName) VALUES ('addl_loan_data', 'IX_AddlLoanData_LnLoanID_AldId')
INSERT INTO @Indexes (ObjectName, IndexName) VALUES ('loan_fees', 'IX_LoanFees_LnLoanId')

DECLARE DB_cur CURSOR FOR
	SELECT Name FROM sys.databases
	WHERE name LIKE '%SMC'

OPEN DB_cur
FETCH NEXT FROM DB_cur INTO @DB

WHILE (@@FETCH_STATUS <> -1)
BEGIN

DECLARE Index_cur CURSOR FOR
	SELECT ObjectName, IndexName FROM @Indexes

OPEN Index_cur
FETCH NEXT FROM Index_cur INTO @ObjectName, @IndexName

WHILE (@@FETCH_STATUS <> -1)

BEGIN

SELECT @SQL = '
IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[' + @ObjectName + ']'') AND name = N''' + @IndexName + ''')
	BEGIN
		PRINT ''Found ' + @DB + '.' + @ObjectName + '.' + @IndexName + '''
	END
	ELSE
	BEGIN
		PRINT ''Did not find ' + @DB + '.' + @ObjectName + '.' + @IndexName + '''
	END'

--PRINT @SQL
EXEC(@SQL)

FETCH NEXT FROM Index_cur INTO @ObjectName, @IndexName

END
CLOSE Index_cur
DEALLOCATE Index_cur

FETCH NEXT FROM DB_cur INTO @DB


END
CLOSE DB_cur
DEALLOCATE DB_cur


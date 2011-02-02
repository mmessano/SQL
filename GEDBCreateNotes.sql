USE GE_Document_Archive_2010
GO
-- SELECT from source DB document_files into archive DB
SET IDENTITY_INSERT document_files ON
GO
INSERT INTO document_files (df_id, do_id, df_document_title, df_document_location, df_filename, df_doc_repository_id, df_filetype, df_filesize, df_date_received, df_date_transmitted, df_last_update, df_updated_by, df_DCStatus, df_DCDateSent, df_DCFileID, df_DCUploadedBy)
SELECT df_id, do_id, df_document_title, df_document_location, df_filename, df_doc_repository_id, df_filetype, df_filesize, df_date_received, df_date_transmitted, df_last_update, df_updated_by, df_DCStatus, df_DCDateSent, df_DCFileID, df_DCUploadedBy
--into document_files
FROM GEAUCentralP3..document_files
WHERE do_id in
	(SELECT distinct do_id
	FROM GEAUCentralP3.dbo.document_orders do
	WHERE ln_loan_id in
		(select distinct la_loan_appl_id
		from GEAUCentralP3..loan_appl
		where la_last_Update < '1/1/2006'))
SET IDENTITY_INSERT document_files OFF	
GO

-- SELECT from source DB document_orders into archive DB
SET IDENTITY_INSERT document_orders ON
GO
INSERT INTO document_orders (do_id, ln_loan_id, relate_order_id, do_client_xref_id, do_pertain_to_text, do_pertain_to_id, do_joint_flag, do_order_status, do_order_outcome, do_document_category, do_document_type, do_vendor, do_date_initiated, do_date_ordered, do_date_received, do_date_transferred, do_err_message, do_ordered_by, do_vendor_xref_id, do_other_params, do_ssn, do_acct_num, do_last_update, do_updated_by, do_order_type, do_lender_inst, do_alert_flag, do_liab_updated, do_merged_credit, do_invoice_recipient, PostMIRemoval, LTVAtTimeOfOrder)
SELECT do_id, ln_loan_id, relate_order_id, do_client_xref_id, do_pertain_to_text, do_pertain_to_id, do_joint_flag, do_order_status, do_order_outcome, do_document_category, do_document_type, do_vendor, do_date_initiated, do_date_ordered, do_date_received, do_date_transferred, do_err_message, do_ordered_by, do_vendor_xref_id, do_other_params, do_ssn, do_acct_num, do_last_update, do_updated_by, do_order_type, do_lender_inst, do_alert_flag, do_liab_updated, do_merged_credit, do_invoice_recipient, PostMIRemoval, LTVAtTimeOfOrder
--into Document_Orders
FROM GEAUCentralP3.dbo.Document_Orders do
WHERE do.ln_loan_id in
	(select distinct la_loan_appl_id
	from GEAUCentralP3..loan_appl
	where la_last_Update < '1/1/2006')
SET IDENTITY_INSERT document_orders OFF
GO
	
********************************************
********     --Verify Records--     ********
********************************************
-- Verify records between the source DB document_files and the archive DB
SELECT *
FROM GEAUCentralP3..document_files df
LEFT OUTER JOIN document_files df9
ON df.do_id = df9.do_id
WHERE df9.do_id IN
	(SELECT distinct do_id
	FROM GEAUCentralP3.dbo.document_orders do
	WHERE ln_loan_id in
		(select distinct la_loan_appl_id
		from GEAUCentralP3..loan_appl
		where la_last_Update < '1/1/2006'))
	and df9.do_id IS NULL
-------------------------------------------------------------
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO
SELECT do_id, df_last_update
FROM
(SELECT DISTINCT 'Live' AS source, do_id, df_last_update
FROM GEAUCentralP3..document_files df
WHERE do_id IN
	(SELECT distinct do_id
	FROM document_orders
	WHERE ln_loan_id in
		(SELECT DISTINCT la_loan_appl_id
		FROM GEAUCentralP3..loan_appl
		WHERE la_last_Update < '1/1/2006'))
UNION ALL
SELECT DISTINCT 'Archive' AS source, do_id, df_last_update
FROM GE_Document_Archive_2010.dbo.document_files
WHERE do_id IN
	(SELECT distinct do_id
	FROM document_orders
	WHERE ln_loan_id IN
		(SELECT DISTINCT la_loan_appl_id
		FROM GEAUCentralP3..loan_appl
		WHERE la_last_Update < '1/1/2006'))
) AS UA
GROUP BY do_id, df_last_update
HAVING COUNT(*) = 1 AND MAX(source)='Live'	
	
-- Verify records between the source DB document_orders and the archive DB
select count(*)
	from GEAUCentralP3.dbo.loan_appl p3la
	left outer join GE_Document_Archive_2010..Document_Orders do9
	on p3la.la_loan_appl_id = do9.ln_loan_id
	where p3la.la_last_update < '1/1/2006'
	and do9.ln_loan_id IS NULL
-------------------------------------------------------------
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO
SELECT la_loan_appl_id, max(la_last_update) AS MaxLastUpdate
	FROM loan_appl
	WHERE la_loan_appl_id IN 
		(select ln_loan_id
		FROM
		(SELECT DISTINCT 'Live' AS Source, do_id, ln_loan_id, do_last_update
			FROM document_orders
			WHERE do_last_update < '1/1/2006'
UNION ALL
SELECT distinct 'Archive' as Source, do_id, ln_loan_id, do_last_update
	FROM GE_Document_Archive_09.dbo.document_orders_09
	WHERE do_last_update < '1/1/2006') AS UA
	GROUP BY do_id, ln_loan_id, do_last_update
	HAVING COUNT(*) =1 AND MAX(source)='Live'
	)
GROUP BY la_loan_appl_id
ORDER BY 2 DESC	
	
********************************************
********    -- Delete Records --    ********
********************************************
-- DELETE document_files records from the source db
/*
USE GEAUCentralP3
GO
BEGIN TRAN
DELETE FROM document_files
WHERE do_id IN
	(SELECT distinct do_id
	FROM document_orders do
	WHERE ln_loan_id IN
		(select distinct la_loan_appl_id
		FROM loan_appl
		WHERE loan_appl.la_last_Update < '1/1/2006'
        ))
COMMIT TRAN 
*/
	
-- DELETE document_orders records from the source db
/*
USE GEAUCentralP3
GO
BEGIN TRAN
DELETE FROM Document_Orders
WHERE Document_Orders.ln_loan_id in
	(select distinct la_loan_appl_id
	from loan_appl
	where la_last_Update < '1/1/2006')
COMMIT TRAN
*/

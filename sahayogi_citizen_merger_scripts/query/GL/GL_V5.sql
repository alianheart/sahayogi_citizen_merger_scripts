use PPIVSahayogiVBL
Declare @MigDate date, @v_MigDate nvarchar(15)
set @MigDate = (select Today from ControlTable);
set @v_MigDate = REPLACE(CONVERT(VARCHAR,@MigDate,106), ' ','-')


--pre check 
/*
SELECT * FROM FINMIG.dbo.GL_MAPPING
WHERE SOLID <> LEFT(FORACID_WITH_MIGRA,3)
*/

select  
 gl.ALL_BACID,

 gl.FORACID_WITH_MIGRA AS foracid

--gl.FORACID_WITH_MIGRA AS foracid
--gl.FORACID  AS foracid
,c.CyDesc AS tran_crncy_code
,F_SolId AS sol_id
, CASE WHEN BASE_CCY<0 THEN 'D' ELSE 'C' END AS part_tran_type
,RIGHT(SPACE(17)+CAST(ABS(BASE_CCY) AS VARCHAR(17)),17) AS tran_amt
,@v_MigDate+' - Migration' AS tran_particular
,'' AS rpt_code
,'' AS ref_num
,'' AS instrmnt_type
,'' AS instrmnt_date
,'' AS instrmnt_alpha
,'' AS instrmnt_num
,'' AS navigation_flg
,RIGHT(SPACE(17)+CAST(ABS(NPR_BALANCE) AS VARCHAR(17)),17) AS ref_amt
,'NPR' AS ref_crncy_code
,'MID'  AS rate_code
--,RIGHT(SPACE(15)+CAST(Mid_Rate AS VARCHAR(15)),15) AS rate
--,RIGHT(SPACE(15)+CAST(NPR_BALANCE/BASE_CCY AS VARCHAR(15)),15) AS rate
,RIGHT(SPACE(15)+CAST('' AS VARCHAR(15)),15) AS rate
,CONVERT(VARCHAR(10),@MigDate,105) AS value_date
,CONVERT(VARCHAR(10),@MigDate,105) AS gl_date
,'' AS category_code
,'' AS bank_code
,'' AS br_code
,'' AS advc_to_from_extn_cntr_code
,'' AS bar_advc_gen_ind
,'' AS bar_or_advc_num
,'' AS bar_or_advc_date
,'' AS bill_num
,'' AS hdr_text_code
,'' AS hdr_free_text
,'' AS particulars_1
,'' AS particulars_2
,'' AS particulars_3
,'' AS particulars_4
,'' AS particulars_5
,'' AS amt_line_1
,'' AS amt_line_2
,'' AS amt_line_3
,'' AS amt_line_4
,'' AS amt_line_5
,gl.MainCode + '-' + gl.Name  AS remarks
,'' AS payee_acct
,'' AS rcvd_bar_or_advc_num
,'' AS rcvd_bar_or_advc_date
,'' AS Original_Transaction_Date
,'' AS Original_Transaction_ID  
,'' AS Original_Part_Transaction_Serial_Number 
,'' AS iban_number
,'' AS entity_id
,'' AS b2k_id
,'' AS b2k_type
,'' AS Tran_Particular_Code 
,'' AS Particulars_2_FreeText
FROM  FINMIG.dbo.GL_MAPPING gl 
		join FINMIG..SolMap s on s.BranchCode = gl.SOLID
		 join CurrencyTable c on c.CyCode=CCYCODE
WHERE ROUND(ABS(isnull(BASE_CCY,'0')),2)<>'0'
order by 3,2



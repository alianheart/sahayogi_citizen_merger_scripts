
use PPIVSahayogiVBL;
Declare @MigDate date, @v_MigDate nvarchar(15), @BACID nvarchar(100)='080040101'; --<000>MIGRA_<AUD>_LAA

set @MigDate = (select Today from ControlTable);

--TEMP TABLE
IF OBJECT_ID('tempdb.dbo.#loan_temp', 'U') IS NOT NULL
  DROP TABLE #loan_temp;

select * into #loan_temp from
(

select 
BranchCode,
ReferenceNo,
Flow_ID,
IntOverDues as flow_amt_indem,
isnull(IntOnIntOverDues,0)+isnull(IntOnPriOverDues,0) as flow_amt_pidem,
dmd_date 
from FINMIG.dbo.PastDue m where Flow_ID <>'PRDEM'
AND ReferenceNo not in (select ReferenceNo from FINMIG..OverDuesGreaterThanINT)

UNION ALL

select 
BranchCode,
t1.ReferenceNo,
Flow_ID,
sum(IntOverDues) as flow_amt_indem,
case when Flow_ID ='PIDEM' THEN sum(isnull(IntOnIntOverDues,0)+isnull(IntOnPriOverDues,0))+CAST(diff AS NUMERIC(17,2)) 
	ELSE '0.00' END as flow_amt_pidem,
max(dmd_date) dmd_date
from FINMIG.dbo.PastDue t1 join 
FINMIG.dbo.OverDuesGreaterThanINT t2 on t1.ReferenceNo=t2.ReferenceNo
where Flow_ID not in ('PRDEM')
AND FLOWID='PIDEM'
group by BranchCode,t1.ReferenceNo,Flow_ID,diff

union all

select 
BranchCode,
t1.ReferenceNo,
Flow_ID,
case when Flow_ID ='INDEM' THEN sum(IntOverDues)+CAST(diff AS NUMERIC(17,2))
	ELSE '0.00' END as flow_amt_indem,
sum(isnull(IntOnIntOverDues,0)+isnull(IntOnPriOverDues,0)) as flow_amt_pidem,
max(dmd_date) dmd_date
from FINMIG.dbo.PastDue t1 join 
FINMIG.dbo.OverDuesGreaterThanINT t2 on t1.ReferenceNo=t2.ReferenceNo
where Flow_ID not in ('PRDEM')
AND FLOWID='INDEM'
group by BranchCode,t1.ReferenceNo,Flow_ID,diff
)x


select 
	f.F_SolId+substring(f.ForAcid,4,2)+@BACID  AS foracid
	,'NPR' AS tran_crncy_code
	,f.F_SolId AS sol_id
	,'D' AS part_tran_type
	,case when Flow_ID='INDEM' THEN RIGHT(SPACE(17)+CAST(ROUND(CAST (t.flow_amt_indem AS decimal(17,2)),2) AS VARCHAR(17)),17)
else RIGHT(SPACE(17)+CAST(ROUND(CAST (t.flow_amt_pidem AS decimal(17,2)),2) AS VARCHAR(17)),17) end  AS tran_amt
	, ''  AS tran_particular
	,'' AS rpt_code
	,'' AS ref_num
	,'' AS instrmnt_type
	,'' AS instrmnt_date
	,'' AS instrmnt_alpha
	,'' AS instrmnt_num
	,'' AS navigation_flg
	, case when Flow_ID='INDEM' THEN RIGHT(SPACE(17)+CAST(ROUND(CAST (t.flow_amt_indem AS decimal(17,2)),2) AS VARCHAR(17)),17)
	else RIGHT(SPACE(17)+CAST(ROUND(CAST (t.flow_amt_pidem AS decimal(17,2)),2) AS VARCHAR(17)),17) end  AS ref_amt
	, '' AS ref_crncy_code
	,'MID'  AS rate_code
	,'' AS rate
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
	,''   AS hdr_free_text
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
	,'' AS remarks
	,'' AS payee_acct
	,'' AS rcvd_bar_or_advc_num
	,'' AS rcvd_bar_or_advc_date
	,'' AS Original_Transaction_Date
	,'' AS Original_Transaction_ID  
	,'' AS Original_Part_Transaction_Serial_Number 
	,'' AS iban_number
	,''   AS entity_id
	,'' as b2k_id
	,'' AS b2k_type
	,'' AS Tran_Particular_Code 
	,'' AS Particulars_2_FreeText
from #loan_temp t
--LEFT JOIN Master m on t.ReferenceNo = m.MainCode AND t.BranchCode = m.BranchCode
join FINMIG.dbo.ForAcidLAA f on 
t.ReferenceNo = f.MainCode and t.BranchCode =f.BranchCode

--t.BranchCode = f.BranchCode and f.Scheme_Type = 'LAA' --lm.MainCode = f.MainCode
where --round(m.Balance,2) <> 0 
1=1
and (t.flow_amt_indem>0 or t.flow_amt_pidem>0) and F_SolId not in ('108', '099')


union all


select 
	 f.F_SolId+substring(f.ForAcid,4,2)+AIR_BACID  AS foracid 
	,'NPR' AS tran_crncy_code
	,f.F_SolId AS sol_id
	,'C' AS part_tran_type
	,case when Flow_ID='INDEM' THEN RIGHT(SPACE(17)+CAST(ROUND(CAST (t.flow_amt_indem AS decimal(17,2)),2) AS VARCHAR(17)),17)
else RIGHT(SPACE(17)+CAST(ROUND(CAST (t.flow_amt_pidem AS decimal(17,2)),2) AS VARCHAR(17)),17) end  AS tran_amt
	, ''  AS tran_particular
	,'' AS rpt_code
	,'' AS ref_num
	,'' AS instrmnt_type
	,'' AS instrmnt_date
	,'' AS instrmnt_alpha
	,'' AS instrmnt_num
	,'' AS navigation_flg
	, case when Flow_ID='INDEM' THEN RIGHT(SPACE(17)+CAST(ROUND(CAST (t.flow_amt_indem AS decimal(17,2)),2) AS VARCHAR(17)),17)
	else RIGHT(SPACE(17)+CAST(ROUND(CAST (t.flow_amt_pidem AS decimal(17,2)),2) AS VARCHAR(17)),17) end  AS ref_amt
	, '' AS ref_crncy_code
	,'MID'  AS rate_code
	,'' AS rate
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
	,''   AS hdr_free_text
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
	,'' AS remarks
	,'' AS payee_acct
	,'' AS rcvd_bar_or_advc_num
	,'' AS rcvd_bar_or_advc_date
	,'' AS Original_Transaction_Date
	,'' AS Original_Transaction_ID  
	,'' AS Original_Part_Transaction_Serial_Number 
	,'' AS iban_number
	,''   AS entity_id
	,'' as b2k_id
	,'' AS b2k_type
	,'' AS Tran_Particular_Code 
	,'' AS Particulars_2_FreeText
from #loan_temp t
--LEFT JOIN Master m on t.ReferenceNo = m.MainCode AND t.BranchCode = m.BranchCode
join FINMIG.dbo.ForAcidLAA f on 
t.ReferenceNo = f.MainCode and t.BranchCode =f.BranchCode
 join  FINMIG.dbo.MGRA_AC_LOAN_AIR ma ON ma.SCHEME=f.F_SCHEME_CODE 
 AND substring(f.ForAcid,4,2)=substring(ma.FORACID,4,2)
--t.BranchCode = f.BranchCode and f.Scheme_Type = 'LAA' --lm.MainCode = f.MainCode
where 1=1--round(m.Balance,2) <> 0 
 and (t.flow_amt_indem>0 or t.flow_amt_pidem>0) and F_SolId not in ('108', '099')
order by   foracid,part_tran_type

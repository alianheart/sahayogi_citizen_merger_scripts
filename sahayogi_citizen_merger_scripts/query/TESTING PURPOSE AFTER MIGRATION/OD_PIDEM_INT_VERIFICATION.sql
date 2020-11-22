use PPIVSahayogiVBL
--cs002

Declare @MigDate date, @v_MigDate nvarchar(15),@v_StatusDate nvarchar(15)
set @MigDate = (select Today from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','')
set @v_StatusDate = REPLACE(CONVERT(VARCHAR,(select Today-1 from ControlTable),105), ' ','-')

--TEMP TABLE
IF OBJECT_ID('tempdb.dbo.#loan_temp', 'U') IS NOT NULL
  DROP TABLE #loan_temp;

select * into #loan_temp from
(

select 
BranchCode,
ReferenceNo,
Flow_ID,
isnull(IntOnIntOverDues,0)+isnull(IntOnPriOverDues,0) as flow_amt_pidem,
dmd_date as  dmd_date
from FINMIG.dbo.PastDue where Flow_ID not in ('PRDEM','INDEM')
AND ReferenceNo not in (select MainCode from FINMIG.dbo.OD_OVERDUE_GREATER where FLOWID='PIDEM') 
and ReferenceNo not in (select MainCode from Master where IntDrAmt <= 0)


UNION ALL

select 
BranchCode,
t1.ReferenceNo,
Flow_ID,
sum(isnull(IntOnIntOverDues,0)+isnull(IntOnPriOverDues,0))+CAST(diffint AS NUMERIC(17,2)) as flow_amt_pidem,
max(dmd_date) dmd_date
from FINMIG.dbo.PastDue t1 join 
FINMIG.dbo.OD_OVERDUE_GREATER t2 on t1.ReferenceNo=t2.MainCode
where Flow_ID not in ('PRDEM','INDEM')
and ReferenceNo not in (select MainCode from Master where IntDrAmt <= 0)
and FLOWID='PIDEM'
group by BranchCode,t1.ReferenceNo,Flow_ID,diffint
)x


--MAIN QUERY
select 
	 m.F_SolId+m.CyCode+o.BACID AS foracid
	,ct.CyDesc AS tran_crncy_code
	,m.F_SolId AS sol_id
	,CASE WHEN SUM(flow_amt_pidem) >0 THEN 'D' ELSE 'C' END AS part_tran_type
	,right(space(17)+cast(cast(SUM(flow_amt_pidem) as numeric(14,2))as varchar(17)),17) AS tran_amt
	,p.ReferenceNo +' '+o.NAME_OF_PRODUCT AS tran_particular
	,'' AS rpt_code
	,'' AS ref_num
	,'' AS instrmnt_type
	,'' AS instrmnt_date
	,'' AS instrmnt_alpha
	,'' AS instrmnt_num
	,'' AS navigation_flg
	, '' AS ref_amt
	--,'NPR' AS ref_crncy_code
	, '' AS ref_crncy_code
	--,'MID'  AS rate_code
	,''  AS rate_code
		,'' AS rate
	,CONVERT(VARCHAR(10),@MigDate,105) AS value_date
	--,'15-05-2018' AS value_date
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
	, p.ReferenceNo + ' '+ o.NAME_OF_PRODUCT AS hdr_free_text
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
	--,case when partition_acc is null then '' else partition_acc end AS remarks
	--,f.foracid AS remarks
	, m.ForAcid AS remarks
	,'' AS payee_acct
	,'' AS rcvd_bar_or_advc_num
	,'' AS rcvd_bar_or_advc_date
	,'' AS Original_Transaction_Date
	,'' AS Original_Transaction_ID  
	,'' AS Original_Part_Transaction_Serial_Number 
	,'' AS iban_number
	--,f.foracid AS entity_id
	,  m.ForAcid   AS entity_id
	,'ACCNT' as b2k_id
	,'' AS b2k_type
	,'' AS Tran_Particular_Code 
	,'' AS Particulars_2_FreeText
from FINMIG.dbo.ForAcidOD m join #loan_temp p
on m.MainCode=p.ReferenceNo
join FINMIG.dbo.OD_DUE o on m.F_SCHEME_CODE=o.SCHM_CODE
join CurrencyTable ct on m.CyCode=ct.CyCode
where 1=1 --and m.MainCode = '00504300063172000002'
and p.Flow_ID not in ('PRDEM','INDEM')
and o.FLAG='PIDEM'
and flow_amt_pidem<>0
--and MainCode = '00104500012043000005'
group by p.ReferenceNo,m.ForAcid,ct.CyDesc,o.BACID, F_SolId,m.CyCode,o.NAME_OF_PRODUCT




USE PPIVSahayogiVBL;
DECLARE @l_DAY DATE, @v_DAY nvarchar(15),@MTH DATE,@v_MONTH nvarchar(15), @MigDate date, @v_MigDate nvarchar(15),
@QTR DATE, @v_QTR nvarchar(15), @HYR DATE,@v_HYR nvarchar(15), @YR DATE, @v_YR nvarchar(15)

set @l_DAY = (select LastDay from ControlTable);
set @v_DAY=REPLACE(REPLACE(CONVERT(VARCHAR,@l_DAY,105), ' ','-'), ',','')

set @MigDate = (select Today from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','')
 


IF OBJECT_ID('tempdb.dbo.#FinalMaster', 'U') IS NOT NULL
  DROP TABLE #FinalMaster;

  select * into #FinalMaster from (
select *, 'SBA' SCHM_TYPE from FINMIG.dbo.ForAcidSBA
union all
select *, 'ODA' SCHM_TYPE from FINMIG.dbo.ForAcidOD
)
x

--select * from #FinalMaster where ForAcid = '0010100000028505'

IF OBJECT_ID('tempdb.dbo.#OverDues', 'U') IS NOT NULL
  DROP TABLE #OverDues;

  select * into #OverDues from (
	select ReferenceNo,BranchCode,sum(IntOverDues) as IntOverDues
	from FINMIG.dbo.PastDue group by ReferenceNo,BranchCode
)x

 
select 
'SBA' INDICATOR                 
,'' ACID                      
, f1.ForAcid FORACID                   
,f1.CyCode CRNCY_CODE                
,f1.F_SolId SOL_ID                    
, @v_DAY AS INTEREST_CALC_UPTO_DATE_CR
, @v_DAY AS ACCRUED_UPTO_DATE_CR  
, @v_DAY AS BOOKED_UPTO_DATE_CR   
,'' XFER_INT_AMT_CR           
,ISNULL(round(M.IntCrAmt,2),0) AS NRML_ACCRUED_AMOUNT_CR
--,ISNULL(M.IntCrAmt,0) AS NRML_ACCRUED_AMOUNT_CR    
,ISNULL(round(M.IntCrAmt,2),0) AS NRML_BOOKED_AMOUNT_CR     
,'' INTEREST_CALC_UPTO_DATE_DR
,'' AS ACCRUED_UPTO_DATE_DR           
,'' AS BOOKED_UPTO_DATE_DR       
,'' XFER_INT_AMT_DR           
,'' AS NRML_ACCRUED_AMOUNT_DR
--,ISNULL(M.IntDrAmt,0)AS  NRML_ACCRUED_AMOUNT_DR    
,'' AS NRML_BOOKED_AMOUNT_DR     
,'' PENALINT_ACCRUED_AMOUNT_DR
,'' PENALINT_BOOKED_AMOUNT_DR 
,'' PENAL_INTEREST_AMOUNT_DR 
FROM #FinalMaster f1 join Master M
on f1.MainCode=M.MainCode
where M.AcType in (select distinct ACTYPE from FINMIG..PRODUCT_MAPPING where MODULE = 'SAVING')
--(ISNULL(ROUND(M.IntCrAmt,2),0)>0)
--SCHM_TYPE = 'SBA'
order by f1.ForAcid


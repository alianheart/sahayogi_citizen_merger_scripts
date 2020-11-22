use PPIVSahayogiVBL

--TD_Interest TD008

DECLARE @MigDate DATE, @v_MigDate nvarchar(15),@MTH DATE,@mig_MONTH nvarchar(15),
@QTR DATE, @mig_QTR nvarchar(15), @HYR DATE,@mig_HYR nvarchar(15), @YR DATE, @mig_YR nvarchar(15),@MigDate1 DATE, @v_MigDate1 nvarchar(15)


set @MigDate = (select Today from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','')

set @MigDate1 = (select LastDay from ControlTable);
set @v_MigDate1=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate1,105), ' ','-'), ',','')

set @MTH = (select dateadd(day,1,LastMonthEnd) from ControlTable);
set @mig_MONTH=REPLACE(REPLACE(CONVERT(VARCHAR,@MTH,105), ' ','-'), ',','')

set @QTR = (select dateadd(day,1,LastQtrEnd) from ControlTable);
set @mig_QTR=REPLACE(REPLACE(CONVERT(VARCHAR,@QTR,105), ' ','-'), ',','')

set @HYR = (select dateadd(day,1,LastHalfYrEnd) from ControlTable);
set @mig_HYR=REPLACE(REPLACE(CONVERT(VARCHAR,@HYR,105), ' ','-'), ',','')

set @YR = (select dateadd(day,1,LastYearEnd) from ControlTable);
set @mig_YR=REPLACE(REPLACE(CONVERT(VARCHAR,@YR,105), ' ','-'), ',','')

--TD008-Interest

select 
'TDA' INDICATOR    
,'' ACID
, ForAcid FORACID                   
,C.CyDesc CRNCY_CODE                
,F_SolId SOL_ID                    
, case when IntPostFrqCr = '1' AND AcOpenDate<@MigDate then convert(varchar,dateadd(day,-1,@MigDate),105)
	when IntPostFrqCr = '4' AND AcOpenDate<@MTH then convert(varchar,dateadd(day,-1,@MTH),105)
	when IntPostFrqCr = '5' AND AcOpenDate<@QTR then convert(varchar,dateadd(day,-1,@QTR),105)
	when IntPostFrqCr = '6' AND AcOpenDate<@HYR then convert(varchar,dateadd(day,-1,@HYR),105)
	when IntPostFrqCr = '7' AND AcOpenDate<@YR then convert(varchar,dateadd(day,-1,@YR),105)
	else convert(VARCHAR,(dateadd(day,-1,AcOpenDate)),105) end AS INTEREST_CALC_UPTO_DATE_CR
, @v_MigDate1 AS ACCRUED_UPTO_DATE_CR  
, @v_MigDate1 AS BOOKED_UPTO_DATE_CR 
,'' XFER_INT_AMT_CR 
,RIGHT(SPACE(17)+CAST(round(IntAccrued_IntCrAmt,2) AS VARCHAR(17)),17) AS NRML_ACCRUED_AMOUNT_CR
--,ISNULL(M.IntCrAmt,0) AS NRML_ACCRUED_AMOUNT_CR    
,RIGHT(SPACE(17)+CAST(round(IntAccrued_IntCrAmt,2) AS VARCHAR(17)),17) AS NRML_BOOKED_AMOUNT_CR     
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
from FINMIG.dbo.ForAcidTD fa join DealTable t1
on fa.MainCode = t1.MainCode and fa.ReferenceNo = t1.ReferenceNo
join CurrencyTable C
on fa.CyCode = C.CyCode
where t1.IsMatured <> 'T'
order by FORACID


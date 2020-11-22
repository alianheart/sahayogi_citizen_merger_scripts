
--RL003 LRS

Use PPIVSahayogiVBL
Declare @MigDate date,@v_MigDate1 nvarchar(15), @v_MigDate nvarchar(15), @IntCalTillDate date, @MTH date, @v_MONTH nvarchar(15)
select  @MigDate=Today ,@IntCalTillDate=LastDay   from ControlTable;
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','')
--set @v_MigDate1=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate-1,105), ' ','-'), ',','')
select * from (
select 
(select MainCode from FINMIG..ForAcidLAA where ForAcid = LS.foracid) as MainCode,
foracid  foracid                    ,
flow_id  flow_id                    ,
convert(varchar,flow_start_date,105)  flow_start_date            ,
flow_start_date as flow_start_date_test,
ISNULL(lr_freq_type,'')  lr_freq_type               ,
ISNULL(lr_freq_week_num,'')  lr_freq_week_num   ,        
ISNULL(convert(nvarchar,lr_freq_week_day),'')  lr_freq_week_day  ,         
ISNULL(convert(nvarchar,right(flow_start_date,2)),'') lr_freq_start_dd          ,
ISNULL(convert(nvarchar,lr_freq_months),'')  lr_freq_months  ,         
ISNULL(convert(nvarchar,lr_freq_days),'') lr_freq_days,
'P' lr_freq_hldy_stat	,

--case when flow_id ='INDEM' then RIGHT(SPACE(3)+CAST('0' AS VARCHAR(3)),3)
--else RIGHT(SPACE(3)+CAST(num_of_flows AS VARCHAR(3)),3) end as    num_of_flows  ,
RIGHT(SPACE(3)+CAST(num_of_flows AS VARCHAR(3)),3)  as    num_of_flows  ,        

case when flow_id in('PRDEM','EIDEM') AND flow_amt = 0 THEN RIGHT(SPACE(17)+CAST('0.01' AS VARCHAR(17)),17)
	when flow_id ='INDEM' AND flow_amt<> 0 then '0'
	ELSE RIGHT(SPACE(17)+CAST(flow_amt AS VARCHAR(17)),17) END flow_amt,

ISNULL(convert(nvarchar,instlmnt_pcnt),'')  instlmnt_pcnt,
ISNULL(convert(nvarchar,num_of_dmds),'')   num_of_dmds,


case when @MigDate>flow_start_date then @v_MigDate --Next Dmd Date shld not be entered if Flow Start Dt. is greater than BOD Dt.
else '' end as next_dmd_date


--REPLACE(REPLACE(CONVERT(VARCHAR,next_dmd_date,105), ' ','-'), ',','')  as next_dmd_date
--'' as next_dmd_date
/*
case when flow_id= 'INDEM' THEN 
case when LimitExpiryDate < @MigDate then REPLACE(REPLACE(CONVERT(VARCHAR, (select Today-1 from ControlTable),105), ' ','-'), ',','')
else isnull(REPLACE(REPLACE(CONVERT(VARCHAR,LimitExpiryDate,105), ' ','-'), ',',''),datediff(day, @MigDate, 1)) end
ELSE '' END AS next_int_dmd_date,
*/

,'' as next_int_dmd_date,

case when flow_id= 'EIDEM' THEN ISNULL(convert(nvarchar,lr_int_freq_type),'')
	ELSE '' END AS      lr_int_freq_type       ,
ISNULL(convert(nvarchar,lr_int_freq_week_num),'')  lr_int_freq_week_num       ,
ISNULL(convert(nvarchar,lr_int_freq_week_day),'')    lr_int_freq_week_day     ,
ISNULL(convert(nvarchar,right(flow_start_date,2)),'') lr_int_freq_start_dd         ,
ISNULL(convert(nvarchar,lr_int_freq_months),'') lr_int_freq_months           ,
--ISNULL(convert(nvarchar,lr_int_freq_days),'') lr_int_freq_days             ,
ISNULL(convert(nvarchar,''),'') lr_int_freq_days             ,
'P' lr_int_freq_hldy_stat        ,
ISNULL(convert(nvarchar,instlmnt_ind),'') instlmnt_ind			     
 from FINMIG.dbo.LRS LS join FINMIG..ForAcidLAA b 
 on LS.foracid = b.ForAcid join Master m on b.MainCode = m.MainCode

union all


select 
(select MainCode from FINMIG..ForAcidLAA where ForAcid = LS.foracid) as MainCode,
foracid  foracid                    ,

'PRDEM'  flow_id                    ,
convert(varchar,(select Today-1 from ControlTable),105)  flow_start_date            ,
flow_start_date as flow_start_date_test,
ISNULL(lr_freq_type,'')  lr_freq_type               ,
ISNULL(lr_freq_week_num,'')  lr_freq_week_num   ,        
ISNULL(convert(nvarchar,lr_freq_week_day),'')  lr_freq_week_day  ,         
ISNULL(convert(nvarchar,right(flow_start_date,2)),'') lr_freq_start_dd          ,
ISNULL(convert(nvarchar,lr_freq_months),'')  lr_freq_months  ,         
ISNULL(convert(nvarchar,lr_freq_days),'') lr_freq_days,
'P' lr_freq_hldy_stat	,

--case when flow_id ='INDEM' then RIGHT(SPACE(3)+CAST('0' AS VARCHAR(3)),3)
--else RIGHT(SPACE(3)+CAST(num_of_flows AS VARCHAR(3)),3) end as    num_of_flows  ,
RIGHT(SPACE(3)+CAST(1 AS VARCHAR(3)),3)  as    num_of_flows  ,        

RIGHT(SPACE(17)+CAST('0.01' AS VARCHAR(17)),17) flow_amt,

ISNULL(convert(nvarchar,instlmnt_pcnt),'')  instlmnt_pcnt,
ISNULL(convert(nvarchar,num_of_dmds),'')   num_of_dmds,


'31-12-2099' as next_dmd_date


--REPLACE(REPLACE(CONVERT(VARCHAR,next_dmd_date,105), ' ','-'), ',','')  as next_dmd_date
--'' as next_dmd_date
/*
case when flow_id= 'INDEM' THEN 
case when LimitExpiryDate < @MigDate then REPLACE(REPLACE(CONVERT(VARCHAR, (select Today-1 from ControlTable),105), ' ','-'), ',','')
else isnull(REPLACE(REPLACE(CONVERT(VARCHAR,LimitExpiryDate,105), ' ','-'), ',',''),datediff(day, @MigDate, 1)) end
ELSE '' END AS next_int_dmd_date,
*/

,'' as next_int_dmd_date,

case when flow_id= 'EIDEM' THEN ISNULL(convert(nvarchar,lr_int_freq_type),'')
	ELSE '' END AS      lr_int_freq_type       ,
ISNULL(convert(nvarchar,lr_int_freq_week_num),'')  lr_int_freq_week_num       ,
ISNULL(convert(nvarchar,lr_int_freq_week_day),'')    lr_int_freq_week_day     ,
ISNULL(convert(nvarchar,right(flow_start_date,2)),'') lr_int_freq_start_dd         ,
ISNULL(convert(nvarchar,lr_int_freq_months),'') lr_int_freq_months           ,
--ISNULL(convert(nvarchar,lr_int_freq_days),'') lr_int_freq_days             ,
ISNULL(convert(nvarchar,''),'') lr_int_freq_days             ,
'P' lr_int_freq_hldy_stat        ,
ISNULL(convert(nvarchar,instlmnt_ind),'') instlmnt_ind			     
 from FINMIG.dbo.LRS LS join FINMIG..ForAcidLAA b 
 on LS.foracid = b.ForAcid join Master m on b.MainCode = m.MainCode
where foracid in (select ForAcid from FINMIG..ForAcidLAA where ForAcid 
not in (select distinct foracid from FINMIG..LRS where flow_id <> 'INDEM'))) n
ORDER BY foracid,flow_id DESC,flow_start_date_test


/* loan repay schedule check query
select * from FINMIG..ForAcidLAA where ForAcid not in (
select foracid from FINMIG.dbo.LRS)
*/



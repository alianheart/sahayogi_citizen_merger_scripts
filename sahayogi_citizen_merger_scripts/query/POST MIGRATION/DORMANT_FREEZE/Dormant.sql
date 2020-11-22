

select 'spool acct_status.lst;' 
union all
select 
 
/*
fn.MainCode,
fn.ForAcid AS foracid
,case when t1.IsDormant = 'T' then 'D' 
 end AS acct_Status 
,case when t1.IsDormant = 'T' THEN case when t1.IsDormant= 'T'
  THEN convert(VARCHAR,dateadd(MM,6,t1.LastTranDate),105) END
END AS acct_status_date ,
*/
 'update tbaadm.cam set ACCT_STATUS = ' + '''D''' 
+ ' ,ACCT_STATUS_DATE = ''' +
  REPLACE(REPLACE(convert(VARCHAR,dateadd(MM,6,t1.LastTranDate),106), ' ','-'), ',','') 
   + ''' where acid = (select acid from tbaadm.gam where foracid = '''+ fn.ForAcid + ''');' as update_field
 from Master t1
join FINMIG.dbo.ForAcidOD fn on fn.MainCode = t1.MainCode 
and fn.AcType = t1.AcType 
where  t1.IsDormant ='T'

UNION ALL

select 
/*
fn.MainCode,
fn.ForAcid AS foracid
,case when t1.IsDormant = 'T' then 'D' 
 end AS acct_Status 
,case when t1.IsDormant = 'T' THEN case when t1.IsDormant= 'T'
  THEN convert(VARCHAR,dateadd(MM,6,t1.LastTranDate),105) END
END AS acct_status_date ,
*/
 'update tbaadm.smt set ACCT_STATUS = ' + '''D''' 
+ ' ,ACCT_STATUS_DATE = ''' +
  REPLACE(REPLACE(convert(VARCHAR,dateadd(MM,6,t1.LastTranDate),106), ' ','-'), ',','') 
   + ''' where acid = (select acid from tbaadm.gam where foracid = '''+ fn.ForAcid + ''');' as update_field
 from Master t1
join FINMIG.dbo.ForAcidSBA fn on fn.MainCode = t1.MainCode 

where  t1.IsDormant ='T' and t1.AcType in (select ACTYPE From FINMIG..PRODUCT_MAPPING where MODULE = 'CURRENT') 


union all


select 
/*
fn.MainCode,
fn.ForAcid AS foracid
,case when t1.IsDormant = 'T' then 'D' 
 end AS acct_Status 
,case when t1.IsDormant = 'T' THEN case when t1.IsDormant= 'T'
  THEN convert(VARCHAR,dateadd(MM,6,t1.LastTranDate),105) END
END AS acct_status_date ,
*/
 'update tbaadm.smt set ACCT_STATUS = ' + '''D''' 
+ ' ,ACCT_STATUS_DATE = ''' +
  REPLACE(REPLACE(convert(VARCHAR,dateadd(MM,36,isnull(t1.LastTranDate, t1.AcOpenDate)),106), ' ','-'), ',','') 
   + ''' where acid = (select acid from tbaadm.gam where foracid = '''+ fn.ForAcid + ''');' as update_field
 from Master t1
join FINMIG.dbo.ForAcidSBA fn on fn.MainCode = t1.MainCode 

where  t1.IsDormant ='T' and t1.AcType in (select ACTYPE From FINMIG..PRODUCT_MAPPING where MODULE = 'SAVING') 

--select 'saba' + null + 'Shrestha'

--34526 count




--34526 count


union all 

select 'commit;' 
union all
select 'spool off;'

-- Freeze Flag


select 'spool Freez_status.lst;' 
union all

select 
'update tbaadm.gam set frez_code = '+
case when t1.IsBlocked in('B','T','L','D') then 'T' when t1.IsBlocked ='-' then 'C' when t1.IsBlocked ='+' then 'D' end 
+ ' ,FREZ_REASON_CODE = ''MIG''' 
 + ' where foracid = ''' + ForAcid + ''';'
 FROM Master t1
join (select MainCode, ForAcid from FINMIG.dbo.ForAcidOD union all select MainCode, ForAcid from FINMIG.dbo.ForAcidSBA) fn on fn.MainCode = t1.MainCode --and fn.AcType = t1.AcType and fn.MainCode = t1.MainCode				--New Foracid generation query
where  
t1.IsBlocked in('B','T','L','D','-','+')

union all 

select 'commit;' 
union all
select 'spool off;'
--select * from Master where IsBlocked in('B','T','L','D','-','+') -- 6674
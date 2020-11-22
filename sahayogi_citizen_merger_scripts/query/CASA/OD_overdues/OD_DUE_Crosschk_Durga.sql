SELECT ReferenceNo, Sum(NormalInt) from PastDuedList where ReferenceNo in (select MainCode from Master where MoveType='4')

group by ReferenceNo


SELECT ReferenceNo, Sum(NewPastDuedInt) from PastDuedList p join FINMIG..ForAcidOD m on p.ReferenceNo=m.MainCode
where ReferenceNo in (select MainCode from Master where MoveType='4')
group by ReferenceNo
having sum(NewPastDuedInt)>0
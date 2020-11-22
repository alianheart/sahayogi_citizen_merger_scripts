select * from FINMIG..SolMap;

create table FINMIG..SolMap (
	BranchCode varchar(5),
	F_SolId varchar(3)
)

insert into FINMIG..SolMap(BranchCode, F_SolId)
values('001', '096');
insert into FINMIG..SolMap(BranchCode, F_SolId)
values('002', '097');
insert into FINMIG..SolMap(BranchCode, F_SolId)
values('003', '098');
insert into FINMIG..SolMap(BranchCode, F_SolId)
values('004', '099');
insert into FINMIG..SolMap(BranchCode, F_SolId)
values('005', '100');
insert into FINMIG..SolMap(BranchCode, F_SolId)
values('006', '101');
insert into FINMIG..SolMap(BranchCode, F_SolId)
values('007', '102');
insert into FINMIG..SolMap(BranchCode, F_SolId)
values('008', '103');
insert into FINMIG..SolMap(BranchCode, F_SolId)
values('009', '104');
insert into FINMIG..SolMap(BranchCode, F_SolId)
values('010', '105');
insert into FINMIG..SolMap(BranchCode, F_SolId)
values('011', '106');
insert into FINMIG..SolMap(BranchCode, F_SolId)
values('012', '107');
insert into FINMIG..SolMap(BranchCode, F_SolId)
values('013', '108');
insert into FINMIG..SolMap(BranchCode, F_SolId)
values('014', '109');

commit

select * from  FINMIG..SolMap

select * from FINMIG..solmap;

drop table FINMIG..solmap



/* 프로시저 기반의 데이터 탐색: 결측값 포함 */
proc cardinality
    data = hmeq_partn(where=(_partind_=0))
    maxlevels = 254
    outcard=out_card
    ;
run;

proc fedsql;
    select 
        _varname_,
        _nmiss_ / _nobs_ * 100. as "Missing Percent"
    from out_card
    where _varname_ not in ('_PartInd_')
    order by "Missing Percent" desc
    ;
quit;
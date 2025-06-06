/* 등간격 구간화 */
proc binning
    data=hmeq_partn(where=(_partind_=0))
    numbin=16
    method=bucket
    ;
    input mortdue;
    code file="&workspace_path./bnn/chap02_prep/code_bucket.sas";
    output out=out_bucket copyvars=(bad mortdue);
run;

proc fedsql;
    select * from out_bucket
    limit 5;
quit;

/* 등빈도 구간화 */
proc binning 
    data=hmeq_partn(where=(_partind_=0))
    numbin=16
    method=quantile
    ;
    input mortdue;
    code file="&workspace_path./chap02_prep/code_quantile.sas";
    output out=out_quantile copyvars=(bad mortdue);
run;

proc fedsql;
    select * from out_quantile
    limit 5;
quit;

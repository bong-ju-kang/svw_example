/* 모든 변수에 대한 유일건수 계산 */
proc cardinality data=hmeq 
    outcard=card_hmeq
    outdetails=details_hmeq
    maxlevels=254
    ;
    var _all_;
run;

/* 출력 데이터 컬럼 이해 */
proc contents data=card_hmeq varnum;
run;

/* 출력 데이터 일부 보기 */
proc fedsql;
    select * 
    from card_hmeq
    /* limit 5 */
    ;
quit;

/* 상세 출력 데이터 일부 보기 */
proc fedsql;
    select * 
    from details_hmeq
    where _varname_ in ('REASON', 'JOB')
    ;
quit;




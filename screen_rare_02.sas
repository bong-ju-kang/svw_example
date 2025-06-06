/* 희귀 범주 찾기 */
proc freqtab
    data = hmeq_partn
    missing
    ;
    tables &cats &target;
    /* 필요한 경우 테이블로 출력 */
    ods output OneWayFreqs=out_oneway;
run;
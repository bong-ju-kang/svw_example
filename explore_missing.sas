/* 결측값 분포 */
proc mi 
    data=hmeq_partn(where=(_partind_=0))
    nimpute=0
    simple
    ;
    class &cats;
    var &target &xvars;
    fcs; /* 범주형 변수가 있으면 반드시 필요 */
run;

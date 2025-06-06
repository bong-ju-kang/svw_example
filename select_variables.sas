
/* 잔차변동을 최소화. 지도학습 */
proc varreduce data=hmeq_partn(where=(_partind_=0));
    class &cats &target;
    reduce supervised &target = &xvars / bic;
run;

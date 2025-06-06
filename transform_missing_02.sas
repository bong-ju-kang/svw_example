/* 결측값 대체 모델*/
proc varimpute 
    data=hmeq_partn(where=(_partind_=0)) 
    seed=1234
    ;
    input &cats / ntech=mode;
    input &nums / ctech=median;
    output out=impute_hmeq copyvars=(&target);
    code file="&workspace_path./model/code_impute_hmeq.sas";
run;

/* 결측값 대체 */
%let codefile = "&workspace_path./model/code_impute_hmeq.sas";
data impute_hmeq_partn;
    set hmeq_partn;
    %include &codefile;
run;

/* 결측 데이터 구조 */
proc contents data=impute_hmeq_partn varnum;
run;
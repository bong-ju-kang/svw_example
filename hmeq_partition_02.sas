/* HMEQ */
filename infile url "https://github.com/bong-ju-kang/data/raw/refs/heads/master/hmeq.csv";

/* SAS 데이터셋 구성 */
proc import datafile=infile
    out=hmeq
    dbms=csv
    replace;
    guessingrows=MAX;
run;

/* 결과 확인 */
proc fedsql;
    select * 
    from hmeq
    limit 5
    ;
quit;

/* 분석시 사용할 역할 정의 */
%let target = BAD;
%let xvars = CLAGE CLNO DEBTINC DELINQ DEROG JOB LOAN MORTDUE NINQ REASON VALUE YOJ;
%let cats = REASON JOB;
%let nums = CLAGE CLNO DEBTINC DELINQ DEROG LOAN MORTDUE NINQ VALUE YOJ;
%let event = '1';



/* 검증 데이터 30% */
proc partition data=hmeq samppct=30 seed=12345 partind;
    by bad;
    output out=hmeq_partn;
run;

/* 결과 확인 */
proc freqtab data=hmeq_partn;
    table bad*_partind_;
run;

/* 검증 데이터 20% 평가 데이터 10% */
proc partition data=hmeq samppct=20 samppct2=10 seed=12345 partind;
    by bad;
    output out=hmeq_partn;
run;

/* 결과 확인 */
proc freqtab data=hmeq_partn;
    table bad*_partind_;
run;

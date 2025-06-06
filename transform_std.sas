/* 1단계: 평균과 표준편차를 구해서 매크로 변수로 저장 */
proc fedsql;
    drop table stats force;
    create table stats as
      select 
        mean(loan) as mu, 
        stddev(loan) as sigma
      from hmeq_partn
      where 
        _PartInd_=0
    ;
quit;

/* 매크로 변수에 저장 */
data _null_;
  set stats;
  call symputx('mu', mu);
  call symputx('sigma', sigma);
run;

/* 2단계: Z 점수 계산 */
proc fedsql;
  drop table zscore_loan force;
  create table zscore_loan as
  select *, 
         (loan - &mu.) / &sigma. as z_loan
  from hmeq_partn;
quit;

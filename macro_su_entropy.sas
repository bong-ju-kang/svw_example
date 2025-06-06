%put "su_entropy launched....";
%macro calc_lkr_su_entropy(x=, y=, data=, where=1);
   %let freq_xy = freq_&x._&y;
   %let freq_x  = freq_&x;
   %let freq_y  = freq_&y;
   %let ent_x   = ent_&x;
   %let ent_y   = ent_&y;
   %let ent_xy  = ent_&x._&y;
   %let result  = su_&x._&y;

   /* 교차 빈도표 */
   proc freqtab data=&data;
      where &where and &x is not null;
      table &x * &y / out=&freq_xy ;
   run;

   /* 단일 분포: x */
   proc freqtab data=&data;
      where &where and &x is not null;
      table &x / out=&freq_x ;
   run;

   /* 단일 분포: y */
   proc freqtab data=&data;
      where &where and &x is not null;
      table &y / out=&freq_y ;
   run;

   /* H(X) 계산 */
   proc fedsql;
      drop table &ent_x force;
      create table &ent_x as
      select sum(
         case when percent > 0 then -1 * (percent/100.0) * log(percent/100.0)/log(2) else 0 end
      ) as H_X
      from &freq_x;
   quit;

   /* H(Y) 계산 */
   proc fedsql;
      drop table &ent_y force;
      create table &ent_y as
      select sum(
         case when percent > 0 then -1 * (percent/100.0) * log(percent/100.0)/log(2) else 0 end
      ) as H_Y
      from &freq_y;
   quit;

   /* H(X,Y) 계산 */
   proc fedsql;
      drop table &ent_xy force;
      create table &ent_xy as
      select sum(
         case when percent > 0 then -1 * (percent / 100.0) * log(percent / 100.0) / log(2) else 0 end
      ) as H_XY
      from &freq_xy;
   quit;

   /* 대칭 불확실도 및 상호정보량, 표준화 상호정보량 계산 */
   proc fedsql;
      drop table &result force;
      create table &result as
      select a.H_X, b.H_Y, c.H_XY,
             (a.H_X + b.H_Y - c.H_XY) as I_XY,
             sqrt(1 - exp(-2 * (a.H_X + b.H_Y - c.H_XY))) as SI,
             (a.H_X + b.H_Y - c.H_XY)/b.H_Y * 100. as LKR,
             2 * (a.H_X + b.H_Y - c.H_XY) / (a.H_X + b.H_Y) as SU
      from &ent_x as a, &ent_y as b, &ent_xy as c;
   quit;

   proc print data=&result label noobs;
      title "Mutual Information, Standardized MI, Leakage Rate and Symmetric Uncertainty between &x and &y";
   run;
%mend calc_lkr_su_entropy;
/* 사용방법 */
%calc_lkr_su_entropy(x=JOB, y=BAD, data=hmeq_partn, where=_partind_=0);

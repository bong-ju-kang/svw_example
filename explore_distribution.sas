%macro plot_hist;
  %let i = 1;
  %do %while(%scan(&nums, &i) ne );
    %let var = %scan(&nums, &i);

    proc sgplot data=hmeq_partn(where=(_partind_=0));
      title "히스토그램: &var";
      histogram &var;
    run;

    %let i = %eval(&i + 1);
  %end;
%mend;

%plot_hist;
title;

%macro plot_bar;
  %let i = 1;
  %do %while(%scan(&cats, &i) ne );
    %let var = %scan(&cats, &i);

    proc sgplot data=hmeq_partn(where=(_partind_=0));
      title "막대 그래프: &var";
      vbar &var / datalabel;
    run;

    %let i = %eval(&i + 1);
  %end;
%mend;

%plot_bar;

/* 목표변수에 대한 비율 막대 그래프프 */

proc freqtab data=hmeq_partn(where=(_partind_=0));
  tables &target / plots=freqplot(scale=percent);
run;




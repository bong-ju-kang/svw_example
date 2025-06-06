%macro calc_entropy(vars=, data=);

    %let nvar = %sysfunc(countw(&vars));
    
    %do i = 1 %to &nvar;
        %let var = %scan(&vars, &i);

        /* 빈도 계산 */
        proc freqtab data=&data noprint;
            tables &var / out=freq_hmeq;
        run;

        /* 표준 엔트로피 계산 */
        proc sql noprint;
            select count(*) into :num_cats
            from freq_hmeq
            ;
        quit;

        title "&var";
        proc fedsql;
            select sum(-percent/100 * log2(percent/100)) * 1/log2(&num_cats) as entropy
            from freq_hmeq
            ;
        quit;
        title;
    %end;
%mend;
/* 사용 방법 */
/* %calc_entropy(vars=REASON JOB, data=HMEQ); */
%calc_entropy(vars=&cats, data=HMEQ);
/* 상용 로그 변환 */
proc fedsql;
    drop table out_log force;
    create table out_log as 
    select 
        a.*,
        case 
            when a.mortdue is null then a.mortdue
            when a.mortdue >= 0 then log(a.mortdue + 1)
            when a.mortdue < 0 then log(a.mortdue + abs(b.min_mortdue) + 1)
        end as log_mortdue
    from 
        hmeq_partn as a,
        (select min(mortdue) as min_mortdue 
            from hmeq_partn 
            where _partind_ = 0) as b
    where a._partind_ = 0;
quit;
/* 결과 확인 */
proc fedsql;
    select mortdue, log_mortdue
    from out_log
    limit 5
    ;
quit;

ods graphics / reset width=1600px height=800px imagename="log_transform_histogram";
ods layout gridded columns=1 advance=table;

/* 원본 변수 히스토그램 */
proc sgplot data=out_log;
    title "원본 변수: mortdue";
    histogram mortdue / scale=percent;
    xaxis label="MORTDUE";
    yaxis label="Percent";
run;

/* 로그 변환된 변수 히스토그램 */
proc sgplot data=out_log;
    title "변환 변수: log_mortdue";
    histogram log_mortdue / scale=percent;
    xaxis label="LOG_MORTDUE";
    yaxis label="Percent";
run;

ods layout end;



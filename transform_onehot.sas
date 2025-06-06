
%let onehot_job = 
            case when job is null or job = '' then null 
             when job = 'Mgr'     then 1 else 0 end as JOB_MGR,
        case when job is null or job = '' then null 
             when job = 'Office'  then 1 else 0 end as JOB_OFFICE,
        case when job is null or job = '' then null 
             when job = 'ProfExe' then 1 else 0 end as JOB_PROFEXE,
        case when job is null or job = '' then null 
             when job = 'Sales'   then 1 else 0 end as JOB_SALES,
        case when job is null or job = '' then null 
             when job = 'Self'    then 1 else 0 end as JOB_SELF,
        case when job is null or job = '' then null 
             when job = 'Other'   then 1 else 0 end as JOB_OTHER
;


proc fedsql;
    drop table job_onehot force;

    create table job_onehot as
    select *, &onehot_job
    from hmeq_partn
    where _partind_ = 0;
quit;

proc sql;
  select name into :jobs separated by ','
  from dictionary.columns
  where libname = "WORK" and memname = "JOB_ONEHOT"
        and upcase(name) like "JOB%";
quit;

proc fedsql;
    select &jobs
    from job_onehot
    limit 5
    ;
quit;

libname model "&workspace_path./model";
/* 결정나무 모델 */
proc treesplit 
    data=hmeq_partn
    maxdepth=20
    ;
    class &cats &target;
    model &target = &xvars;
    grow entropy;
    prune cc;
    partition rolevar=_partind_(test='2' validate='1' train='0');
    /* 분석가게 모델 저장 */
    savestate rstore=model.astore_tree_hmeq; 
run;

/* 분석 가게 모델 확인 */
proc astore;
    describe rstore=model.astore_tree_hmeq;
run;

/* 분석 가게 모델을 이용한 점수화(scoring) */
proc astore;
    score 
        rstore=model.astore_tree_hmeq
        data=hmeq_partn
        out=hmeq_score
        copyvars=(_all_)
    ;
quit;

/* 확인 */
proc fedsql;
    select * 
    from hmeq_score
    limit 5
    ;
quit;

/* 모델 평가 */
proc assess 
    /* 검증 데이터 기준 */
    data=hmeq_score(where=(_partind_=1)) 
    /* ROC 그래프의 빈 개수 */
    ncuts=100
    /* LIFT의 빈(bin) 개수 */
    nbins=20
    rocout=out_roc_tree
    liftout=out_lift_tree
    fitstatout=out_stat_tree
    ;
    /* 예측 확률 변수 */
    input P_BAD1;                   
    /* 목표변수 */
    target BAD / level=nominal event='1';   
    /* 적합통계량을 구하기 위한 정보 입력 */
    /* 입력 변수외 예측정보 변수 및 이벤트 정의 */    
    fitstat pvar=P_BAD0 / pevent="0";     
run;

/* 출력 데이터: ROC */
proc contents data=out_roc_tree varnum;
run;

/* ROC 데이터 해석 */
proc fedsql;
	select _cutoff_
	, _tp_
	, _fp_
	, _fn_
	, _tn_
	, _sensitivity_
	, _fpr_
	from out_roc_tree
	limit 10
	;
quit;

/* AUC 값 */
proc sql noprint outobs=1;
    select round(_c_, 0.0001) into :auc
    from out_roc_tree;
quit;

/* ROC 그래프 그리기 */
proc sgplot data=out_roc_tree;
    series x=_FPR_ y=_Sensitivity_ / 
        lineattrs=(thickness=2 color=steelblue) 
        name="ROC" legendlabel="Tree Model ROC Curve"
        ;
    lineparm x=0 y=0 slope=1 / 
        lineattrs=(pattern=shortdash color=gray) 
        name="none" legendlabel="" 
        ;
    inset "Tree AUC = &auc" / 
        position=bottomright border
        ;
    keylegend "ROC" / 
        location=outside position=bottom
        ;
    xaxis label="False Positive Rate";
    yaxis label="True Positive Rate (Sensitivity)";
run;

/* 최적의 절사값 찾기 */
proc sql;
    select _cutoff_ into :optimal_cutoff
    from out_roc_tree
    /* _ks2_가 최대값일 때 _ks_=1 값을 갖음 */
    where _ks_=1 
    ;
quit;

/* 절사값 변경 */
data cutoff_result;
   set hmeq_score;
   where _partind_ = 1;

   pred_bad = (P_BAD1 >= 0.5);
   misclassified = (pred_bad ne BAD);
run;
proc means data=cutoff_result mean;
    class bad;
    var misclassified;
    title "절사값 0.5 기준 오분류율";
run;
title;

data cutoff_result;
   set hmeq_score;
   where _partind_ = 1;

   pred_bad = (P_BAD1 >= &optimal_cutoff);
   misclassified = (pred_bad ne BAD);
run;
proc means data=cutoff_result mean;
    class bad;
    var misclassified;
    title "절사값 &optimal_cutoff 기준 오분류율";
run;
title;



/* 1) 모델 저장용 라이브러리 지정 */
libname model "&workspace_path./model";

/* 2) 포레스트 모델 적합 */
proc forest
    /* 분석에 사용할 데이터 지정: 파티션된 hmeq_partn */
    data=hmeq_partn
    /* 부트스트랩 샘플 비율 설정 */
    inbagfraction=0.6
    /* 생성할 결정나무 수 지정 */
    ntrees=100
    /* 씨앗값 */
    seed=12345
    ;

    /* 3) 명목형(범주형) 입력 변수 지정 */
    input &cats / level=nominal;

    /* 4) 연속형 입력 변수 지정 */
    input &nums / level=interval;

    /* 5) 타깃(종속) 변수 지정 — 분류 모델용 명목형 */
    target &target / level=nominal;

    /* 6) 데이터 파티셔닝: _partind_ 값으로 역할 분할 */
    partition rolevar=_partind_(
        /* 학습 세트: 값이 '0'인 행 */
        train='0'
        /* 검증 세트: 값이 '1'인 행 */
        validate='1'
        /* 테스트 세트: 값이 '2'인 행 */
        test='2'
    );

    /* 7) 스코어링용 SAS 코드 생성 */
    code file='/workspaces/bnn/model/code_forest_hmeq.sas';

    /* 8) 학습된 모델 상태(Analytic Store) 저장 */
    savestate rstore=model.astore_forest_hmeq;

    /* 9) 모델 적합 통계치(Accuracy, AUC 등)를 out_fitstatistics_forest에 저장 */
    ods output fitstatistics=out_fitstatistics_forest;

quit;


/* 모델 안정성 평가 */
proc sgplot data=out_fitstatistics_forest;
    title "나무 개수에 따른 오분류율 변화";

    /* 각각 다른 선 패턴과 색상 적용 */
    series x=trees y=miscoob / 
        lineattrs=(color=blue pattern=solid thickness=2) 
        legendlabel="OOB 오분류율";

    series x=trees y=misctrain / 
        lineattrs=(color=green pattern=shortdash thickness=2) 
        legendlabel="훈련 오분류율";

    series x=trees y=miscvalid / 
        lineattrs=(color=red pattern=dot thickness=2) 
        legendlabel="검증 오분류율";

    xaxis label="나무 개수 (trees)";
    yaxis label="오분류율 (Misclassification Rate)";
    keylegend / location=inside position=topright across=1;
run;


/* 스코어링 */
/* 파이썬에서 만든 모델 불러오기 */
proc astore;
    describe store="&workspace_path./model/forest_model.astore";
quit;
/* 스코어 생성: 파이썬 모델 */
proc astore;
    score 
        store="&workspace_path./model/forest_model.astore"
        data=hmeq_partn
        out=hmeq_score_forest
        copyvars=(_all_);
quit;

/* 모델 정보 */
proc astore;
    describe rstore=model.astore_forest_hmeq;
quit;
/* 스코어 생성 */
proc astore;
    score data=hmeq_partn
        out=hmeq_score_forest
        rstore=model.astore_forest_hmeq
        copyvars=(_all_);
quit;

/* 확인 */
proc fedsql;
    select * 
    from hmeq_score_forest
    limit 5
    ;
quit;

/* 모델 평가 */
proc assess 
    data=hmeq_score_FOREST(where=(_partind_=1)) 
    ncuts=100 
    nbins=20 
    rocout=out_roc_FOREST
    liftout=out_lift_FOREST
    fitstatout=out_stat_FOREST
    ;
   input P_BAD1;  
   target BAD / level=nominal event='1'; 
   fitstat pvar=P_BAD0 / pevent='0';  
run;

/* AUC 값 */
proc sql outobs=1;
    select round(_c_, 0.0001) into :auc_FOREST
    from out_roc_FOREST;
quit;
%put &auc_FOREST;

/* ROC 그래프 그리기 */
proc sgplot data=out_roc_FOREST;
    series x=_FPR_ y=_Sensitivity_ / lineattrs=(thickness=2 color=steelblue) name="ROC" legendlabel="FOREST Model ROC Curve";
    lineparm x=0 y=0 slope=1 / lineattrs=(pattern=shortdash color=gray) legendlabel="" name="none";
    inset "FOREST AUC = &auc_FOREST" / position=bottomright border;
    keylegend "ROC" / location=outside position=bottom;
    xaxis label="False Positive Rate";
    yaxis label="True Positive Rate (Sensitivity)";
run;


/* 비교 그래프 */
/* 1단계: ROC 데이터를 병합 (모델 구분 컬럼 추가) */
proc fedsql;
    drop table roc_compare force;

    create table roc_compare as
    select a.*, 'FOREST' as model
    from out_roc_forest as a
    union all
    select b.*, 'TREE' as model
    from out_roc_tree as b
    ;
quit;

/* 2단계: ROC 곡선 비교 그래프 */
ods graphics / attrpriority=none; /* 색깔이외에도 적용 */
proc sgplot data=roc_compare;
    title "FOREST vs TREE 모델 ROC 곡선 비교";

    /* 그룹별 선 색상, 패턴, 마커 모양 설정 */
    styleattrs 
        datalinepatterns=(shortdash dash dot dashdotdot)      /* 선 패턴 */
        datacontrastcolors=(steelblue red)      /* 선 색 */
        datasymbols=(circlefilled squarefilled); /* 마커 */

    series x=_FPR_ y=_Sensitivity_ / 
        group=model
        lineattrs=(thickness=2)
        ;

    lineparm x=0 y=0 slope=1 / 
        lineattrs=(pattern=dot color=gray)
        legendlabel="Random Model";

    xaxis label="1 - Specificity (False Positive Rate)" values=(0 to 1 by 0.1);
    yaxis label="Sensitivity (True Positive Rate)" values=(0 to 1 by 0.1);

    keylegend / location=inside position=bottomright across=1;
run;
ods graphics;

/* 최적의 절사값 찾기 */
proc fedsql;
    select _cutoff_
    from out_roc_FOREST
    where _ks_=1
    ;
quit;
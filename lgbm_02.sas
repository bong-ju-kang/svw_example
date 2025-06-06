
/* 경량 그래디언트부스팅 모델 적합 */
/* 1) 모델 저장용 라이브러리 지정: Analytic Store를 저장할 경로 설정 */
libname model "&workspace_path./model";

/* 2) LIGHTGRADBOOST 프로시저 실행: LightGBM 방식의 그래디언트 부스팅 모델 적합 시작 */
proc lightgradboost
    /* 학습 데이터: 파티션된 hmeq_partn 중 _partind_=0(학습) 사용 */
    data=hmeq_partn(where=(_partind_=0))
    /* 최대 반복 횟수 설정: 150회 반복 */
    maxiters=150
    /* 각 부스팅 반복 시 전체 샘플 사용 (Bagging 비율 100%) */
    baggingfraction=1
    /* 각 노드 분할에 모든 특성 사용 (Input fraction 100%) */
    inputfraction=1
    /* 부스팅 알고리즘 지정: GBDT(Gradient Boosted Decision Trees) */
    boosting=GBDT
    /* 검증 데이터 지정: _partind_=1인 관측치로 검증 */
    validationdata=hmeq_partn(where=(_partind_=1))
    /* 랜덤 시드 고정: 결과 재현성 확보 */
    seed=1234
    ;

/* 3) 명목형(범주형) 입력 변수 지정 */
input &cats / level=nominal;

/* 4) 연속형 입력 변수 지정 */
input &nums / level=interval;

/* 5) 타깃(종속) 변수 지정 — 분류 모델용 명목형 */
target &target / level=nominal;

/* 6) 학습된 모델 상태를 Analytic Store로 저장 */
savestate rstore=model.astore_lgbm_hmeq;

/* 7) 반복 이력(Iteration History) 결과를 out_IterHistory_lgbm 데이터셋으로 저장 */
ods output IterHistory=out_IterHistory_lgbm;

/* 8) 프로시저 종료 */
quit;


/* 적합통계량 데이터 구조 */
proc contents data=out_IterHistory_lgbm;
run;
/* 모델 안정성 평가 */
proc sgplot data=out_IterHistory_lgbm;
    title "나무 개수에 따른 오분류율 변화";

    /* 각각 다른 선 패턴과 색상 적용 */
    series x=numberOfTrees y=trainingAccuracyMetric / 
        lineattrs=(color=green pattern=shortdash thickness=2) 
        legendlabel="훈련 오분류율";

    series x=numberOfTrees y=validationAccuracyMetric / 
        lineattrs=(color=red pattern=dot thickness=2) 
        legendlabel="검증 오분류율";

    xaxis label="나무 개수 (trees)";
    yaxis label="오분류율 (Misclassification Rate)";
    keylegend / location=inside position=topright across=1;
run;

/* 나무 개수 조정 필요 */

/* 스코어링 */
/* 모델 정보 */
proc astore;
    describe rstore=model.astore_lgbm_hmeq;
quit;

/* 스코어 생성 */
proc astore;
    score data=hmeq_partn
        out=hmeq_score_LGBM
        rstore=model.astore_lgbm_hmeq
        copyvars=(_all_);
        ;
quit;
/* 확인 */
proc fedsql;
    select * 
    from hmeq_score_LGBM
    limit 5
    ;
quit;

/* 모델 평가 */
proc assess 
    data=hmeq_score_LGBM(where=(_partind_=1)) /* 검증 데이터 기준 */
    ncuts=100 /* ROC 그래프의 빈 개수 */
    nbins=20 /* LIFT의 빈 개수 */
    rocout=out_roc_LGBM
    liftout=out_lift_LGBM
    fitstatout=out_stat_LGBM
    ;
   input P_BAD1;                   /* 예측 확률 변수 */
   target BAD / level=nominal event='1';   /* 목표변수 */
   fitstat pvar=P_BAD0 / pevent='0';     /* 나머지 클래스 확률 */
run;

/*  AUC */
proc sql outobs=1;
    select round(_c_, 0.0001) into :auc_LGBM
    from out_roc_LGBM;
quit;
%put &auc_LGBM;

/* 개별 ROC 그래프 그리기 */
proc sgplot data=out_roc_LGBM;
    series x=_FPR_ y=_Sensitivity_ / lineattrs=(thickness=2 color=steelblue) name="ROC" legendlabel="Tree Model ROC Curve";
    lineparm x=0 y=0 slope=1 / lineattrs=(pattern=shortdash color=gray) legendlabel="" name="none";
    inset "BOOSTING AUC = &auc_LGBM" / position=bottomright border;
    keylegend "ROC" / location=outside position=bottom;
    xaxis label="False Positive Rate";
    yaxis label="True Positive Rate (Sensitivity)";
run;

/* 1단계: ROC 데이터를 병합 (모델 구분 컬럼 추가) */
proc fedsql;
    drop table roc_compare force;

    create table roc_compare as
    select a.*, 'TREE' as model
    from out_roc_tree as a
    union all
    select b.*, 'FOREST' as model
    from out_roc_forest as b
    union all
    /* select c.*, 'BOOSTING' as model
    from out_roc_boosting as c
    union all */
    select c.*, 'LGBM' as model
    from out_roc_LGBM as c
    ;
quit;

/* 2단계: ROC 곡선 비교 그래프 */
ods graphics / attrpriority=none; /* 색깔이외에도 적용 */
proc sgplot data=roc_compare;
    title "ROC 그래프 비교";

    /* 그룹별 선 색상, 패턴, 마커 모양 설정 */
    styleattrs 
        datalinepatterns=(shortdash dash dot dashdotdot)      /* 선 패턴 */
        datacontrastcolors=(steelblue darkgreen red darkblue)      /* 선 색 */
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
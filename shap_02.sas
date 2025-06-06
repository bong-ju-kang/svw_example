
/*  특정 데이터 */
data hmeq_sample;
    set hmeq;
    if _n_=13 then output;
run;
proc print data=hmeq_sample;run;

/* 질의 데이터 */
data shap_query;
    set hmeq_partn(where=(_partind_=2));
    if _n_=1;
run;
/* 결과 확인 */
proc fedsql;
    select *
    from shap_query
    ;
quit;

/* 1) 모델 저장 위치를 "model" 라이브러리로 할당합니다. */
/*    이 경로에 ASTORE 모델 파일이 읽혀지고 저장됩니다. */
libname model "&workspace_path./model";

/* 2) SHAPLEY 프로시저 시작: 개별 관측치에 대한 Shapley 값을 계산합니다. */

proc SHAPLEY
    /* 설명 대상(쿼리) 단일 행 테이블 */
    data=shap_query      
    /* 참조 데이터 */
    referencedata=hmeq_partn(where=(_partind_=0))
    ;

/* 3) ASTORE 모델 불러오기: LightGBM 모델을 analytic store에서 조회합니다. */
    astoremodel rstore=model.astore_LGBM_HMEQ;

/* 4) 명목형 변수 입력 (범주형 변수) */
/*    &cats 매크로에 지정된 변수들을 모두 nominal(범주형)으로 처리 */
    input &cats / level=nominal;

/* 5) 연속형 변수 입력 */
/*    &nums 매크로에 지정된 변수들을 interval(연속)으로 처리 */
    input &nums / level=interval;

/* 6) 예측 대상 변수 지정 */
/*    p_bad1 변수에 저장된 'Bad1' 클래스(probability)를 Shapley 계산 대상으로 사용 */
    predictedtarget p_bad1;

/* 7) ODS 출력 설정 */
/*    계산된 Shapley 값 결과를 "shapleyValues_hmeq" 데이터셋에 저장 */
    ods output shapleyvalues=shapleyValues_hmeq;
run;



/* SHAP 그래프 */
proc sgplot data=shapleyValues_hmeq;
  /* HBARPARM 에서는 DISCRETEORDER=DATA 가 먹힙니다 */
  hbarparm 
    category=Variable 
    response=ShapleyValue 
    / datalabel 
      fillattrs=(color=CX4F81BD)
  ;
  xaxis label="Shapley Value";
  yaxis display=(nolabel);
  title "Shapley Values (데이터 순서)";
run;

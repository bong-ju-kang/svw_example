/* 모델 적합 */
/* 1) 모델 저장용 라이브러리 지정: Analytic Store를 저장할 경로 설정 */
libname model "&workspace_path./model";

/* 2) NNET 프로시저 호출: 다층 퍼셉트론 신경망 모델 적합 시작
     - DATA=hmeq_partn           : 파티션된 학습 데이터 사용
     - MISSING=MEAN              : 결측치는 평균으로 대체
     - STANDARDIZE=MIDRANGE      : 입력 변수는 중간값−범위 방식 표준화 */
proc nnet 
    data=hmeq_partn
    missing=mean
    standardize=midrange
    ;

/* 3) 명목형(범주형) 입력 변수 지정 */
input &cats / level=nominal;

/* 4) 연속형 입력 변수 지정 */
input &nums / level=interval;

/* 5) 목표표(종속) 변수 지정 — 분류용 명목형 */
target &target / level=nominal;

/* 6) 신경망 구조 설정 — 다층 퍼셉트론(MLP) */
architecture mlp;

/* 7) 최적화 알고리즘 및 반복횟수 설정
     - ALGORITHM=LBFGS         : L-BFGS 알고리즘 사용
     - MAXITER=100             : 최대 100회 반복 */
optimization algorithm=lbfgs maxiter=100;

/* 8) 은닉층 구성: 첫 번째 은닉층 4유닛, 활성함수 TANH */
hidden 4 / act=tanh;
/*    두 번째 은닉층층 4유닛, 활성함수 TANH */
hidden 4 / act=tanh;

/* 9) 훈련 제어 설정
     - NUMTRIES=1               : 초기값 시도 1회
     - SEED=1234                : 랜덤 시드 고정
     - OUTMODEL=…               : 학습된 모델을 모델라이브러리에 저장 */
train numtries=1 seed=1234 outmodel=model.outmodel_nnet_hmeq;

/* 10) 데이터 분할할: _partind_ 값으로 학습(0), 검증(1), 테스트(2) 분할 */
partition rolevar=_partind_(train='0' validate='1' test='2');

/* 11) 스코어링용 DATA step 코드 생성 */
code file='/workspaces/bnn/model/code_nnet_hmeq.sas';

/* 12) 학습된 모델 상태 저장 (Analytic Store) */
savestate rstore=model.astore_nnet_hmeq;

/* 13) 최적화 반복 이력(Iteration History)을 out_OptIterHistory_nnet에 저장 */
ods output OptIterHistory=out_OptIterHistory_nnet;

/* 14) 프로시저 종료 */
quit;


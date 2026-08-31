# Stage 2D XGBoost Cost Model Patch

Paste this patch into:
C:\Users\adilm\Projects\cost_prediction_xgboost_stage1

IMPORTANT: stop the currently running XGBoost API first with Ctrl+C.

After paste:
1. cd /d "C:\Users\adilm\Projects\cost_prediction_xgboost_stage1"
2. .venv\Scripts\activate
3. python scripts\train_xgboost.py
4. python -m scripts.test_api
5. If API TEST PASSED:
   python -m uvicorn api.main:app --host 127.0.0.1 --port 8001

Keep that window open, then install/test the main-project Stage 2D patch.

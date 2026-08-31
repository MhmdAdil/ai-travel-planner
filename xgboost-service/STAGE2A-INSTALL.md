# Cost Prediction Stage 2A — XGBoost API

This is an **add-only patch** for the separate folder:

`C:\Users\adilm\Projects\cost_prediction_xgboost_stage1`

Do NOT copy it into `ai-travel-planner`.

## It adds
- `api/main.py`
- `api/__init__.py`
- `scripts/test_api.py`
- `scripts/run_api.bat`
- `requirements-stage2-api.txt`

It does not overwrite your models or training dataset.

## Install

Extract this patch and copy its contents into:

`C:\Users\adilm\Projects\cost_prediction_xgboost_stage1`

Choose merge folders if Windows asks.

Open CMD:

```cmd
cd /d "C:\Users\adilm\Projects\cost_prediction_xgboost_stage1"
.venv\Scripts\activate
pip install -r requirements-stage2-api.txt
python scripts\test_api.py
```

Expected final line:

`API TEST PASSED`

Then run the server:

```cmd
python -m uvicorn api.main:app --host 127.0.0.1 --port 8001
```

Expected:

`Uvicorn running on http://127.0.0.1:8001`

Keep this CMD open. The next stage connects Spring Boot to port 8001.

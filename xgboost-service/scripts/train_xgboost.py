from pathlib import Path
import json
import numpy as np
import pandas as pd
import joblib

from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from xgboost import XGBRegressor

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data" / "cost_prediction_training.csv"
MODELS = ROOT / "models"
MODELS.mkdir(exist_ok=True)

df = pd.read_csv(DATA)
targets = ["accommodation_cost_lkr","food_cost_lkr","transport_cost_lkr","activities_cost_lkr"]
X = df.drop(columns=targets + ["total_cost_lkr","data_origin"])
categorical = ["budget_level","accommodation_type","food_preference","transport_mode","pace"]
numeric = [c for c in X.columns if c not in categorical]

prep = ColumnTransformer([
    ("cat", OneHotEncoder(handle_unknown="ignore", sparse_output=False), categorical),
    ("num", "passthrough", numeric),
], verbose_feature_names_out=False)

X_train, X_test, idx_train, idx_test = train_test_split(
    X, np.arange(len(X)), test_size=0.20, random_state=42
)

pred_parts = {}
metrics = {}
for target in targets:
    y = df[target].values
    model = XGBRegressor(
        n_estimators=300, max_depth=7, learning_rate=0.06,
        subsample=0.9, colsample_bytree=0.9,
        objective="reg:squarederror", random_state=42, n_jobs=4, reg_lambda=1.2,
    )
    pipe = Pipeline([("prep", prep), ("model", model)])
    pipe.fit(X_train, y[idx_train])
    pred = np.maximum(pipe.predict(X_test), 0)
    pred_parts[target] = pred
    metrics[target] = {
        "MAE_LKR": float(mean_absolute_error(y[idx_test], pred)),
        "RMSE_LKR": float(mean_squared_error(y[idx_test], pred) ** 0.5),
        "R2": float(r2_score(y[idx_test], pred)),
    }
    joblib.dump(pipe, MODELS / f"{target.replace('_cost_lkr','')}_xgboost.joblib")

total_pred = sum(pred_parts.values())
actual_total = df.iloc[idx_test]["total_cost_lkr"].values
metrics["total_from_components"] = {
    "MAE_LKR": float(mean_absolute_error(actual_total, total_pred)),
    "RMSE_LKR": float(mean_squared_error(actual_total, total_pred) ** 0.5),
    "R2": float(r2_score(actual_total, total_pred)),
}
(ROOT / "metrics.json").write_text(json.dumps(metrics, indent=2))
print(json.dumps(metrics, indent=2))

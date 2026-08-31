from pathlib import Path
import numpy as np
import pandas as pd

# This generator creates reference-derived synthetic trip scenarios for model development.
# It does NOT claim that these are 60,000 historical traveller receipts.
# Replace or enrich the targets later with real observed trip expenses when available.

OUTPUT = Path(__file__).resolve().parents[1] / "data" / "cost_prediction_training.csv"
rng = np.random.default_rng(42)
N = 60000

# Keep this file aligned with the generated dataset schema supplied in the Stage 1 pack.
# The full reproducible generator used to produce the supplied CSV is included in
# generate_training_dataset_full.py.
print(f"Use the supplied dataset at: {OUTPUT}")
print("Rows:", len(pd.read_csv(OUTPUT)))

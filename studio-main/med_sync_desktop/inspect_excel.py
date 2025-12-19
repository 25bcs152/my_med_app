
import pandas as pd
import os

files = [
    r"c:\New folder\studio-main\xlsx\stock_REPORTS MARG AS ON 03.12.25.xlsx",
    r"c:\New folder\studio-main\xlsx\PMBI STOCK REOPRTS AS ON 02.12.25.xlsx"
]

for file_path in files:
    try:
        print(f"\nProcesing: {file_path}")
        # Read the first few rows to inspect headers
        df = pd.read_excel(file_path, header=0, nrows=5)
        print("--- COLUMNS ---")
        print(df.columns.tolist())
        print("--- SAMPLE DATA ---")
        print(df.head(2).to_string())
        
    except Exception as e:
        print(f"Error reading {file_path}: {e}")

import pandas as pd
import os

files = [
    r'c:\New folder\studio-main\xlsx\stock_REPORTS MARG AS ON 03.12.25.xlsx',
    r'c:\New folder\studio-main\xlsx\PMBI STOCK REOPRTS AS ON 02.12.25.xlsx'
]

for f in files:
    if os.path.exists(f):
        print(f"--- Headers for {os.path.basename(f)} ---")
        try:
            df = pd.read_excel(f, nrows=0)
            print(df.columns.tolist())
        except Exception as e:
            print(f"Error reading {f}: {e}")
    else:
        print(f"File not found: {f}")

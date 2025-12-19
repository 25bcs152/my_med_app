import pandas as pd

# Check StockReport.xlsx (PMBI - Medicine 2)
print("="*60)
print("StockReport.xlsx (PMBI - Medicine 2)")
print("="*60)
df = pd.read_excel(r'c:\New folder\studio-main\xlsx\StockReport.xlsx', header=None)
print(f"Total rows: {len(df)}")
print("\nFirst 10 rows (raw):")
for i in range(min(10, len(df))):
    print(f"Row {i}: {df.iloc[i].tolist()}")

# Check hsncodemaster.xls (Marg - Medicine 1)  
print("\n" + "="*60)
print("hsncodemaster.xls (Marg - Medicine 1)")
print("="*60)
try:
    # Try openpyxl first (for .xls saved as .xlsx actually)
    df2 = pd.read_excel(r'c:\New folder\studio-main\xlsx\hsncodemaster.xls', header=None, engine='openpyxl')
    print(f"Total rows: {len(df2)}")
    print("\nFirst 10 rows (raw):")
    for i in range(min(10, len(df2))):
        print(f"Row {i}: {df2.iloc[i].tolist()}")
except Exception as e:
    print(f"Error with openpyxl: {e}")
    print("File might be actual .xls format, need xlrd library")

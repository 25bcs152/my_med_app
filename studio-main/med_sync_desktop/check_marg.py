import pandas as pd

# Check hsncodemaster.xls (Marg - Medicine 1)  
print("="*60)
print("hsncodemaster.xls (Marg - Medicine 1)")
print("="*60)
df = pd.read_excel(r'c:\New folder\studio-main\xlsx\hsncodemaster.xls', header=None, engine='xlrd')
print(f"Total rows: {len(df)}")
print("\nFirst 15 rows (raw):")
for i in range(min(15, len(df))):
    row_data = df.iloc[i].tolist()
    # Clean up display
    row_display = [str(x) if pd.notna(x) else 'nan' for x in row_data]
    print(f"Row {i}: {row_display[:10]}")  # Show first 10 columns

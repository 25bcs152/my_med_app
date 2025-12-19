import pandas as pd

# Check 'stock_81.xls' (New Marg File)
print("="*60)
print("Checking stock_81.xls (New Marg File)")
print("="*60)
try:
    # It has .xls extension, try xlrd first
    df = pd.read_excel(r'c:\New folder\studio-main\xlsx\stock_81.xls', header=None, engine='xlrd')
    print(f"Total rows: {len(df)}")
    print("\nFirst 15 rows (raw):")
    # Set pandas options to show all columns
    pd.set_option('display.max_columns', None)
    pd.set_option('display.width', 1000)
    
    # Print first 15 rows cleanly
    for i in range(min(15, len(df))):
        row = df.iloc[i].tolist()
        # Clean nulls for display
        clean_row = [str(x) if pd.notna(x) else '' for x in row]
        print(f"Row {i}: {clean_row}")

except Exception as e:
    print(f"Error reading with xlrd: {e}")
    # Try openpyxl just in case it's an xlsx renamed
    try:
        print("Trying openpyxl...")
        df = pd.read_excel(r'c:\New folder\studio-main\xlsx\stock_81.xls', header=None, engine='openpyxl')
        print("Success with openpyxl!")
        print(df.head(5))
    except Exception as e2:
        print(f"Error with openpyxl: {e2}")


import sys
import json
import pandas as pd
import os
import re
from datetime import datetime

def normalize_header(h):
    return str(h).strip().lower().replace(' ', '').replace('.', '').replace('_', '')

def parse_date(val):
    if pd.isna(val):
        return None
    s = str(val).strip()
    if not s:
        return None
    
    # Try parsing common formats
    formats = [
        '%d-%b-%y', # 01-May-27
        '%d-%m-%Y', 
        '%Y-%m-%d', 
        '%Y-%m-%d %H:%M:%S', # Pandas default string
        '%d/%m/%Y',
        '%d%m%Y',
        '%d%m%y'
    ]
    
    for fmt in formats:
        try:
            dt = datetime.strptime(s, fmt)
            return dt.strftime('%d-%m-%y') # Return dd-MM-yy
        except ValueError:
            continue
            
    # Return as is if acts like a string? Or try to clean?
    # For now return original if parsing fails (maybe it's already correct or weird format)
    return s

def process_file(file_path, file_type):
    try:
        # Determine engine
        ext = os.path.splitext(file_path)[1].lower()
        engine = 'xlrd' if ext == '.xls' else 'openpyxl'
        
        # Read file
        # We read valid rows. Find header first?
        # Let's read first few rows to find header
        df_scan = pd.read_excel(file_path, nrows=20, header=None, engine=engine)
        
        header_row_idx = -1
        keywords = []
        if file_type == 'marg':
            keywords = ['productname', 'currentstock', 'mrp', 'exp']
        else:
            keywords = ['drugname', 'drugcode', 'mrp', 'expirydate', 'qty']
            
        # Find header
        for i, row in df_scan.iterrows():
            row_str = "".join([str(x).lower() for x in row if pd.notna(x)])
            matches = sum(1 for k in keywords if k in row_str.replace(' ', '').replace('.', ''))
            if matches >= 2: # At least 2 matches
                header_row_idx = i
                break
        
        if header_row_idx == -1:
            header_row_idx = 0 # Fallback
            
        # Read actual data
        df = pd.read_excel(file_path, header=header_row_idx, engine=engine)
        
        # Normalize columns
        df.columns = [normalize_header(c) for c in df.columns]
        
        results = []
        
        # Define mappings (normalized -> target key)
        mapping = {}
        if file_type == 'marg':
            # Target: Product Name, Current Stock, M.R.P., EXP
            # Source (normalized): productname, currentstock, mrp, exp
            mapping = {
                'productname': 'Product Name',
                'name': 'Product Name',
                'itemname': 'Product Name',
                'productname_kn': 'Product Name_kn',
                'productname_kan': 'Product Name_kn',
                'currentstock': 'Current Stock',
                'stock': 'Current Stock',
                'qty': 'Current Stock',
                'mrp': 'M.R.P.',
                'rate': 'M.R.P.',
                'exp': 'EXP',
                'expiry': 'EXP'
            }
        else:
            # Target: Drug Name, Drug Code, MRP, Expiry Date, Qty
            mapping = {
                'drugname': 'Drug Name',
                'drugname_kn': 'Drug Name_kn',
                'drugname_kan': 'Drug Name_kn',
                'drugcode': 'Drug Code',
                'code': 'Drug Code',
                'mrp': 'MRP',
                'expirydate': 'Expiry Date',
                'exp': 'Expiry Date',
                'expiry': 'Expiry Date',
                'qty': 'Qty',
                'quantity': 'Qty',
                'stock': 'Qty',
                'uom': 'UOM',
                'batchno': 'Batch No'
            }
            
        # Helper to find column
        col_map = {}
        for col in df.columns:
            for k, v in mapping.items():
                if k in col: # Contain check? or exact?
                    # Be strict if possible, or permissive
                    # "m.r.p." -> "mrp"
                    if k == col or k == col.replace('.',''):
                        col_map[v] = col
                        break
        
        # Process rows
        for _, row in df.iterrows():
            item = {}
            has_data = False
            
            for target_key, src_col in col_map.items():
                val = row[src_col]
                if pd.isna(val):
                    continue
                    
                has_data = True
                
                # Format
                if 'mrp' in target_key.lower():
                    try:
                        # Store as float for numeric operations/sorting
                        # Display handling (2 decimals) is done in Flutter
                        item[target_key] = float(val)
                    except:
                        item[target_key] = 0.0
                elif 'qty' in target_key.lower() or 'stock' in target_key.lower():
                    try:
                        item[target_key] = str(int(float(val)))
                    except:
                        item[target_key] = str(val)
                elif 'exp' in target_key.lower():
                    item[target_key] = parse_date(val)
                else:
                    item[target_key] = str(val).strip()
            
            # Generate ID
            if file_type == 'marg':
                # Marg: Use Product Name
                name_key = 'Product Name'
                if name_key in item and item[name_key]:
                    doc_id = item[name_key].replace('/', '-').replace('\\', '-').strip()
                    doc_id = re.sub(r'[^\w\-. ]', '_', doc_id)
                    if len(doc_id) > 150: doc_id = doc_id[:150]
                    item['_id'] = doc_id
                    results.append(item)
            else:
                # PMBI: Use Drug Code (preferred) or Fallback to Drug Name
                # Drug Code is cleaner and unique
                code_key = 'Drug Code'
                name_key = 'Drug Name'
                
                doc_id = None
                if code_key in item and item[code_key]:
                    doc_id = str(item[code_key]).strip()
                elif name_key in item and item[name_key]:
                     doc_id = item[name_key].replace('/', '-').replace('\\', '-').strip()
                
                if doc_id:
                    # Sanitize ID to be safe for Firestore
                    doc_id = re.sub(r'[^\w\-. ]', '_', doc_id)
                    if len(doc_id) > 150: doc_id = doc_id[:150]
                    item['_id'] = doc_id
                    results.append(item)
                
        print(json.dumps(results))
        
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(json.dumps({"error": "Usage: process_excel.py <path> <type>"}))
        sys.exit(1)
        
    process_file(sys.argv[1], sys.argv[2])

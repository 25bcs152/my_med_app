#!/usr/bin/env python3
"""
desk.py - GUI Firestore Dual Importer (strict fields + smart header normalization)

Behavior:
 - Tkinter window with Browse buttons for serviceAccount.json, MARG .xlsx, PMBI .xlsx
 - "Start Import" button: confirms deletion of top-level collections, deletes them, then uploads
 - MARG -> medicine-1: only uploads Product Name, Current Stock, M.R.P., EXP
 - PMBI -> medicine-2: only uploads Drug Code, Drug Name, UOM, Batch No, Expiry Date, Qty, MRP
 - Header names are normalized (strip, lowercase, remove punctuation) and auto-mapped
 - Dates are stored as Python datetime objects (Admin SDK converts to Firestore timestamp)
 - Batched writes (<= 400)
 - Logs shown in GUI
 - Requires: firebase-admin, pandas, openpyxl
"""
import tkinter as tk
from tkinter import filedialog, messagebox, scrolledtext
import threading, time, traceback, re, math
from datetime import datetime

import pandas as pd
import firebase_admin
from firebase_admin import credentials, firestore

# ---------------------------
# GUI logging helper
# ---------------------------
def gui_log(msg: str):
    ts = datetime.now().strftime("%H:%M:%S")
    line = f"{ts} - {msg}"
    def _append():
        log_box.configure(state="normal")
        log_box.insert(tk.END, line + "\n")
        log_box.see(tk.END)
        log_box.configure(state="disabled")
    root.after(1, _append)

# ---------------------------
# Utilities
# ---------------------------
def sanitize_doc_id(s: str) -> str:
    if not s:
        return ""
    s = str(s).strip().replace("/", "-")[:200]
    return re.sub(r"[^\w\-. ]", "_", s)

def parse_number(v):
    if v is None: return None
    if isinstance(v, (int, float)) and not (isinstance(v, float) and math.isnan(v)):
        return float(v)
    s = str(v).strip().replace(",", "")
    if s == "": return None
    try: return float(s)
    except: return None

def parse_int(v):
    if v is None: return None
    if isinstance(v, int): return v
    if isinstance(v, float) and not math.isnan(v): return int(v)
    s = str(v).strip().replace(",", "")
    if s == "": return None
    try: return int(float(s))
    except: return None

def parse_date(v):
    if v is None: return None
    if isinstance(v, datetime): return v
    s = str(v).strip()
    if s == "": return None
    fmts = ["%d/%m/%Y","%d-%m-%Y","%Y-%m-%d","%d/%m/%y","%m/%d/%Y"]
    for f in fmts:
        try:
            return datetime.strptime(s, f)
        except:
            pass
    try:
        dt = pd.to_datetime(s, dayfirst=True, errors="coerce")
        if pd.isna(dt): return None
        return dt.to_pydatetime()
    except:
        return None

def normalize_header_key(h):
    """Normalize header: lowercase, strip, remove non-alnum (but keep letters/numbers)."""
    if h is None: return ""
    s = str(h).strip().lower()
    # replace common separators with nothing
    s = re.sub(r"[^\w]", "", s)  # removes spaces, dots, slashes, hyphens
    return s

def row_summary(row, limit=4):
    pairs = []
    for k, v in row.items():
        pairs.append(f"{k}:{str(v)[:18]}")
        if len(pairs) >= limit: break
    return " | ".join(pairs)

# ---------------------------
# Firestore helpers
# ---------------------------
def init_db(sa_path):
    cred = credentials.Certificate(sa_path)
    try:
        firebase_admin.get_app()
    except ValueError:
        firebase_admin.initialize_app(cred)
    return firestore.client()

def delete_all_collections(db):
    gui_log("Skipping deletion of all collections to save writes (Metadata Only Strategy).")
    return
    # gui_log("Deleting ALL top-level collections...")
    colls = list(db.collections())
    if not colls:
        gui_log("No top-level collections found.")
        return
    for c in colls:
        cname = c.id
        gui_log(f"Deleting collection: {cname}")
        while True:
            docs = list(db.collection(cname).limit(400).stream())
            if not docs:
                gui_log(f"  {cname} cleared.")
                break
            batch = db.batch()
            for d in docs:
                batch.delete(d.reference)
            batch.commit()
            time.sleep(0.05)

# ---------------------------
# Excel reading + header detection
# ---------------------------
def read_excel_rows(path):
    try:
        df = pd.read_excel(path, dtype=object, header=0)
    except Exception as e:
        gui_log(f"Error reading '{path}': {e}")
        raise

    cols = list(df.columns)
    # attempt to detect header if Unnamed...
    if any(str(c).startswith("Unnamed") or re.fullmatch(r"\d+", str(c)) for c in cols[:6]):
        raw = pd.read_excel(path, dtype=object, header=None)
        def looks_like_header(row):
            letters = sum(1 for x in row if isinstance(x, str) and re.search(r"[A-Za-z]", x))
            return letters >= max(1, len(row)//5)
        header_idx = None
        for i in range(min(6, len(raw))):
            if looks_like_header(raw.iloc[i].tolist()):
                header_idx = i
                break
        if header_idx is not None:
            df = pd.read_excel(path, dtype=object, header=header_idx)
            gui_log(f"Auto-detected header row {header_idx} for '{path}'")
        else:
            gui_log(f"Using first row as header for '{path}'")

    df = df.where(pd.notnull(df), None)
    rows = df.to_dict(orient="records")
    detected_cols = [str(c) for c in df.columns]
    gui_log(f"Detected columns for '{path}': {detected_cols}")
    if rows:
        gui_log(f"Sample row -> {row_summary(rows[0])}")
    return rows, detected_cols

# ---------------------------
# Smart header -> canonical mapping
# ---------------------------
# Canonical fields for MARG and PMBI (strict)
MARG_ALLOWED = {"Product Name", "Current Stock", "M.R.P.", "EXP"}
PMBI_ALLOWED = {"Drug Code", "Drug Name", "UOM", "Batch No", "Expiry Date", "Qty", "MRP"}

def smart_map_header(orig_header):
    """
    Return canonical field name if header maps to something we care about, else None.
    Uses normalized key and keyword matching.
    """
    nk = normalize_header_key(orig_header)
    # direct known mappings
    if nk in ("productname","product","product_name","name"):
        return "Product Name"
    if nk in ("currentstock","current_stock","stock","quantity"):
        return "Current Stock"
    # MRP variations
    if "mrp" in nk or nk in ("m.r.p","mrp.","m_r_p","price","rate"):
        # for MARG we use "M.R.P." canonical; for PMBI canonical later will be "MRP"
        return "M.R.P."  # we'll also accept MARG's M.R.P.; for PMBI we map to MRP later
    # expiry/exp variations
    if "exp" == nk or nk.startswith("exp") or "expiry" in nk or "bestbefore" in nk or "bb" == nk:
        # ambiguous: MARG uses "EXP" canonical; PMBI uses "Expiry Date"
        # We'll return a marker; decision later depends on target collection.
        return "EXP_OR_EXPIRY"
    # PMBI-specific mappings
    if "drugcode" in nk or nk == "code":
        return "Drug Code"
    if "drugname" in nk or ("drug" in nk and "name" in nk):
        return "Drug Name"
    if nk == "uom":
        return "UOM"
    if "batch" in nk:
        return "Batch No"
    if nk in ("qty","quantity","qnty"):
        return "Qty"
    # last fallback: exact "mrp" handled earlier; if nk contains 'mrp' returned already
    return None

# ---------------------------
# Upload logic (uses smart_map_header)
# ---------------------------
def upload_collection_strict(db, collection_name, rows, base_candidates, write_to_firestore=False):
    coll_ref = db.collection(collection_name)
    uploaded = 0; skipped = 0; failed = 0
    # Batch is only needed if write_to_firestore is True
    batch = db.batch(); batch_count = 0; BATCH_LIMIT = 400
    uploaded_items = [] # Collect items for metadata

    def find_base_value(row):
        for cand in base_candidates:
            if cand in row and row[cand] not in (None, ""):
                return row[cand]
        cand_norms = [normalize_header_key(c) for c in base_candidates]
        for k, v in row.items():
            if v in (None, ""): continue
            if normalize_header_key(k) in cand_norms:
                return v
        # header containing name+product/drug
        for k, v in row.items():
            if v in (None, ""): continue
            nk = normalize_header_key(k)
            if ("name" in nk) and ("product" in nk or "drug" in nk):
                return v
        return None

    for row in rows:
        try:
            base_val = find_base_value(row)
            if base_val is None:
                skipped += 1
                gui_log(f"Skipping row (no base): {row_summary(row)}")
                continue

            doc_id = sanitize_doc_id(base_val)
            data = {}

            # iterate original headers -> map to canonical if relevant
            for orig_header, val in row.items():
                mapped = smart_map_header(orig_header)
                if mapped is None:
                    continue

                # if smart_map returned "EXP_OR_EXPIRY", decide canonical per target collection
                if mapped == "EXP_OR_EXPIRY":
                    if collection_name == "medicine-1":
                        canonical = "EXP"
                    else:
                        canonical = "Expiry Date"
                else:
                    # special case: smart_map returns "M.R.P." for MRPs; PMBI wants "MRP" canonical
                    if mapped == "M.R.P." and collection_name == "medicine-2":
                        canonical = "MRP"
                    else:
                        canonical = mapped

                # ensure canonical is allowed for this collection
                if collection_name == "medicine-1":
                    if canonical not in MARG_ALLOWED:
                        continue
                else:
                    if canonical not in PMBI_ALLOWED:
                        continue

                # parse values
                if canonical in ("M.R.P.", "MRP"):
                    parsed = parse_number(val)
                    data[canonical] = parsed if parsed is not None else (val if val is not None else None)
                elif canonical in ("Current Stock", "Qty"):
                    parsed = parse_int(val)
                    data[canonical] = parsed if parsed is not None else (val if val is not None else None)
                elif canonical in ("EXP", "Expiry Date"):
                    parsed_date = parse_date(val)
                    if parsed_date:
                        data[canonical] = parsed_date
                    else:
                        data[canonical] = val if val is not None else None
                else:
                    data[canonical] = val

            # ensure base field exists under canonical name
            if collection_name == "medicine-1":
                if "Product Name" not in data:
                    data["Product Name"] = base_val
            else:
                if "Drug Name" not in data:
                    data["Drug Name"] = base_val

            data["_imported_at"] = firestore.SERVER_TIMESTAMP

            # Prepare metadata item (needs explicit ID)
            meta_item = data.copy()
            meta_item['id'] = doc_id
            uploaded_items.append(meta_item)

            if write_to_firestore:
                batch.set(coll_ref.document(doc_id), data)
                batch_count += 1
                
                if batch_count >= BATCH_LIMIT:
                    batch.commit()
                    batch = db.batch()
                    batch_count = 0
            
            uploaded += 1

        except Exception as e:
            failed += 1
            gui_log(f"Failed writing row for base '{base_val if 'base_val' in locals() else 'unknown'}': {e}")
            traceback.print_exc()

    if write_to_firestore and batch_count > 0:
        batch.commit()

    return uploaded, skipped, failed, uploaded_items

# ---------------------------
# Worker thread
# ---------------------------
def start_import_thread():
    threading.Thread(target=run_import, daemon=True).start()

def run_import():
    try:
        sa_path = ent_sa.get().strip()
        marg_path = ent_marg.get().strip()
        pmbi_path = ent_pmbi.get().strip()

        if not sa_path:
            messagebox.showerror("Missing", "Select serviceAccount.json")
            return
        if not marg_path and not pmbi_path:
            messagebox.showerror("Missing", "Select at least one Excel file (MARG or PMBI)")
            return

        gui_log("Initializing Firebase...")
        try:
            db = init_db(sa_path)
        except Exception as e:
            gui_log(f"Firebase init failed: {e}")
            messagebox.showerror("Firebase init failed", str(e))
            return

        if not messagebox.askyesno("Confirm", "This will overwrite the metadata documents. Old collections will NOT be deleted (to save writes).\n\nContinue?"):
            gui_log("User cancelled operation.")
            return

        delete_all_collections(db)

        if marg_path:
            gui_log(f"Reading MARG: {marg_path}")
            rows_marg, cols_marg = read_excel_rows(marg_path)
            gui_log(f"MARG raw headers: {cols_marg}")
            base_candidates_marg = ["Product Name", "ProductName", "product name", "Product", "name"]
            gui_log("Uploading MARG -> medicine-1 (Product Name, Current Stock, M.R.P., EXP)...")
            # write_to_firestore=False to save writes
            up, sk, fl, items1 = upload_collection_strict(db, "medicine-1", rows_marg, base_candidates_marg, write_to_firestore=False)
            gui_log(f"MARG summary: processed={up}, skipped={sk}, failed={fl}")
            
            if items1:
                gui_log(f"Updating metadata/medicine_1_data with {len(items1)} items...")
                db.collection('metadata').document('medicine_1_data').set({'items': items1})
                gui_log("metadata/medicine_1_data updated.")

        if pmbi_path:
            gui_log(f"Reading PMBI: {pmbi_path}")
            rows_pmbi, cols_pmbi = read_excel_rows(pmbi_path)
            gui_log(f"PMBI raw headers: {cols_pmbi}")
            base_candidates_pmbi = ["Drug Name", "DrugName", "drug name", "Drug", "name"]
            gui_log("Uploading PMBI -> medicine-2 (Drug Code, Drug Name, UOM, Batch No, Expiry Date, Qty, MRP)...")
            # write_to_firestore=False to save writes
            up2, sk2, fl2, items2 = upload_collection_strict(db, "medicine-2", rows_pmbi, base_candidates_pmbi, write_to_firestore=False)
            gui_log(f"PMBI summary: processed={up2}, skipped={sk2}, failed={fl2}")

            if items2:
                gui_log(f"Updating metadata/medicine_2_data with {len(items2)} items...")
                db.collection('metadata').document('medicine_2_data').set({'items': items2})
                gui_log("metadata/medicine_2_data updated.")

        gui_log("=== IMPORT FINISHED ===")
        messagebox.showinfo("Done", "Import finished. See log for details.")

    except Exception as e:
        gui_log(f"Unhandled error: {e}")
        traceback.print_exc()
        messagebox.showerror("Unhandled error", str(e))

# ---------------------------
# GUI layout
# ---------------------------
root = tk.Tk()
root.title("Firestore Dual Importer — smart header mapping")
root.geometry("980x660")

frame = tk.Frame(root)
frame.pack(fill="both", expand=True, padx=12, pady=10)

# Service account
tk.Label(frame, text="Service Account JSON:").grid(row=0, column=0, sticky="w")
ent_sa = tk.Entry(frame, width=88)
ent_sa.grid(row=0, column=1, sticky="w")
def browse_sa():
    p = filedialog.askopenfilename(title="Select serviceAccount.json", filetypes=[("JSON","*.json")])
    if p: ent_sa.delete(0, tk.END); ent_sa.insert(0, p)
tk.Button(frame, text="Browse", width=14, command=browse_sa).grid(row=0, column=2, padx=6)

# MARG
tk.Label(frame, text="MARG Excel (Product Name base):").grid(row=1, column=0, sticky="w", pady=6)
ent_marg = tk.Entry(frame, width=88)
ent_marg.grid(row=1, column=1, sticky="w")
def browse_marg():
    p = filedialog.askopenfilename(title="Select MARG Excel", filetypes=[("Excel","*.xlsx;*.xls")])
    if p: ent_marg.delete(0, tk.END); ent_marg.insert(0, p)
tk.Button(frame, text="Browse", width=14, command=browse_marg).grid(row=1, column=2, padx=6)

# PMBI
tk.Label(frame, text="PMBI Excel (Drug Name base):").grid(row=2, column=0, sticky="w")
ent_pmbi = tk.Entry(frame, width=88)
ent_pmbi.grid(row=2, column=1, sticky="w")
def browse_pmbi():
    p = filedialog.askopenfilename(title="Select PMBI Excel", filetypes=[("Excel","*.xlsx;*.xls")])
    if p: ent_pmbi.delete(0, tk.END); ent_pmbi.insert(0, p)
tk.Button(frame, text="Browse", width=14, command=browse_pmbi).grid(row=2, column=2, padx=6)

# Buttons
btn_frame = tk.Frame(frame)
btn_frame.grid(row=3, column=1, pady=10, sticky="w")
tk.Button(btn_frame, text="Start Import (Delete ALL then Upload)", bg="#1976D2", fg="white", width=36, command=start_import_thread).grid(row=0, column=0, padx=6)
tk.Button(btn_frame, text="Clear Log", width=12, command=lambda: log_box.configure(state="normal") or log_box.delete(1.0, tk.END) or log_box.configure(state="disabled")).grid(row=0, column=1, padx=6)

# Log box
log_box = scrolledtext.ScrolledText(frame, width=118, height=30, state="disabled")
log_box.grid(row=4, column=0, columnspan=3, pady=(6,0))

tk.Label(frame, text="Note: MARG fields uploaded: Product Name, Current Stock, M.R.P., EXP. PMBI fields uploaded: Drug Code, Drug Name, UOM, Batch No, Expiry Date, Qty, MRP.").grid(row=5, column=0, columnspan=3, sticky="w", pady=(8,0))

root.mainloop()

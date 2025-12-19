export interface Medicine1 {
  id: string;
  'Product Name': string;
  'Product Name_kn': string;
  'Current Stock'?: number | string;
  'M.R.P.'?: number | string;
  'MRP'?: number | string;
  'EXP'?: string | number | { seconds: number, nanoseconds: number };
  'Expiry Date'?: string | number | { seconds: number, nanoseconds: number };
}

export interface Medicine2 {
  id: string;
  'Drug Code': string;
  'Drug Name': string;
  'Drug Name_kn': string;
  'UOM'?: string;
  'Batch No'?: string;
  'Expiry Date'?: string | number | { seconds: number, nanoseconds: number };
  'EXP'?: string | number | { seconds: number, nanoseconds: number };
  'Qty'?: number | string;
  'MRP'?: number | string;
  'M.R.P.'?: number | string;
}

export type Medicine = Medicine1 | Medicine2;

// Type guard to check if a medicine is of type Medicine1
export function isMedicine1(medicine: Medicine): medicine is Medicine1 {
  return 'Product Name' in medicine;
}

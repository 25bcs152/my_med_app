import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"
import { format, parse, isValid, fromUnixTime } from 'date-fns';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

//
// FORMAT PRICE (₹) — now converts £ → ₹
//
export function formatPrice(price: number | string | undefined | null): string {
  if (price === undefined || price === null) return '-';

  const priceString = String(price);

  // Remove £, commas, and unwanted P/p prefix
  const cleaned = priceString
    .replace(/^[pP]/, '')   // remove leading P/p
    .replace(/£/g, '')      // remove pound symbol
    .replace(/,/g, '');     // remove commas

  const numericPrice = parseFloat(cleaned);
  if (isNaN(numericPrice)) return priceString;

  return `Rs ${numericPrice.toFixed(2)}`;
}

//
// FORMAT STOCK
//
export function formatStock(
  stock: number | string | undefined | null,
  t: (key: string) => string
): string {
  if (stock === undefined || stock === null) return '-';

  if (typeof stock === 'string' && isNaN(parseInt(stock, 10))) {
    return t('out_of_stock');  // e.g., "Out of Stock"
  }

  const numericStock = typeof stock === 'string'
    ? parseInt(stock, 10)
    : stock;

  if (numericStock <= 0) return t('out_of_stock');

  return numericStock.toLocaleString();
}

//
// FORMAT DATE
//
export function formatDate(dateValue: string | number | { seconds: number, nanoseconds: number } | undefined | null): string {
  if (!dateValue) return '-';

  // Handle Firestore Timestamp object
  if (typeof dateValue === 'object' && 'seconds' in dateValue && typeof dateValue.seconds === 'number') {
    const date = fromUnixTime(dateValue.seconds);
    if (isValid(date)) {
      return format(date, 'dd MMM yyyy');
    }
  }
  
  // Handle numeric timestamp (in seconds)
  if (typeof dateValue === 'number') {
    const date = fromUnixTime(dateValue);
     if (isValid(date)) {
      return format(date, 'dd MMM yyyy');
    }
  }

  const dateString = String(dateValue);

  // Define formats, prioritizing those with day information
  const formats = [
    'dd/MM/yyyy',
    'yyyy-MM-dd',
    'dd-MMM-yy',
    'MM/yyyy',
    'MMM yyyy',
    'MM-yyyy',
    'MMM-yyyy',
    'yyyy/MM/dd',
    'MM.yy',
    'MMM-yy',
  ];

  // Handle "Expired" text
  if (dateString.toLowerCase() === 'expired') {
    return dateString;
  }
  
  // Attempt to parse the date string with various formats
  for (const fmt of formats) {
    try {
      const parsedDate = parse(dateString, fmt, new Date());
      if (isValid(parsedDate)) {
        // If the original format included a day, display it.
        if (fmt.includes('dd')) {
          return format(parsedDate, 'dd MMM yyyy');
        }
        // Otherwise, show month and year.
        return format(parsedDate, 'MMM yyyy');
      }
    } catch (e) {
      // Ignore parsing errors and try the next format
    }
  }

  // Handle specific non-standard cases like "Jan 2027" or "Nov-2025"
  const monthYearMatch = dateString.match(/([a-zA-Z]{3,})[-.\s]?(\d{4}|\d{2})/);
  if (monthYearMatch) {
    try {
      const parsed1 = parse(dateString, 'MMM-yy', new Date());
      if (isValid(parsed1)) return format(parsed1, 'MMM yyyy');

      const parsed2 = parse(dateString, 'MMM yyyy', new Date());
      if (isValid(parsed2)) return format(parsed2, 'MMM yyyy');
    } catch (e) {}
  }


  // If no format matches, return the original string
  return dateString;
}

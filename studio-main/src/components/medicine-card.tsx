import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { type Medicine, isMedicine1 } from "@/lib/types";
import { formatPrice, formatStock, formatDate } from "@/lib/utils";
import { Package, Boxes, CalendarClock, Tag, Scale, PlusCircle } from "lucide-react";
import { useLanguage } from "@/context/language-context";

interface MedicineCardProps {
  medicine: Medicine;
  onAddMedicine?: (medicine: Medicine) => void;
  showAddButton?: boolean;
}

const InfoRow = ({ icon, label, value }: { icon: React.ReactNode, label: string, value: string | number | React.ReactNode }) => (
  <div className="flex items-start justify-between text-sm">
    <div className="flex items-center gap-2 text-muted-foreground">
      {icon}
      <span>{label}</span>
    </div>
    <span className="font-medium text-foreground text-right">{value}</span>
  </div>
);

export function MedicineCard({ medicine, onAddMedicine, showAddButton = true }: MedicineCardProps) {
  const { language, t } = useLanguage();
  
  const handleAdd = () => {
    if (onAddMedicine) {
      onAddMedicine(medicine);
    }
  };
  
  if (isMedicine1(medicine)) {
    const stock = formatStock(medicine['Current Stock'], t);
    const isOutOfStock = stock === t('out_of_stock');
    const productName = language === 'kannada' ? medicine['Product Name_kn'] : medicine['Product Name'];
    
    return (
      <Card className="flex flex-col h-full transition-shadow duration-300 hover:shadow-lg hover:-translate-y-1">
        <CardHeader>
          <div className="flex justify-between items-start gap-4">
            <CardTitle className="font-headline text-lg">{productName}</CardTitle>
            {isOutOfStock && <Badge variant="destructive" className="flex-shrink-0">{t('out_of_stock')}</Badge>}
          </div>
          <CardDescription>Generic</CardDescription>
        </CardHeader>
        <CardContent className="flex flex-col flex-grow justify-end gap-3">
          <InfoRow
            icon={<Boxes className="h-4 w-4" />}
            label={t('stock')}
            value={stock}
          />
          <InfoRow
            icon={<Tag className="h-4 w-4" />}
            label="MRP"
            value={formatPrice(medicine['M.R.P.'] ?? medicine.MRP)}
          />
          <InfoRow
            icon={<CalendarClock className="h-4 w-4" />}
            label={t('expiry')}
            value={formatDate(medicine.EXP ?? medicine['Expiry Date'])}
          />
        </CardContent>
        {showAddButton && (
            <CardFooter>
                <Button variant="ghost" size="sm" className="w-full" onClick={handleAdd} disabled={isOutOfStock}>
                    <PlusCircle className="mr-2 h-4 w-4" />
                    {t('add_to_my_medicines')}
                </Button>
            </CardFooter>
        )}
      </Card>
    );
  } else {
    // It's Medicine2
    const stock = formatStock(medicine.Qty, t);
    const isOutOfStock = stock === t('out_of_stock');
    const drugName = language === 'kannada' ? medicine['Drug Name_kn'] : medicine['Drug Name'];

    return (
      <Card className="flex flex-col h-full transition-shadow duration-300 hover:shadow-lg hover:-translate-y-1">
        <CardHeader>
           <div className="flex justify-between items-start gap-4">
            <CardTitle className="font-headline text-lg">{drugName}</CardTitle>
            {isOutOfStock && <Badge variant="destructive" className="flex-shrink-0">{t('out_of_stock')}</Badge>}
          </div>
          <CardDescription>Jan Aushadhi - {medicine['Drug Code']}</CardDescription>
        </CardHeader>
        <CardContent className="flex flex-col flex-grow justify-end gap-3">
          <InfoRow
            icon={<Boxes className="h-4 w-4" />}
            label={t('quantity')}
            value={stock}
          />
          <InfoRow
            icon={<Scale className="h-4 w-4" />}
            label="UOM"
            value={medicine.UOM || '-'}
          />
           <InfoRow
            icon={<Package className="h-4 w-4" />}
            label={t('batch_no')}
            value={medicine['Batch No'] || '-'}
          />
          <InfoRow
            icon={<Tag className="h-4 w-4" />}
            label="MRP"
            value={formatPrice(medicine['M.R.P.'] ?? medicine.MRP)}
          />
          <InfoRow
            icon={<CalendarClock className="h-4 w-4" />}
            label={t('expiry')}
            value={formatDate(medicine.EXP ?? medicine['Expiry Date'])}
          />
        </CardContent>
        {showAddButton && (
            <CardFooter>
                <Button variant="ghost" size="sm" className="w-full" onClick={handleAdd} disabled={isOutOfStock}>
                    <PlusCircle className="mr-2 h-4 w-4" />
                    {t('add_to_my_medicines')}
                </Button>
            </CardFooter>
        )}
      </Card>
    );
  }
}

import { MedicineCard } from "./medicine-card";
import { type Medicine } from "@/lib/types";
import { useLanguage } from "@/context/language-context";

interface MedicineListProps {
  medicines: Medicine[];
  onAddMedicine?: (medicine: Medicine) => void;
  showAddButton?: boolean;
}

export function MedicineList({ medicines, onAddMedicine, showAddButton }: MedicineListProps) {
  const { t } = useLanguage();
  if (medicines.length === 0) {
    return (
      <div className="text-center py-16 text-muted-foreground">
        <h3 className="text-xl font-semibold text-foreground">{t('no_medicines_found')}</h3>
        <p className="mt-2">{t('no_medicines_description')}</p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
      {medicines.map((med) => (
        <MedicineCard key={med.id} medicine={med} onAddMedicine={onAddMedicine} showAddButton={showAddButton} />
      ))}
    </div>
  );
}

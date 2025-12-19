"use client";

import { useState, useMemo } from 'react';
import { collection } from 'firebase/firestore';
import { Input } from "@/components/ui/input";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { MedicineList } from "@/components/medicine-list";
import { LoadingSkeleton } from "@/components/loading-skeleton";
import { ErrorDisplay } from "@/components/error-display";
import type { Medicine1, Medicine2, Medicine } from "@/lib/types";
import { Search, Languages, ShoppingCart } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { useLanguage } from '@/context/language-context';
import { useFirestore, useCollection } from '@/firebase';
import { Logo } from '@/components/logo';

export default function Home() {
  const [myMedicines, setMyMedicines] = useState<Medicine[]>([]);
  const [search1, setSearch1] = useState('');
  const [search2, setSearch2] = useState('');
  const [searchMy, setSearchMy] = useState('');
  const { language, setLanguage, t } = useLanguage();
  const [activeTab, setActiveTab] = useState('med1');
  
  const firestore = useFirestore();

  const medicine1Query = useMemo(() => {
    if (!firestore) return null;
    return collection(firestore, 'medicine-1');
  }, [firestore]);

  const medicine2Query = useMemo(() => {
    if (!firestore) return null;
    return collection(firestore, 'medicine-2');
  }, [firestore]);

  const { data: medicines1, loading: loading1, error: error1 } = useCollection<Medicine1>(medicine1Query);
  const { data: medicines2, loading: loading2, error: error2 } = useCollection<Medicine2>(medicine2Query);
  
  const isLoading = loading1 || loading2;
  const error = error1 || error2;
  
  const locationUrl = "https://www.google.com/maps/search/?api=1&query=F12,+1st+Floor,+Madhava+Square,+Station+Road,+Malmaddi,+Dharwad+–+580007,+Karnataka,+India";
  const address = "F12, 1st Floor, Madhava Square, Station Road, Malmaddi, Dharwad – 580007, Karnataka, India";


  const addToMyMedicines = (medicine: Medicine) => {
    setMyMedicines(prev => {
        if(prev.find(m => m.id === medicine.id)) {
            return prev;
        }
        return [...prev, medicine]
    })
  }

  const filterMedicines = (medicines: Medicine[] | null, search: string) => {
    if (!medicines) return [];
    if (!search) return medicines;
    const lowercasedSearch = search.toLowerCase();
    return medicines.filter(med => {
      if ('Product Name' in med && med['Product Name'] && med['Product Name_kn']) {
        return med['Product Name'].toLowerCase().includes(lowercasedSearch) ||
               med['Product Name_kn'].toLowerCase().includes(lowercasedSearch);
      }
      if ('Drug Name' in med && med['Drug Name'] && med['Drug Name_kn']) {
        return med['Drug Name'].toLowerCase().includes(lowercasedSearch) ||
               med['Drug Name_kn'].toLowerCase().includes(lowercasedSearch);
      }
      return false;
    });
  }
  
  const handleRetry = () => {
    window.location.reload();
  };

  const filteredMedicines1 = useMemo(() => filterMedicines(medicines1, search1), [medicines1, search1]);
  const filteredMedicines2 = useMemo(() => filterMedicines(medicines2, search2), [medicines2, search2]);
  const filteredMyMedicines = useMemo(() => filterMedicines(myMedicines, searchMy), [myMedicines, searchMy]);

  const renderContent = (
    filteredData: Medicine[],
    searchVal: string,
    setSearch: (val: string) => void,
    placeholder: string
  ) => {
    if (isLoading) {
      return <LoadingSkeleton />;
    }
    if (error && (activeTab === 'med1' || activeTab === 'med2')) {
      return null;
    }
    return (
      <div className="space-y-6">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
          <Input
            type="search"
            aria-label={placeholder}
            placeholder={placeholder}
            className="pl-10 w-full md:w-1/2 lg:w-1/3"
            value={searchVal}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <div className="animate-in fade-in-50 duration-500">
          <MedicineList 
            medicines={filteredData} 
            onAddMedicine={addToMyMedicines} 
            showAddButton={activeTab !== 'my-medicines'} 
            />
        </div>
      </div>
    );
  };

  return (
    <main className="min-h-screen bg-background text-foreground">
      <div className="container mx-auto px-4 py-8">
        <header className="mb-12">
           <div className="flex justify-between items-start gap-4 mb-4">
              <a href={locationUrl} target="_blank" rel="noopener noreferrer" className="text-sm text-muted-foreground hover:text-primary transition-colors">
                <p className="whitespace-pre-line">{address}</p>
              </a>
              <div className="flex justify-end gap-2">
                <Button variant="outline" onClick={() => setActiveTab('my-medicines')}>
                    <ShoppingCart className="mr-2 h-4 w-4" /> {t('my_medicines')}
                </Button>
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="outline">
                      <Languages className="mr-2 h-4 w-4" />
                      <span>{language === 'kannada' ? 'ಕನ್ನಡ' : 'English'}</span>
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent>
                    <DropdownMenuItem onSelect={() => setLanguage('english')}>English</DropdownMenuItem>
                    <DropdownMenuItem onSelect={() => setLanguage('kannada')}>ಕನ್ನಡ</DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>
          </div>
          <div className="text-center">
            <div className="inline-flex items-center justify-center rounded-full w-24 h-24 mb-4 p-2">
              <Logo className="w-full h-full" />
            </div>
            <h1 className="font-headline text-4xl md:text-5xl font-bold text-primary">
              {t('app_title')}
            </h1>
            <p className="text-muted-foreground text-lg mt-2">{t('app_subtitle')}</p>
          </div>
        </header>

        {error && !isLoading ? (
          <ErrorDisplay onRetry={handleRetry} />
        ) : (
          <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
            <TabsList className="grid w-full grid-cols-3 max-w-lg mx-auto mb-8">
              <TabsTrigger value="med1">{t('tab1_title')}</TabsTrigger>
              <TabsTrigger value="med2">{t('tab2_title')}</TabsTrigger>
              <TabsTrigger value="my-medicines">{t('my_medicines')}</TabsTrigger>
            </TabsList>
            <TabsContent value="med1">
              {renderContent(filteredMedicines1, search1, setSearch1, t('search_placeholder_product'))}
            </TabsContent>
            <TabsContent value="med2">
              {renderContent(filteredMedicines2, search2, setSearch2, t('search_placeholder_drug'))}
            </TabsContent>
            <TabsContent value="my-medicines">
              {renderContent(filteredMyMedicines, searchMy, setSearchMy, t('search_my_medicines'))}
            </TabsContent>
          </Tabs>
        )}
      </div>
    </main>
  );
}

import { AlertTriangle, RefreshCw } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { useLanguage } from "@/context/language-context";

interface ErrorDisplayProps {
  onRetry: () => void;
}

export function ErrorDisplay({ onRetry }: ErrorDisplayProps) {
  const { t } = useLanguage();

  return (
    <Card className="w-full max-w-md mx-auto my-8 text-center animate-in fade-in-50">
      <CardHeader>
        <div className="mx-auto bg-destructive/10 rounded-full p-3 w-fit">
          <AlertTriangle className="h-10 w-10 text-destructive" />
        </div>
        <CardTitle className="mt-4">{t('error_title')}</CardTitle>
        <CardDescription>
          {t('error_description')}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <Button onClick={onRetry}>
          <RefreshCw className="mr-2 h-4 w-4" />
          {t('retry_button')}
        </Button>
      </CardContent>
    </Card>
  );
}

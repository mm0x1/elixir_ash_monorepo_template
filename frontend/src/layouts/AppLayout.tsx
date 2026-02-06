import { Navbar } from '@/components/navigation/Navbar';
import { Footer } from '@/components/navigation/Footer';
import { FlashMessages } from '@/components/FlashMessages';
import { useAppConfig } from '@/config/app';
import { useFlash } from '@/lib/inertia';

export interface AppLayoutProps {
  children: React.ReactNode;
  brandName?: string;
}

function AppLayout({
  children,
  brandName,
}: AppLayoutProps) {
  const flash = useFlash();
  const config = useAppConfig();
  const displayName = brandName || config.name;

  return (
    <>
      <div className="min-h-screen flex flex-col">
        <header>
          <div className="container mx-auto">
            <Navbar brandName={displayName} />
          </div>
        </header>

        <FlashMessages flash={flash} className="container mx-auto px-4" />

        <main className="flex-1">
          <div className="container mx-auto px-4 py-8">
            {children}
          </div>
        </main>
      </div>
      <Footer companyName={config.company} />
    </>
  );
}

export { AppLayout };

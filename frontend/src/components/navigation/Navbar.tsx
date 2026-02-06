import { router } from '@inertiajs/react';
import { Brand } from '@/components/ui/Brand';
import { useAppAbility } from '@/lib/permissions';

export interface NavbarProps {
  brandName?: string;
}

function Navbar({ brandName }: NavbarProps) {
  const ability = useAppAbility();

  return (
    <nav className="navbar bg-base-100">
      <div className="flex-1">
        <Brand brandName={brandName} className="btn btn-ghost text-xl" />
      </div>
      <div className="flex-none">
        <ul className="menu menu-horizontal px-1">
          <li>
            <a onClick={() => router.visit('/')}>Home</a>
          </li>
          {ability.canAccessAdminPanel() && (
            <li>
              <a onClick={() => router.visit('/admin')}>Admin</a>
            </li>
          )}
        </ul>
      </div>
    </nav>
  );
}

export { Navbar };

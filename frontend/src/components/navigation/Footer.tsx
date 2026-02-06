export interface FooterProps {
  companyName?: string;
  year?: number;
}

function Footer({
  companyName = 'SaaS Template',
  year = new Date().getFullYear(),
}: FooterProps) {
  return (
    <footer>
      <div>
        <p>
          © {year} {companyName}. All rights reserved.
        </p>
      </div>
    </footer>
  );
}

export { Footer };

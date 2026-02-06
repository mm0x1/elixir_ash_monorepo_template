import { Head } from "@inertiajs/react";
import { getPageTitle, useAppConfig } from "@/config/app";

function Home() {
  const config = useAppConfig();

  return (
    <>
      <Head title={getPageTitle("Home", config.name)} />
      <div>
        <div>
          <div>
            <h1>Welcome to {config.name}</h1>
            <p>
              {config.description}
            </p>
          </div>
        </div>
      </div>
    </>
  );
}

export default Home;

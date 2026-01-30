import { Link } from "react-router-dom";
import logo from "@/assets/logo.png";

export function Footer() {
  return (
    <footer className="bg-r107-dark border-t border-border mt-auto">
      <div className="container mx-auto px-4 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* Logo & Description */}
          <div className="md:col-span-2">
            <img src={logo} alt="R107 Garage" className="h-12 w-auto mb-4" />
            <p className="text-muted-foreground text-sm max-w-md">
              Portal dla miłośników klasycznych Mercedesów R107 i C107 (SL/SLC) 
              z lat 1970-1986. Ogłoszenia, poradniki napraw i lista sklepów 
              z częściami.
            </p>
          </div>

          {/* Links */}
          <div>
            <h4 className="font-heading font-semibold text-foreground mb-4">
              Nawigacja
            </h4>
            <ul className="space-y-2">
              <li>
                <Link
                  to="/ogloszenia"
                  className="text-muted-foreground hover:text-primary transition-colors text-sm"
                >
                  Ogłoszenia
                </Link>
              </li>
              <li>
                <Link
                  to="/naprawy"
                  className="text-muted-foreground hover:text-primary transition-colors text-sm"
                >
                  Naprawy
                </Link>
              </li>
              <li>
                <Link
                  to="/sklepy"
                  className="text-muted-foreground hover:text-primary transition-colors text-sm"
                >
                  Sklepy
                </Link>
              </li>
            </ul>
          </div>

          {/* Social */}
          <div>
            <h4 className="font-heading font-semibold text-foreground mb-4">
              Dołącz do nas
            </h4>
            <a
              href="https://www.tiktok.com/@r107garage"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 text-muted-foreground hover:text-primary transition-colors"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 24 24"
                fill="currentColor"
                className="h-6 w-6"
              >
                <path d="M19.59 6.69a4.83 4.83 0 0 1-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 0 1-5.2 1.74 2.89 2.89 0 0 1 2.31-4.64 2.93 2.93 0 0 1 .88.13V9.4a6.84 6.84 0 0 0-1-.05A6.33 6.33 0 0 0 5 20.1a6.34 6.34 0 0 0 10.86-4.43v-7a8.16 8.16 0 0 0 4.77 1.52v-3.4a4.85 4.85 0 0 1-1-.1z" />
              </svg>
              <span className="text-sm">TikTok</span>
            </a>
          </div>
        </div>

        <div className="border-t border-border mt-8 pt-8 text-center text-sm text-muted-foreground">
          <p>© {new Date().getFullYear()} R107 Garage. Wszystkie prawa zastrzeżone.</p>
        </div>
      </div>
    </footer>
  );
}

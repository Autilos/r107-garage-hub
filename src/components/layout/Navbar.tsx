import { Link, useLocation, useNavigate } from "react-router-dom";
import { User, LogOut, Shield, Car, Wrench, Store, BookOpen } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/hooks/useAuth";
import logo from "@/assets/logo.png";

const navLinks = [
  { href: "/ogloszenia", label: "Ogłoszenia", icon: Car },
  { href: "/naprawy", label: "Naprawy", icon: Wrench },
  { href: "/sklepy", label: "Sklepy", icon: Store },
  { href: "/blog", label: "Blog", icon: BookOpen },
];

export function Navbar() {
  const location = useLocation();
  const navigate = useNavigate();
  const { user, isAdmin, signOut } = useAuth();

  const handleSignOut = async () => {
    await signOut();
    navigate("/");
  };

  return (
    <>
      {/* Top navbar */}
      <nav className="fixed top-0 left-0 right-0 z-50 bg-background/95 backdrop-blur-md border-b border-border">
        <div className="container mx-auto px-4">
          <div className="flex items-center justify-between h-16">
            {/* Logo */}
            <Link to="/" className="flex items-center gap-2 group">
              <img src={logo} alt="R107 Garage" className="h-[28px] sm:h-[40px] md:h-[60px] w-auto transition-transform duration-300 group-hover:scale-105" />
            </Link>

            {/* Desktop Navigation */}
            <div className="hidden md:flex items-center gap-1 ml-auto mr-4">
              {navLinks.map((link) => (
                <Link
                  key={link.href}
                  to={link.href}
                  className={`nav-link font-medium ${location.pathname.startsWith(link.href) ? "active" : ""
                    }`}
                >
                  {link.label}
                </Link>
              ))}
              {isAdmin && (
                <Link
                  to="/admin"
                  className={`nav-link font-medium flex items-center gap-1.5 ${location.pathname.startsWith("/admin") ? "active" : ""
                    }`}
                >
                  <Shield className="h-4 w-4" />
                  Admin
                </Link>
              )}
            </div>

            {/* Auth buttons - Desktop */}
            <div className="hidden md:flex items-center gap-2">
              {user ? (
                <>
                  <Link to="/konto">
                    <Button variant="ghost" size="sm" className="gap-2">
                      <User className="h-4 w-4" />
                      {user.email?.split("@")[0]}
                    </Button>
                  </Link>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={handleSignOut}
                    className="gap-2 text-muted-foreground hover:text-foreground"
                  >
                    <LogOut className="h-4 w-4" />
                  </Button>
                </>
              ) : (
                <Link to="/konto">
                  <Button variant="default" size="sm">
                    Zaloguj się
                  </Button>
                </Link>
              )}
            </div>

            {/* Mobile - Auth icon only */}
            <div className="md:hidden flex items-center gap-2">
              {isAdmin && (
                <Link to="/admin">
                  <Button variant="ghost" size="icon" className="h-9 w-9">
                    <Shield className="h-5 w-5" />
                  </Button>
                </Link>
              )}
              {user ? (
                <>
                  <Link to="/konto">
                    <Button variant="ghost" size="icon" className="h-9 w-9">
                      <User className="h-5 w-5" />
                    </Button>
                  </Link>
                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={handleSignOut}
                    className="h-9 w-9 text-muted-foreground"
                  >
                    <LogOut className="h-5 w-5" />
                  </Button>
                </>
              ) : (
                <Link to="/konto">
                  <Button variant="ghost" size="icon" className="h-9 w-9">
                    <User className="h-5 w-5" />
                  </Button>
                </Link>
              )}
            </div>
          </div>
        </div>
      </nav>

      {/* Mobile top navigation buttons */}
      <div className="md:hidden fixed top-16 left-0 right-0 z-40 bg-background/95 backdrop-blur-md border-b border-border">
        <div className="flex items-center justify-around h-12">
          {navLinks.map((link) => {
            const isActive = location.pathname.startsWith(link.href);
            return (
              <Link
                key={link.href}
                to={link.href}
                className={`text-sm font-semibold uppercase tracking-wide transition-colors ${isActive
                  ? "text-primary"
                  : "text-foreground hover:text-primary"
                  }`}
              >
                {link.label}
              </Link>
            );
          })}
        </div>
      </div>

      {/* Mobile bottom navigation */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 z-50 bg-background/95 backdrop-blur-md border-t border-border">
        <div className="flex items-center justify-around h-16">
          {navLinks.map((link) => {
            const Icon = link.icon;
            const isActive = location.pathname.startsWith(link.href);
            return (
              <Link
                key={link.href}
                to={link.href}
                className={`flex flex-col items-center justify-center gap-1 px-4 py-2 transition-colors ${isActive
                  ? "text-primary"
                  : "text-muted-foreground hover:text-foreground"
                  }`}
              >
                <Icon className="h-5 w-5" />
                <span className="text-xs font-medium">{link.label}</span>
              </Link>
            );
          })}
        </div>
      </nav>
    </>
  );
}
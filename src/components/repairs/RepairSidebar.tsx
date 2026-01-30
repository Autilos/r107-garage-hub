import { useState } from "react";
import { Link, useLocation } from "react-router-dom";
import { ChevronDown } from "lucide-react";
import { repairCategories } from "@/data/repairCategories";
import { cn } from "@/lib/utils";
import { useIsMobile } from "@/hooks/use-mobile";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";

export const RepairSidebar = () => {
  const location = useLocation();
  const currentSlug = location.pathname.split("/").pop();
  const isMobile = useIsMobile();
  const [isOpen, setIsOpen] = useState(false);

  const currentCategory = repairCategories.find(c => c.slug === currentSlug);

  const categoryList = (
    <ul className="space-y-1">
      {repairCategories.map((category) => (
        <li key={category.slug}>
          <Link
            to={`/naprawy/${category.slug}`}
            onClick={() => isMobile && setIsOpen(false)}
            className={cn(
              "block px-3 py-2 rounded-md text-sm transition-colors",
              currentSlug === category.slug
                ? "bg-primary text-primary-foreground font-medium"
                : "text-muted-foreground hover:bg-muted hover:text-foreground"
            )}
          >
            {category.title}
          </Link>
        </li>
      ))}
    </ul>
  );

  if (isMobile) {
    return (
      <aside className="w-full shrink-0">
        <Collapsible open={isOpen} onOpenChange={setIsOpen}>
          <CollapsibleTrigger className="w-full bg-card border border-border rounded-lg p-4 flex items-center justify-between">
            <span className="font-heading text-lg font-semibold text-foreground">
              {currentCategory ? currentCategory.title : "Kategorie napraw"}
            </span>
            <ChevronDown
              className={cn(
                "h-5 w-5 text-muted-foreground transition-transform",
                isOpen && "rotate-180"
              )}
            />
          </CollapsibleTrigger>
          <CollapsibleContent className="bg-card border border-t-0 border-border rounded-b-lg p-4 pt-2">
            {categoryList}
          </CollapsibleContent>
        </Collapsible>
      </aside>
    );
  }

  return (
    <aside className="w-64 shrink-0">
      <nav className="sticky top-24 bg-card border border-border rounded-lg p-4">
        <h3 className="font-heading text-lg font-semibold mb-4 text-foreground">
          Kategorie napraw
        </h3>
        {categoryList}
      </nav>
    </aside>
  );
};

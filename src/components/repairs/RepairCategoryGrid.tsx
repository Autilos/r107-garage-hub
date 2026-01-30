import { Link } from "react-router-dom";
import { repairCategories } from "@/data/repairCategories";

export const RepairCategoryGrid = () => {
  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 md:gap-6">
      {repairCategories.map((category) => (
        <Link
          key={category.slug}
          to={`/naprawy/${category.slug}`}
          className="group block"
        >
          <div className="bg-card border border-border rounded-lg overflow-hidden transition-all duration-300 hover:shadow-lg hover:border-primary/50 hover:-translate-y-1">
            <div className="aspect-square bg-muted/30 p-4 flex items-center justify-center">
              <img
                src={category.image}
                alt={category.title}
                className="w-full h-full object-contain transition-transform duration-300 group-hover:scale-105"
              />
            </div>
            <div className="p-3 text-center border-t border-border">
              <h3 className="font-heading font-semibold text-foreground group-hover:text-primary transition-colors">
                {category.title}
              </h3>
            </div>
          </div>
        </Link>
      ))}
    </div>
  );
};

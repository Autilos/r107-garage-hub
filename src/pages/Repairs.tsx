import { RepairCategoryGrid } from "@/components/repairs/RepairCategoryGrid";

const Repairs = () => {
  return (
    <div className="min-h-screen py-12 md:py-20">
      <div className="container">
        <div className="mb-8">
          <h1 className="font-heading text-3xl md:text-4xl font-bold text-foreground">
            Naprawy
          </h1>
          <p className="text-muted-foreground mt-2">
            Poradniki napraw i serwisu Mercedes R107/C107
          </p>
        </div>

        <RepairCategoryGrid />
      </div>
    </div>
  );
};

export default Repairs;

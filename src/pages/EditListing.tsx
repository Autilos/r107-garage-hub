import { useState, useCallback, useEffect } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { z } from "zod";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Upload, X, Loader2, Car, Cog, Youtube, AlertCircle, Phone } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/hooks/useAuth";
import { useQuery } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { toast } from "sonner";

const MAX_IMAGES = 6;
const MAX_IMAGE_SIZE = 1200;
const JPEG_QUALITY = 0.85;

const formSchema = z.object({
  title: z.string().trim().min(5, "Tytuł min. 5 znaków").max(150, "Tytuł max. 150 znaków"),
  description: z.string().trim().max(2000, "Opis max. 2000 znaków").optional(),
  category: z.enum(["pojazd", "czesc"]),
  price: z.coerce.number().min(0, "Cena musi być dodatnia").max(10000000, "Cena max. 10 000 000"),
  currency: z.enum(["PLN", "EUR", "USD"]),
  phone_number: z.string().trim().min(9, "Numer telefonu min. 9 znaków").max(20, "Numer telefonu max. 20 znaków"),
  year_from: z.coerce.number().min(1970, "Rok min. 1970").max(1989, "Rok max. 1989").optional().or(z.literal("")),
  mileage: z.coerce.number().min(0).max(9999999).optional().or(z.literal("")),
  youtube_url: z.string().url("Nieprawidłowy URL").optional().or(z.literal("")),
});

type FormData = z.infer<typeof formSchema>;

interface ImagePreview {
  id: string;
  file?: File;
  preview: string;
  uploading: boolean;
  uploaded: boolean;
  storagePath?: string;
  existing?: boolean;
}

async function resizeImage(file: File): Promise<Blob> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => {
      let { width, height } = img;
      
      if (width > MAX_IMAGE_SIZE || height > MAX_IMAGE_SIZE) {
        if (width > height) {
          height = Math.round((height * MAX_IMAGE_SIZE) / width);
          width = MAX_IMAGE_SIZE;
        } else {
          width = Math.round((width * MAX_IMAGE_SIZE) / height);
          height = MAX_IMAGE_SIZE;
        }
      }

      const canvas = document.createElement("canvas");
      canvas.width = width;
      canvas.height = height;
      const ctx = canvas.getContext("2d");
      if (!ctx) {
        reject(new Error("Cannot get canvas context"));
        return;
      }
      
      ctx.drawImage(img, 0, 0, width, height);
      canvas.toBlob(
        (blob) => {
          if (blob) resolve(blob);
          else reject(new Error("Failed to create blob"));
        },
        "image/jpeg",
        JPEG_QUALITY
      );
    };
    img.onerror = () => reject(new Error("Failed to load image"));
    img.src = URL.createObjectURL(file);
  });
}

export default function EditListing() {
  const { id } = useParams<{ id: string }>();
  const { user, isLoading: authLoading } = useAuth();
  const navigate = useNavigate();
  const [images, setImages] = useState<ImagePreview[]>([]);
  const [submitting, setSubmitting] = useState(false);

  const { data: listing, isLoading: listingLoading } = useQuery({
    queryKey: ["edit-listing", id],
    queryFn: async () => {
      if (!id || !user) return null;
      
      const { data, error } = await supabase
        .from("listings")
        .select("*, listing_images(*)")
        .eq("id", id)
        .eq("user_id", user.id)
        .single();

      if (error) throw error;
      return data;
    },
    enabled: !!id && !!user,
  });

  const {
    register,
    handleSubmit,
    watch,
    reset,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      category: "pojazd",
      currency: "PLN",
      phone_number: "",
    },
  });

  const category = watch("category");

  // Load listing data into form
  useEffect(() => {
    if (listing) {
      reset({
        title: listing.title,
        description: listing.description || "",
        category: listing.category as "pojazd" | "czesc",
        price: listing.price || 0,
        currency: (listing.currency as "PLN" | "EUR" | "USD") || "PLN",
        phone_number: listing.phone_number || "",
        year_from: listing.year_from || "",
        youtube_url: listing.url || "",
      });

      // Load existing images
      if (listing.listing_images && listing.listing_images.length > 0) {
        const existingImages: ImagePreview[] = listing.listing_images.map((img: any) => {
          const { data } = supabase.storage.from("r107").getPublicUrl(img.storage_path);
          return {
            id: img.id,
            preview: data.publicUrl,
            uploading: false,
            uploaded: true,
            storagePath: img.storage_path,
            existing: true,
          };
        });
        setImages(existingImages);
      }
    }
  }, [listing, reset]);

  // Redirect if not logged in
  useEffect(() => {
    if (!authLoading && !user) {
      toast.error("Musisz być zalogowany");
      navigate("/konto");
    }
  }, [authLoading, user, navigate]);

  // Handle image selection
  const handleImageSelect = useCallback(async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    if (images.length + files.length > MAX_IMAGES) {
      toast.error(`Maksymalnie ${MAX_IMAGES} zdjęć`);
      return;
    }

    const newImages: ImagePreview[] = files.map((file) => ({
      id: crypto.randomUUID(),
      file,
      preview: URL.createObjectURL(file),
      uploading: false,
      uploaded: false,
    }));

    setImages((prev) => [...prev, ...newImages]);
    e.target.value = "";
  }, [images.length]);

  // Remove image
  const removeImage = useCallback((imageId: string) => {
    setImages((prev) => {
      const img = prev.find((i) => i.id === imageId);
      if (img && !img.existing) {
        URL.revokeObjectURL(img.preview);
      }
      return prev.filter((i) => i.id !== imageId);
    });
  }, []);

  // Upload new images
  async function uploadNewImages(listingId: string): Promise<string[]> {
    const uploadedPaths: string[] = [];
    const newImages = images.filter((img) => !img.existing && img.file);

    for (let i = 0; i < newImages.length; i++) {
      const img = newImages[i];
      if (!img.file) continue;

      setImages((prev) =>
        prev.map((p) => (p.id === img.id ? { ...p, uploading: true } : p))
      );

      try {
        const resized = await resizeImage(img.file);
        const fileName = `${listingId}/${Date.now()}_${i}.jpg`;

        const { error: uploadError } = await supabase.storage
          .from("r107")
          .upload(fileName, resized, { contentType: "image/jpeg" });

        if (uploadError) throw uploadError;

        uploadedPaths.push(fileName);

        setImages((prev) =>
          prev.map((p) =>
            p.id === img.id ? { ...p, uploading: false, uploaded: true, storagePath: fileName } : p
          )
        );
      } catch (err) {
        console.error("Upload error:", err);
        setImages((prev) =>
          prev.map((p) => (p.id === img.id ? { ...p, uploading: false } : p))
        );
        throw err;
      }
    }

    return uploadedPaths;
  }

  // Submit form
  const onSubmit = async (data: FormData) => {
    if (!user || !id) {
      toast.error("Błąd autoryzacji");
      return;
    }

    if (images.length === 0) {
      toast.error("Dodaj przynajmniej 1 zdjęcie");
      return;
    }

    setSubmitting(true);

    try {
      // Delete removed images from storage and database
      if (listing?.listing_images) {
        const existingIds = images.filter((i) => i.existing).map((i) => i.id);
        const toDelete = listing.listing_images.filter((img: any) => !existingIds.includes(img.id));

        for (const img of toDelete) {
          await supabase.storage.from("r107").remove([img.storage_path]);
          await supabase.from("listing_images").delete().eq("id", img.id);
        }
      }

      // Upload new images
      const newPaths = await uploadNewImages(id);

      // Insert new image records
      for (let i = 0; i < newPaths.length; i++) {
        await supabase.from("listing_images").insert({
          listing_id: id,
          storage_path: newPaths[i],
          sort_order: images.filter((i) => i.existing).length + i,
        });
      }

      // Update main image if needed
      const firstImage = images[0];
      let imageUrl = listing?.image_url;
      if (firstImage && firstImage.storagePath) {
        const { data: urlData } = supabase.storage.from("r107").getPublicUrl(firstImage.storagePath);
        imageUrl = urlData.publicUrl;
      }

      // Update listing - set status to pending for re-approval
      const { error: updateError } = await supabase
        .from("listings")
        .update({
          title: data.title,
          description: data.description || null,
          category: data.category,
          price: data.price,
          currency: data.currency,
          phone_number: data.phone_number,
          year_from: data.year_from ? Number(data.year_from) : null,
          url: data.youtube_url || null,
          image_url: imageUrl,
          status: "pending", // Needs re-approval after edit
        })
        .eq("id", id)
        .eq("user_id", user.id);

      if (updateError) throw updateError;

      toast.success("Ogłoszenie zaktualizowane i czeka na moderację");
      navigate("/konto");
    } catch (err) {
      console.error("Submit error:", err);
      toast.error("Wystąpił błąd podczas aktualizacji");
    } finally {
      setSubmitting(false);
    }
  };

  if (authLoading || listingLoading) {
    return (
      <div className="min-h-screen py-20 flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  if (!user || !listing) {
    return null;
  }

  return (
    <div className="min-h-screen py-20">
      <div className="container mx-auto px-4 max-w-2xl">
        <h1 className="font-heading text-3xl font-bold text-foreground mb-2">
          Edytuj ogłoszenie
        </h1>
        <p className="text-muted-foreground mb-8">
          Zaktualizuj szczegóły ogłoszenia
        </p>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
          {/* Category */}
          <div className="space-y-3">
            <Label>Kategoria *</Label>
            <RadioGroup
              value={category}
              className="flex gap-4"
              onValueChange={(v) => {
                const event = { target: { name: "category", value: v } };
                register("category").onChange(event as any);
              }}
            >
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="pojazd" id="pojazd" />
                <Label htmlFor="pojazd" className="flex items-center gap-2 cursor-pointer">
                  <Car className="h-4 w-4" />
                  Pojazd
                </Label>
              </div>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="czesc" id="czesc" />
                <Label htmlFor="czesc" className="flex items-center gap-2 cursor-pointer">
                  <Cog className="h-4 w-4" />
                  Część
                </Label>
              </div>
            </RadioGroup>
          </div>

          {/* Title */}
          <div className="space-y-2">
            <Label htmlFor="title">Tytuł ogłoszenia *</Label>
            <Input
              id="title"
              placeholder="np. Mercedes 450 SL 1978 - bardzo dobry stan"
              {...register("title")}
            />
            {errors.title && (
              <p className="text-sm text-destructive">{errors.title.message}</p>
            )}
          </div>

          {/* Description */}
          <div className="space-y-2">
            <Label htmlFor="description">Opis</Label>
            <Textarea
              id="description"
              placeholder="Opisz szczegóły ogłoszenia..."
              rows={5}
              {...register("description")}
            />
            {errors.description && (
              <p className="text-sm text-destructive">{errors.description.message}</p>
            )}
          </div>

          {/* Phone Number */}
          <div className="space-y-2">
            <Label htmlFor="phone_number" className="flex items-center gap-2">
              <Phone className="h-4 w-4 text-primary" />
              Numer telefonu *
            </Label>
            <Input
              id="phone_number"
              type="tel"
              placeholder="+48 123 456 789"
              {...register("phone_number")}
            />
            {errors.phone_number && (
              <p className="text-sm text-destructive">{errors.phone_number.message}</p>
            )}
          </div>

          {/* Price and Currency */}
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="price">Cena *</Label>
              <Input
                id="price"
                type="number"
                placeholder="25000"
                {...register("price")}
              />
              {errors.price && (
                <p className="text-sm text-destructive">{errors.price.message}</p>
              )}
            </div>
            <div className="space-y-2">
              <Label htmlFor="currency">Waluta *</Label>
              <select
                id="currency"
                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                {...register("currency")}
              >
                <option value="PLN">PLN</option>
                <option value="EUR">EUR</option>
                <option value="USD">USD</option>
              </select>
            </div>
          </div>

          {/* Year (for vehicles) */}
          {category === "pojazd" && (
            <div className="space-y-2">
              <Label htmlFor="year_from">Rocznik</Label>
              <Input
                id="year_from"
                type="number"
                placeholder="1978"
                min={1970}
                max={1989}
                {...register("year_from")}
              />
              {errors.year_from && (
                <p className="text-sm text-destructive">{errors.year_from.message}</p>
              )}
            </div>
          )}

          {/* YouTube URL */}
          <div className="space-y-2">
            <Label htmlFor="youtube_url" className="flex items-center gap-2">
              <Youtube className="h-4 w-4 text-red-500" />
              Link do filmu YouTube
            </Label>
            <Input
              id="youtube_url"
              type="url"
              placeholder="https://youtube.com/watch?v=..."
              {...register("youtube_url")}
            />
            {errors.youtube_url && (
              <p className="text-sm text-destructive">{errors.youtube_url.message}</p>
            )}
          </div>

          {/* Images */}
          <div className="space-y-3">
            <Label>Zdjęcia * (max. {MAX_IMAGES})</Label>
            <div className="grid grid-cols-3 gap-3">
              {images.map((img) => (
                <div
                  key={img.id}
                  className="relative aspect-square rounded-lg overflow-hidden border border-border bg-muted"
                >
                  <img
                    src={img.preview}
                    alt="Preview"
                    className="w-full h-full object-cover"
                  />
                  {img.uploading && (
                    <div className="absolute inset-0 bg-background/80 flex items-center justify-center">
                      <Loader2 className="h-6 w-6 animate-spin text-primary" />
                    </div>
                  )}
                  <button
                    type="button"
                    onClick={() => removeImage(img.id)}
                    className="absolute top-1 right-1 bg-destructive text-white rounded-full p-1 hover:bg-destructive/90"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>
              ))}
              {images.length < MAX_IMAGES && (
                <label className="aspect-square rounded-lg border-2 border-dashed border-border bg-muted/50 flex flex-col items-center justify-center cursor-pointer hover:bg-muted/80 transition-colors">
                  <Upload className="h-6 w-6 text-muted-foreground mb-1" />
                  <span className="text-xs text-muted-foreground">Dodaj</span>
                  <input
                    type="file"
                    accept="image/*"
                    multiple
                    className="hidden"
                    onChange={handleImageSelect}
                  />
                </label>
              )}
            </div>
          </div>

          <Alert>
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>
              Po edycji ogłoszenie trafi do ponownej moderacji.
            </AlertDescription>
          </Alert>

          <div className="flex gap-3">
            <Button type="submit" disabled={submitting} className="flex-1">
              {submitting ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Zapisuję...
                </>
              ) : (
                "Zapisz zmiany"
              )}
            </Button>
            <Button type="button" variant="outline" onClick={() => navigate("/konto")}>
              Anuluj
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
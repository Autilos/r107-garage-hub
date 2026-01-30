import { useEffect, useState } from "react";
import { useAuth } from "@/hooks/useAuth";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Bell, Car, Wrench, X } from "lucide-react";
import { toast } from "sonner";

interface NotificationSettingsData {
  email_new_listings: boolean;
  email_new_comments: boolean;
}

interface CategorySubscription {
  id: string;
  category: string;
}

export function NotificationSettings() {
  const { user } = useAuth();
  const [settings, setSettings] = useState<NotificationSettingsData>({
    email_new_listings: true,
    email_new_comments: true,
  });
  const [categorySubscriptions, setCategorySubscriptions] = useState<CategorySubscription[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (user) {
      fetchSettings();
      fetchCategorySubscriptions();
    }
  }, [user]);

  const fetchSettings = async () => {
    if (!user) return;

    const { data, error } = await supabase
      .from("notification_settings")
      .select("*")
      .eq("user_id", user.id)
      .maybeSingle();

    if (error) {
      console.error("Error fetching notification settings:", error);
    } else if (data) {
      setSettings({
        email_new_listings: data.email_new_listings,
        email_new_comments: data.email_new_comments,
      });
    } else {
      // Create default settings if they don't exist
      const { error: insertError } = await supabase
        .from("notification_settings")
        .insert({ user_id: user.id });

      if (insertError) {
        console.error("Error creating notification settings:", insertError);
      }
    }
    setIsLoading(false);
  };

  const fetchCategorySubscriptions = async () => {
    if (!user) return;

    const { data, error } = await supabase
      .from("category_subscriptions")
      .select("*")
      .eq("user_id", user.id);

    if (error) {
      console.error("Error fetching category subscriptions:", error);
    } else {
      setCategorySubscriptions(data || []);
    }
  };

  const updateSetting = async (key: keyof NotificationSettingsData, value: boolean) => {
    if (!user) return;

    setSettings((prev) => ({ ...prev, [key]: value }));
    setIsSaving(true);

    const { error } = await supabase
      .from("notification_settings")
      .update({ [key]: value })
      .eq("user_id", user.id);

    setIsSaving(false);

    if (error) {
      console.error("Error updating notification setting:", error);
      toast.error("Błąd podczas zapisywania ustawień");
      setSettings((prev) => ({ ...prev, [key]: !value }));
    } else {
      toast.success("Ustawienia zapisane");
    }
  };

  const subscribeToCategory = async (category: string) => {
    if (!user) return;

    const existingSubscription = categorySubscriptions.find((s) => s.category === category);
    if (existingSubscription) {
      toast.info("Już subskrybujesz tę kategorię");
      return;
    }

    const { data, error } = await supabase
      .from("category_subscriptions")
      .insert({ user_id: user.id, category })
      .select()
      .single();

    if (error) {
      console.error("Error subscribing to category:", error);
      toast.error("Błąd podczas subskrypcji");
    } else {
      setCategorySubscriptions((prev) => [...prev, data]);
      toast.success(`Subskrybujesz kategorię: ${category === "pojazd" ? "Pojazdy" : "Części"}`);
    }
  };

  const unsubscribeFromCategory = async (subscriptionId: string) => {
    const { error } = await supabase
      .from("category_subscriptions")
      .delete()
      .eq("id", subscriptionId);

    if (error) {
      console.error("Error unsubscribing from category:", error);
      toast.error("Błąd podczas anulowania subskrypcji");
    } else {
      setCategorySubscriptions((prev) => prev.filter((s) => s.id !== subscriptionId));
      toast.success("Anulowano subskrypcję");
    }
  };

  if (isLoading) {
    return (
      <Card>
        <CardContent className="p-6">
          <div className="animate-pulse space-y-4">
            <div className="h-4 bg-muted rounded w-1/3"></div>
            <div className="h-10 bg-muted rounded"></div>
            <div className="h-10 bg-muted rounded"></div>
          </div>
        </CardContent>
      </Card>
    );
  }

  const isSubscribedToCategory = (category: string) =>
    categorySubscriptions.some((s) => s.category === category);

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Bell className="h-5 w-5" />
            Powiadomienia email
          </CardTitle>
          <CardDescription>
            Wybierz jakie powiadomienia chcesz otrzymywać na email
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <Label htmlFor="email_new_listings" className="text-base">
                Nowe ogłoszenia
              </Label>
              <p className="text-sm text-muted-foreground">
                Otrzymuj powiadomienia o nowych ogłoszeniach w obserwowanych kategoriach
              </p>
            </div>
            <Switch
              id="email_new_listings"
              checked={settings.email_new_listings}
              onCheckedChange={(value) => updateSetting("email_new_listings", value)}
              disabled={isSaving}
            />
          </div>

          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <Label htmlFor="email_new_comments" className="text-base">
                Nowe komentarze
              </Label>
              <p className="text-sm text-muted-foreground">
                Otrzymuj powiadomienia o nowych komentarzach w obserwowanych artykułach
              </p>
            </div>
            <Switch
              id="email_new_comments"
              checked={settings.email_new_comments}
              onCheckedChange={(value) => updateSetting("email_new_comments", value)}
              disabled={isSaving}
            />
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Car className="h-5 w-5" />
            Obserwowane kategorie ogłoszeń
          </CardTitle>
          <CardDescription>
            Subskrybuj kategorie, aby otrzymywać powiadomienia o nowych ogłoszeniach
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex flex-wrap gap-2">
            {categorySubscriptions.map((sub) => (
              <Badge key={sub.id} variant="secondary" className="flex items-center gap-1 pr-1">
                {sub.category === "pojazd" ? (
                  <>
                    <Car className="h-3 w-3" />
                    Pojazdy
                  </>
                ) : (
                  <>
                    <Wrench className="h-3 w-3" />
                    Części
                  </>
                )}
                <button
                  onClick={() => unsubscribeFromCategory(sub.id)}
                  className="ml-1 p-0.5 hover:bg-destructive/20 rounded"
                >
                  <X className="h-3 w-3" />
                </button>
              </Badge>
            ))}
            {categorySubscriptions.length === 0 && (
              <p className="text-sm text-muted-foreground">Nie subskrybujesz żadnych kategorii</p>
            )}
          </div>

          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => subscribeToCategory("pojazd")}
              disabled={isSubscribedToCategory("pojazd")}
            >
              <Car className="h-4 w-4 mr-2" />
              Subskrybuj Pojazdy
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => subscribeToCategory("czesc")}
              disabled={isSubscribedToCategory("czesc")}
            >
              <Wrench className="h-4 w-4 mr-2" />
              Subskrybuj Części
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

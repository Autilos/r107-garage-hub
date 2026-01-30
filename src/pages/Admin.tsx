import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Rss, Youtube, Tag, Store, Wrench } from "lucide-react";
import { useAuth } from "@/hooks/useAuth";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { RepairVideosManager } from "@/components/admin/RepairVideosManager";
import { RepairPartsManager } from "@/components/admin/RepairPartsManager";
import { ListingsApproval } from "@/components/admin/ListingsApproval";
import { ShopsApproval } from "@/components/admin/ShopsApproval";
import { ArticleEditor } from "@/components/admin/ArticleEditor";
import { RssSourcesManager } from "@/components/admin/RssSourcesManager";
import { BookOpen as TagName } from "lucide-react";

export default function Admin() {
  const { user, isAdmin, isLoading: authLoading } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (!authLoading && (!user || !isAdmin)) {
      navigate("/konto");
    }
  }, [user, isAdmin, authLoading, navigate]);

  if (authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!user || !isAdmin) {
    return null;
  }

  return (
    <div className="min-h-screen py-20">
      <div className="container">
        <h1 className="font-heading text-3xl font-bold text-foreground mb-8">
          Panel Administratora
        </h1>

        <Tabs defaultValue="listings" className="space-y-6">
          <TabsList className="flex-wrap h-auto gap-1">
            <TabsTrigger value="listings" className="gap-2">
              <Tag className="h-4 w-4" />
              Ogłoszenia
            </TabsTrigger>
            <TabsTrigger value="shops" className="gap-2">
              <Store className="h-4 w-4" />
              Sklepy
            </TabsTrigger>
            <TabsTrigger value="rss" className="gap-2">
              <Rss className="h-4 w-4" />
              Źródła RSS
            </TabsTrigger>
            <TabsTrigger value="articles" className="gap-2">
              <TagName className="h-4 w-4" />
              Artykuły
            </TabsTrigger>

            <TabsTrigger value="videos" className="gap-2">
              <Youtube className="h-4 w-4" />
              Filmy napraw
            </TabsTrigger>
            <TabsTrigger value="parts" className="gap-2">
              <Wrench className="h-4 w-4" />
              Części zamienne
            </TabsTrigger>
          </TabsList>

          <TabsContent value="listings">
            <ListingsApproval />
          </TabsContent>

          <TabsContent value="shops">
            <ShopsApproval />
          </TabsContent>

          <TabsContent value="rss" className="space-y-6">
            <RssSourcesManager />
          </TabsContent>

          <TabsContent value="articles">
            <ArticleEditor />
          </TabsContent>


          <TabsContent value="videos">
            <RepairVideosManager />
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}


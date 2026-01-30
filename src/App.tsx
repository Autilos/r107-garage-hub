import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { AuthProvider } from "@/hooks/useAuth";
import { Layout } from "@/components/layout/Layout";
import Index from "./pages/Index";
import Account from "./pages/Account";
import Listings from "./pages/Listings";
import AddListing from "./pages/AddListing";
import EditListing from "./pages/EditListing";
import Repairs from "./pages/Repairs";
import RepairCategory from "./pages/RepairCategory";
import Shops from "./pages/Shops";
import Blog from "./pages/Blog";
import Article from "./pages/Article";

import Admin from "./pages/Admin";
import NotFound from "./pages/NotFound";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <AuthProvider>
      <TooltipProvider>
        <Toaster />
        <Sonner />
        <BrowserRouter>
          <Layout>
            <Routes>
              <Route path="/" element={<Index />} />
              <Route path="/konto" element={<Account />} />
              <Route path="/ogloszenia" element={<Listings />} />
              <Route path="/ogloszenia/dodaj" element={<AddListing />} />
              <Route path="/ogloszenia/edytuj/:id" element={<EditListing />} />
              <Route path="/naprawy" element={<Repairs />} />
              <Route path="/naprawy/:slug" element={<RepairCategory />} />
              <Route path="/sklepy" element={<Shops />} />
              <Route path="/blog" element={<Blog />} />
              <Route path="/blog/:slug" element={<Article />} />
              <Route path="/admin" element={<Admin />} />
              <Route path="*" element={<NotFound />} />
            </Routes>
          </Layout>
        </BrowserRouter>
      </TooltipProvider>
    </AuthProvider>
  </QueryClientProvider>
);

export default App;

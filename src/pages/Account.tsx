import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { z } from "zod";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Eye, EyeOff, Mail, Lock, User, LogOut, Settings, Tag, ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useAuth } from "@/hooks/useAuth";
import { useToast } from "@/hooks/use-toast";
import { NotificationSettings } from "@/components/notifications/NotificationSettings";
import { UserListingsManager } from "@/components/listings/UserListingsManager";
import { supabase } from "@/integrations/supabase/client";

const loginSchema = z.object({
  email: z.string().email("Nieprawidłowy adres email"),
  password: z.string().min(6, "Hasło musi mieć minimum 6 znaków"),
});

const signupSchema = z.object({
  email: z.string().email("Nieprawidłowy adres email"),
  password: z.string().min(6, "Hasło musi mieć minimum 6 znaków"),
  displayName: z.string().min(2, "Nazwa musi mieć minimum 2 znaki").optional(),
});

const resetSchema = z.object({
  email: z.string().email("Nieprawidłowy adres email"),
});

const newPasswordSchema = z.object({
  password: z.string().min(6, "Hasło musi mieć minimum 6 znaków"),
  confirmPassword: z.string().min(6, "Hasło musi mieć minimum 6 znaków"),
}).refine((data) => data.password === data.confirmPassword, {
  message: "Hasła muszą być identyczne",
  path: ["confirmPassword"],
});

type LoginFormData = z.infer<typeof loginSchema>;
type SignupFormData = z.infer<typeof signupSchema>;
type ResetFormData = z.infer<typeof resetSchema>;
type NewPasswordFormData = z.infer<typeof newPasswordSchema>;

type ViewState = "login" | "signup" | "forgot-password";

export default function Account() {
  const [view, setView] = useState<ViewState>("login");
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();
  const { signIn, signUp, signOut, user, isPasswordRecovery, updatePassword, clearPasswordRecovery } = useAuth();
  const { toast } = useToast();
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const loginForm = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: "", password: "" },
  });

  const signupForm = useForm<SignupFormData>({
    resolver: zodResolver(signupSchema),
    defaultValues: { email: "", password: "", displayName: "" },
  });

  const resetForm = useForm<ResetFormData>({
    resolver: zodResolver(resetSchema),
    defaultValues: { email: "" },
  });

  const newPasswordForm = useForm<NewPasswordFormData>({
    resolver: zodResolver(newPasswordSchema),
    defaultValues: { password: "", confirmPassword: "" },
  });

  const handleSignOut = async () => {
    await signOut();
    toast({
      title: "Wylogowano",
      description: "Do zobaczenia!",
    });
    navigate("/");
  };

  // Show password reset form if in recovery mode
  if (isPasswordRecovery) {
    const handleNewPassword = async (data: NewPasswordFormData) => {
      setIsLoading(true);
      const { error } = await updatePassword(data.password);
      setIsLoading(false);

      if (error) {
        toast({
          title: "Błąd",
          description: error.message,
          variant: "destructive",
        });
      } else {
        toast({
          title: "Hasło zmienione",
          description: "Twoje hasło zostało pomyślnie zaktualizowane.",
        });
        navigate("/");
      }
    };

    return (
      <div className="min-h-screen flex items-start justify-center pt-10 pb-20">
        <div className="card-automotive p-8 max-w-md w-full mx-4">
          <div className="text-center mb-8">
            <h1 className="font-heading text-2xl font-bold text-foreground mb-2">
              Ustaw nowe hasło
            </h1>
            <p className="text-muted-foreground text-sm">
              Wprowadź swoje nowe hasło poniżej
            </p>
          </div>

          <Form {...newPasswordForm}>
            <form
              onSubmit={newPasswordForm.handleSubmit(handleNewPassword)}
              className="space-y-4"
            >
              <FormField
                control={newPasswordForm.control}
                name="password"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Nowe hasło</FormLabel>
                    <FormControl>
                      <div className="relative">
                        <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
                        <Input
                          {...field}
                          type={showPassword ? "text" : "password"}
                          placeholder="Minimum 6 znaków"
                          className="pl-10 pr-10"
                        />
                        <button
                          type="button"
                          onClick={() => setShowPassword(!showPassword)}
                          className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                        >
                          {showPassword ? (
                            <EyeOff className="h-4 w-4" />
                          ) : (
                            <Eye className="h-4 w-4" />
                          )}
                        </button>
                      </div>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={newPasswordForm.control}
                name="confirmPassword"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Potwierdź hasło</FormLabel>
                    <FormControl>
                      <div className="relative">
                        <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
                        <Input
                          {...field}
                          type={showConfirmPassword ? "text" : "password"}
                          placeholder="Powtórz hasło"
                          className="pl-10 pr-10"
                        />
                        <button
                          type="button"
                          onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                          className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                        >
                          {showConfirmPassword ? (
                            <EyeOff className="h-4 w-4" />
                          ) : (
                            <Eye className="h-4 w-4" />
                          )}
                        </button>
                      </div>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <Button type="submit" className="w-full" disabled={isLoading}>
                {isLoading ? "Zapisywanie..." : "Zapisz nowe hasło"}
              </Button>
            </form>
          </Form>

          <div className="mt-6 text-center">
            <button
              type="button"
              onClick={() => {
                clearPasswordRecovery();
                navigate("/");
              }}
              className="text-sm text-muted-foreground hover:text-primary transition-colors"
            >
              Anuluj
            </button>
          </div>
        </div>
      </div>
    );
  }

  // Show dashboard if logged in
  if (user) {
    return (
      <div className="min-h-screen py-10 px-4">
        <div className="max-w-3xl mx-auto">
          <div className="flex items-center justify-between mb-8">
            <div>
              <h1 className="font-heading text-2xl font-bold text-foreground">
                Moje konto
              </h1>
              <p className="text-muted-foreground">
                {user.email}
              </p>
            </div>
            <Button variant="outline" onClick={handleSignOut}>
              <LogOut className="h-4 w-4 mr-2" />
              Wyloguj
            </Button>
          </div>

          <Tabs defaultValue="listings" className="space-y-6">
            <TabsList>
              <TabsTrigger value="listings">
                <Tag className="h-4 w-4 mr-2" />
                Moje ogłoszenia
              </TabsTrigger>
              <TabsTrigger value="notifications">
                <Settings className="h-4 w-4 mr-2" />
                Powiadomienia
              </TabsTrigger>
            </TabsList>
            <TabsContent value="listings">
              <UserListingsManager />
            </TabsContent>
            <TabsContent value="notifications">
              <NotificationSettings />
            </TabsContent>
          </Tabs>
        </div>
      </div>
    );
  }

  const handleLogin = async (data: LoginFormData) => {
    setIsLoading(true);
    const { error } = await signIn(data.email, data.password);
    setIsLoading(false);

    if (error) {
      toast({
        title: "Błąd logowania",
        description: error.message === "Invalid login credentials" 
          ? "Nieprawidłowy email lub hasło"
          : error.message,
        variant: "destructive",
      });
    } else {
      toast({
        title: "Zalogowano pomyślnie",
        description: "Witaj ponownie!",
      });
      navigate("/");
    }
  };

  const handleSignup = async (data: SignupFormData) => {
    setIsLoading(true);
    const { error } = await signUp(data.email, data.password, data.displayName);
    setIsLoading(false);

    if (error) {
      let message = error.message;
      if (error.message.includes("already registered")) {
        message = "Ten email jest już zarejestrowany. Spróbuj się zalogować.";
      }
      toast({
        title: "Błąd rejestracji",
        description: message,
        variant: "destructive",
      });
    } else {
      toast({
        title: "Sprawdź email",
        description: "Wysłaliśmy link potwierdzający na adres " + data.email,
      });
    }
  };

  const handlePasswordReset = async (data: ResetFormData) => {
    setIsLoading(true);
    const { error } = await supabase.auth.resetPasswordForEmail(data.email, {
      redirectTo: `${window.location.origin}/konto`,
    });
    setIsLoading(false);

    if (error) {
      toast({
        title: "Błąd",
        description: error.message,
        variant: "destructive",
      });
    } else {
      toast({
        title: "Email wysłany",
        description: "Sprawdź skrzynkę pocztową i kliknij w link resetujący hasło.",
      });
      setView("login");
    }
  };

  const getTitle = () => {
    switch (view) {
      case "login":
        return "Zaloguj się";
      case "signup":
        return "Utwórz konto";
      case "forgot-password":
        return "Resetuj hasło";
    }
  };

  const getDescription = () => {
    switch (view) {
      case "login":
        return "Zaloguj się, aby dodawać ogłoszenia i komentować";
      case "signup":
        return "Dołącz do społeczności R107 Garage";
      case "forgot-password":
        return "Podaj swój email, a wyślemy Ci link do zresetowania hasła";
    }
  };

  return (
    <div className="min-h-screen flex items-start justify-center pt-10 pb-20">
      <div className="card-automotive p-8 max-w-md w-full mx-4">
        <div className="text-center mb-8">
          {view === "forgot-password" && (
            <button
              type="button"
              onClick={() => setView("login")}
              className="flex items-center text-sm text-muted-foreground hover:text-primary transition-colors mb-4"
            >
              <ArrowLeft className="h-4 w-4 mr-1" />
              Wróć do logowania
            </button>
          )}
          <h1 className="font-heading text-2xl font-bold text-foreground mb-2">
            {getTitle()}
          </h1>
          <p className="text-muted-foreground text-sm">
            {getDescription()}
          </p>
        </div>

        {view === "login" && (
          <Form {...loginForm}>
            <form
              onSubmit={loginForm.handleSubmit(handleLogin)}
              className="space-y-4"
            >
              <FormField
                control={loginForm.control}
                name="email"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Email</FormLabel>
                    <FormControl>
                      <div className="relative">
                        <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
                        <Input
                          {...field}
                          type="email"
                          placeholder="twoj@email.pl"
                          className="pl-10"
                        />
                      </div>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={loginForm.control}
                name="password"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Hasło</FormLabel>
                    <FormControl>
                      <div className="relative">
                        <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
                        <Input
                          {...field}
                          type={showPassword ? "text" : "password"}
                          placeholder="••••••••"
                          className="pl-10 pr-10"
                        />
                        <button
                          type="button"
                          onClick={() => setShowPassword(!showPassword)}
                          className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                        >
                          {showPassword ? (
                            <EyeOff className="h-4 w-4" />
                          ) : (
                            <Eye className="h-4 w-4" />
                          )}
                        </button>
                      </div>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <div className="text-right">
                <button
                  type="button"
                  onClick={() => setView("forgot-password")}
                  className="text-sm text-muted-foreground hover:text-primary transition-colors"
                >
                  Zapomniałeś hasła?
                </button>
              </div>
              <Button type="submit" className="w-full" disabled={isLoading}>
                {isLoading ? "Logowanie..." : "Zaloguj się"}
              </Button>
            </form>
          </Form>
        )}

        {view === "signup" && (
          <Form {...signupForm}>
            <form
              onSubmit={signupForm.handleSubmit(handleSignup)}
              className="space-y-4"
            >
              <div className="space-y-4">
                <FormItem>
                  <FormLabel>Nazwa użytkownika (opcjonalnie)</FormLabel>
                  <FormControl>
                    <div className="relative">
                      <User className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
                      <Input
                        placeholder="Jan Kowalski"
                        className="pl-10"
                        autoComplete="name"
                        {...signupForm.register("displayName")}
                      />
                    </div>
                  </FormControl>
                  {signupForm.formState.errors.displayName?.message ? (
                    <p className="text-sm font-medium text-destructive">
                      {String(signupForm.formState.errors.displayName.message)}
                    </p>
                  ) : null}
                </FormItem>

                <FormItem>
                  <FormLabel>Email</FormLabel>
                  <FormControl>
                    <div className="relative">
                      <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
                      <Input
                        type="email"
                        placeholder="twoj@email.pl"
                        className="pl-10"
                        autoComplete="email"
                        inputMode="email"
                        {...signupForm.register("email")}
                      />
                    </div>
                  </FormControl>
                  {signupForm.formState.errors.email?.message ? (
                    <p className="text-sm font-medium text-destructive">
                      {String(signupForm.formState.errors.email.message)}
                    </p>
                  ) : null}
                </FormItem>
              </div>
              <FormItem>
                <FormLabel>Hasło</FormLabel>
                <FormControl>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
                    <Input
                      type={showPassword ? "text" : "password"}
                      placeholder="Minimum 6 znaków"
                      className="pl-10 pr-10"
                      autoComplete="new-password"
                      {...signupForm.register("password")}
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                    >
                      {showPassword ? (
                        <EyeOff className="h-4 w-4" />
                      ) : (
                        <Eye className="h-4 w-4" />
                      )}
                    </button>
                  </div>
                </FormControl>
                {signupForm.formState.errors.password?.message ? (
                  <p className="text-sm font-medium text-destructive">
                    {String(signupForm.formState.errors.password.message)}
                  </p>
                ) : null}
              </FormItem>
              <Button type="submit" className="w-full" disabled={isLoading}>
                {isLoading ? "Tworzenie konta..." : "Utwórz konto"}
              </Button>
            </form>
          </Form>
        )}

        {view === "forgot-password" && (
          <Form {...resetForm}>
            <form
              onSubmit={resetForm.handleSubmit(handlePasswordReset)}
              className="space-y-4"
            >
              <FormField
                control={resetForm.control}
                name="email"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Email</FormLabel>
                    <FormControl>
                      <div className="relative">
                        <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
                        <Input
                          {...field}
                          type="email"
                          placeholder="twoj@email.pl"
                          className="pl-10"
                        />
                      </div>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <Button type="submit" className="w-full" disabled={isLoading}>
                {isLoading ? "Wysyłanie..." : "Wyślij link resetujący"}
              </Button>
            </form>
          </Form>
        )}

        {view !== "forgot-password" && (
          <div className="mt-6 text-center">
            <button
              type="button"
              onClick={() => setView(view === "login" ? "signup" : "login")}
              className="text-sm text-muted-foreground hover:text-primary transition-colors"
            >
              {view === "login"
                ? "Nie masz konta? Zarejestruj się"
                : "Masz już konto? Zaloguj się"}
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
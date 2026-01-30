# Migracja z OpenAI na Gemini - Instrukcja

## ✅ Zmiany w kodzie (GOTOWE)

Zaktualizowałem funkcję Edge Function `ingest-rss` aby używała **Google Gemini 2.0 Flash** zamiast OpenAI GPT-4o-mini.

### Kluczowe zmiany:
1. **Model**: `gemini-2.0-flash-exp` (szybszy i lepszy w ekstrakcji strukturalnych danych)
2. **Max tokens**: zwiększone z 400 do 800 dla lepszej analizy
3. **Response format**: `application/json` dla gwarantowanego formatu JSON
4. **Dodatkowe przykłady**: więcej przykładów cen z USA ($11,900, $25,000, $18900)
5. **Priorytet**: dodano punkt 10: "Jeśli w tytule jest cena, MUSISZ ją wyciągnąć - to najważniejsze!"

## 🔧 Konfiguracja wymagana w Supabase

### Krok 1: Uzyskaj klucz API Gemini

1. Przejdź do: https://aistudio.google.com/app/apikey
2. Zaloguj się kontem Google
3. Kliknij **"Get API key"** lub **"Create API key"**
4. Skopiuj wygenerowany klucz (zaczyna się od `AIza...`)

### Krok 2: Dodaj klucz do Supabase

#### Opcja A: Przez Dashboard Supabase (ZALECANE)

1. Otwórz: https://supabase.com/dashboard/project/xqsdepmtejvnngcnrklk/settings/functions
2. Przejdź do zakładki **"Edge Functions"** → **"Secrets"**
3. Kliknij **"Add new secret"**
4. Nazwa: `GEMINI_API_KEY`
5. Wartość: Twój klucz API Gemini (np. `AIzaSyDppmrWYujSyQdmzmzCFO2J3USr-f-_pn0`)
6. Kliknij **"Save"**

#### Opcja B: Przez CLI Supabase

```bash
# Zainstaluj Supabase CLI (jeśli jeszcze nie masz)
brew install supabase/tap/supabase

# Zaloguj się
supabase login

# Link do projektu
cd /Users/wojciechnowak/Projekty/r107-garage-hub
supabase link --project-ref xqsdepmtejvnngcnrklk

# Dodaj secret
supabase secrets set GEMINI_API_KEY=AIzaSyDppmrWYujSyQdmzmzCFO2J3USr-f-_pn0
```

### Krok 3: Deploy zaktualizowanej funkcji

```bash
cd /Users/wojciechnowak/Projekty/r107-garage-hub

# Deploy funkcji ingest-rss
supabase functions deploy ingest-rss
```

## 🧪 Testowanie

Po wdrożeniu, przetestuj funkcję:

1. Otwórz aplikację r107-garage-hub
2. Przejdź do panelu Admin
3. Kliknij **"Uruchom pobieranie RSS"**
4. Sprawdź logi w konsoli Supabase: https://supabase.com/dashboard/project/xqsdepmtejvnngcnrklk/logs/edge-functions

## 📊 Oczekiwane rezultaty

Po migracji na Gemini:
- ✅ Lepsza ekstrakcja cen z tytułów (szczególnie USA z formatem $XX,XXX)
- ✅ Szybsze przetwarzanie (Gemini 2.0 Flash jest bardzo szybki)
- ✅ Niższe koszty (Gemini jest tańszy niż GPT-4o-mini)
- ✅ Lepsze rozpoznawanie modeli R107/C107

## 🔍 Weryfikacja działania

Sprawdź w bazie danych czy nowe ogłoszenia z USA mają poprawnie wyciągniętą cenę:

```sql
SELECT 
  title, 
  price, 
  currency, 
  llm_reason,
  created_at
FROM listings
WHERE source_type = 'rss'
  AND country = 'USA'
ORDER BY created_at DESC
LIMIT 10;
```

## ⚠️ Uwagi

- Błędy TypeScript w IDE (Deno modules) są normalne - to Edge Function dla Deno runtime
- Stary klucz `OPENAI_API_KEY` można usunąć z Supabase secrets
- Gemini API ma limit: 1500 requestów/dzień w darmowym planie (wystarczy dla RSS)

## 📝 Changelog

**2025-12-28**
- Migracja z OpenAI GPT-4o-mini → Google Gemini 2.0 Flash
- Zwiększenie max_tokens: 400 → 800
- Dodanie `responseMimeType: "application/json"`
- Rozszerzenie przykładów cen z USA
- Dodanie priorytetu ekstrakcji ceny z tytułu

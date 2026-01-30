# Debug kroków - Błąd Edge Function

## Krok 1: Sprawdź szczegóły w Network tab

1. Otwórz DevTools (F12)
2. Przejdź do zakładki **Network**
3. Wyczyść historię (ikona 🚫)
4. Kliknij "Uruchom pobieranie" w aplikacji
5. Znajdź request do `ingest-rss` (będzie na czerwono jeśli błąd)
6. Kliknij na niego
7. Sprawdź:
   - **Headers** → Status Code (np. 401, 403, 500)
   - **Response** → tam będzie JSON z dokładnym błędem
   - **Preview** → czytelna forma odpowiedzi

## Krok 2: Sprawdź logi w Supabase

https://supabase.com/dashboard/project/xcbufsemfbklgbcmkitn/logs/edge-functions

1. Ustaw czas na "Last 5 minutes"
2. Kliknij "Uruchom pobieranie"
3. Odśwież logi
4. Znajdź wpis z poziomem "error" lub "log"

## Krok 3: Sprawdź czy użytkownik jest adminem

Uruchom w konsoli przeglądarki:

```javascript
const { data: { user } } = await supabase.auth.getUser();
console.log('User:', user);

const { data: isAdmin } = await supabase.rpc('is_admin');
console.log('Is admin:', isAdmin);
```

## Możliwe przyczyny błędu:

1. **401 Unauthorized** - brak tokenu lub nieprawidłowy token
2. **403 Forbidden** - użytkownik nie jest adminem
3. **500 Internal Server Error** - błąd w kodzie funkcji (np. brak OPENAI_API_KEY)

## Następne kroki:

Po uzyskaniu dokładnego kodu błędu i szczegółów, będziemy mogli go naprawić.

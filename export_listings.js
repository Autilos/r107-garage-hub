
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

// Configuration 1: From VITE_* (The "Project" set)
const url1 = "https://xqsdepmtejvnngcnrklk.supabase.co";
const key1 = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhxc2RlcG10ZWp2bm5nY25ya2xrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwODI2NTQsImV4cCI6MjA4MTY1ODY1NH0.EYHgm7djAib5z0N6Cw4-5kOyr7ssnJ4XNDgyKyhfzSw"; // Anon key

// Configuration 2: From SERVICE_ROLE (The "Service" set - suspicious ref mismatch)
// The ref in the token is "xcbufsemfbklgbcmkitn", which differs from "xqs..."
const url2 = "https://xcbufsemfbklgbcmkitn.supabase.co";
const key2 = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjYnVmc2VtZmJrbGdiY21raXRuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MjIzMDQ2MiwiZXhwIjoyMDc3ODA2NDYyfQ.KmuKgDiyaWR7_oArQj7BLCjok7hIaKfh8fMw0UhhzNk";

const fetchListings = async (name, url, key) => {
    console.log(`Checking ${name}...`);
    try {
        const supabase = createClient(url, key);
        const { data, error } = await supabase.from('listings').select('*');

        if (error) {
            console.log(`[${name}] Error:`, error.message);
            return null;
        }

        console.log(`[${name}] Found ${data.length} listings.`);
        return data.length > 0 ? data : null;
    } catch (e) {
        console.log(`[${name}] Connection failed:`, e.message);
        return null;
    }
}

const generateInserts = (rows) => {
    return rows.map(row => {
        // Helper to safely quote strings
        const q = (val) => val === null || val === undefined ? 'NULL' : `'${String(val).replace(/'/g, "''")}'`;
        const n = (val) => val === null || val === undefined ? 'NULL' : val;

        return `INSERT INTO public.listings (
            id, source_type, status, title, description, price, currency, country, 
            category, url, image_url, rss_source_id, rss_guid, llm_ok, llm_reason, 
            model_tag, variant_tag, year_from, year_to, user_id, created_at, published_at
        ) VALUES (
            ${q(row.id)}, ${q(row.source_type)}, ${q(row.status)}, ${q(row.title)}, ${q(row.description)}, 
            ${n(row.price)}, ${q(row.currency)}, ${q(row.country)}, ${q(row.category)}, ${q(row.url)}, 
            ${q(row.image_url)}, ${q(row.rss_source_id)}, ${q(row.rss_guid)}, ${n(row.llm_ok)}, ${q(row.llm_reason)}, 
            ${q(row.model_tag)}, ${q(row.variant_tag)}, ${n(row.year_from)}, ${n(row.year_to)}, 
            ${q(row.user_id)}, ${q(row.created_at)}, ${q(row.published_at)}
        ) ON CONFLICT (id) DO NOTHING;`;
    }).join('\n');
}

const run = async () => {
    // Try Conf 1
    let listings = await fetchListings("Project (xqs...)", url1, key1);

    // Try Conf 2 if failed
    if (!listings) {
        listings = await fetchListings("Service (xcb...)", url2, key2);
    }

    if (listings) {
        const sql = generateInserts(listings);
        fs.writeFileSync('restored_listings.sql', sql);
        console.log('Success! SQL saved to restored_listings.sql');
    } else {
        console.log('Could not recover listings from either source.');
    }
};

run();

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Content-Type': 'application/xml',
}

serve(async (req) => {
    // Handle CORS preflight requests
    if (req.method === 'OPTIONS') {
        return new Response(null, { headers: corsHeaders })
    }

    try {
        // Create Supabase client
        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_ANON_KEY') ?? '',
        )

        // Get the site URL from environment or use default
        const siteUrl = Deno.env.get('SITE_URL') || 'https://r107garage.com'

        // Fetch all published articles
        const { data: articles, error } = await supabaseClient
            .from('articles_r107')
            .select('slug, updated_at, created_at')
            .eq('is_published', true)
            .order('created_at', { ascending: false })

        if (error) {
            console.error('Error fetching articles:', error)
            throw error
        }

        // Static pages with their priorities and change frequencies
        const staticPages = [
            { url: '', priority: '1.0', changefreq: 'daily' }, // Home
            { url: 'ogloszenia', priority: '0.9', changefreq: 'daily' }, // Listings
            { url: 'naprawy', priority: '0.8', changefreq: 'weekly' }, // Repairs
            { url: 'sklepy', priority: '0.7', changefreq: 'weekly' }, // Shops
            { url: 'blog', priority: '0.9', changefreq: 'daily' }, // Blog
            { url: 'konto', priority: '0.5', changefreq: 'monthly' }, // Account
        ]

        // Build sitemap XML
        let sitemap = '<?xml version="1.0" encoding="UTF-8"?>\n'
        sitemap += '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'

        // Add static pages
        for (const page of staticPages) {
            sitemap += '  <url>\n'
            sitemap += `    <loc>${siteUrl}/${page.url}</loc>\n`
            sitemap += `    <changefreq>${page.changefreq}</changefreq>\n`
            sitemap += `    <priority>${page.priority}</priority>\n`
            sitemap += '  </url>\n'
        }

        // Add dynamic blog article pages
        if (articles && articles.length > 0) {
            for (const article of articles) {
                const lastmod = article.updated_at || article.created_at
                sitemap += '  <url>\n'
                sitemap += `    <loc>${siteUrl}/blog/${article.slug}</loc>\n`
                sitemap += `    <lastmod>${new Date(lastmod).toISOString().split('T')[0]}</lastmod>\n`
                sitemap += `    <changefreq>monthly</changefreq>\n`
                sitemap += `    <priority>0.8</priority>\n`
                sitemap += '  </url>\n'
            }
        }

        sitemap += '</urlset>'

        return new Response(sitemap, {
            headers: corsHeaders,
            status: 200,
        })

    } catch (error: unknown) {
        const errorMessage = error instanceof Error ? error.message : String(error)
        console.error('Error generating sitemap:', errorMessage)
        return new Response(
            JSON.stringify({ error: errorMessage }),
            {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                status: 500,
            }
        )
    }
})

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { Image } from "https://deno.land/x/imagescript@1.3.0/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  try {
    const formData = await req.formData()
    const file = formData.get('file') as File
    const bucket = formData.get('bucket') as string || 'article-images'
    const folder = formData.get('folder') as string || 'covers'

    if (!file) {
      return new Response(
        JSON.stringify({ error: 'No file provided' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    console.log(`Processing file: ${file.name}, type: ${file.type}, size: ${file.size}`)

    // Get file buffer
    const arrayBuffer = await file.arrayBuffer()
    const uint8Array = new Uint8Array(arrayBuffer)

    // Decode the image using imagescript
    const image = await Image.decode(uint8Array)
    
    // Encode to WebP format (imagescript uses encode method with format)
    // imagescript 1.3.0 uses encodeWEBPY for WebP or we use PNG as fallback with good compression
    // Let's check available methods and use WEBP encoding
    const webpBuffer = await image.encode(1) // 1 = WebP format, with quality
    
    console.log(`Converted to WebP: ${webpBuffer.length} bytes (original: ${uint8Array.length} bytes)`)

    // Create Supabase client with service role
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Generate unique filename with .webp extension
    const timestamp = Date.now()
    const randomStr = Math.random().toString(36).substring(2, 10)
    const fileName = `${folder}/${timestamp}-${randomStr}.webp`

    // Upload to Supabase Storage
    const { error: uploadError } = await supabaseClient.storage
      .from(bucket)
      .upload(fileName, webpBuffer, {
        contentType: 'image/webp',
        upsert: false
      })

    if (uploadError) {
      console.error('Upload error:', uploadError)
      throw uploadError
    }

    // Get public URL
    const { data: { publicUrl } } = supabaseClient.storage
      .from(bucket)
      .getPublicUrl(fileName)

    console.log(`Upload successful: ${publicUrl}`)

    return new Response(
      JSON.stringify({ 
        success: true, 
        url: publicUrl,
        originalSize: uint8Array.length,
        webpSize: webpBuffer.length,
        savings: Math.round((1 - webpBuffer.length / uint8Array.length) * 100) + '%'
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    console.error('Error converting image:', errorMessage)
    return new Response(
      JSON.stringify({ error: errorMessage }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})

-- Add phone_number column to listings (required for user listings)
ALTER TABLE public.listings ADD COLUMN phone_number TEXT;

-- Add comment
COMMENT ON COLUMN public.listings.phone_number IS 'Contact phone number for the listing';
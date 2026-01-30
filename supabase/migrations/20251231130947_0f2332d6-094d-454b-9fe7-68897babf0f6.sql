-- Table for user notification preferences
CREATE TABLE public.notification_settings (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE,
  email_new_listings BOOLEAN NOT NULL DEFAULT true,
  email_new_comments BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Table for category subscriptions (users watching specific listing categories)
CREATE TABLE public.category_subscriptions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  category TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(user_id, category)
);

-- Table for repair subscriptions (users watching specific repairs for comments)
CREATE TABLE public.repair_subscriptions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  repair_id UUID NOT NULL REFERENCES public.repairs(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(user_id, repair_id)
);

-- Enable RLS
ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.category_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repair_subscriptions ENABLE ROW LEVEL SECURITY;

-- RLS policies for notification_settings
CREATE POLICY "Users can view their own settings" 
ON public.notification_settings FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own settings" 
ON public.notification_settings FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own settings" 
ON public.notification_settings FOR UPDATE USING (auth.uid() = user_id);

-- RLS policies for category_subscriptions
CREATE POLICY "Users can view their own subscriptions" 
ON public.category_subscriptions FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own subscriptions" 
ON public.category_subscriptions FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own subscriptions" 
ON public.category_subscriptions FOR DELETE USING (auth.uid() = user_id);

-- RLS policies for repair_subscriptions
CREATE POLICY "Users can view their own repair subscriptions" 
ON public.repair_subscriptions FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own repair subscriptions" 
ON public.repair_subscriptions FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own repair subscriptions" 
ON public.repair_subscriptions FOR DELETE USING (auth.uid() = user_id);

-- Trigger for updated_at
CREATE TRIGGER update_notification_settings_updated_at
BEFORE UPDATE ON public.notification_settings
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Auto-create notification settings for new users
CREATE OR REPLACE FUNCTION public.handle_new_user_notifications()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  INSERT INTO public.notification_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_profile_created_add_notifications
AFTER INSERT ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user_notifications();
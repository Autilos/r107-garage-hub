-- Automated import of 428 categorized R107 videos

-- 1. Create the table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.repair_videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_slug TEXT NOT NULL,
    video_id TEXT NOT NULL,
    title TEXT NOT NULL,
    subcategory TEXT,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Enable RLS and setup public read policy
ALTER TABLE public.repair_videos ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_catalog.pg_policies 
        WHERE tablename = 'repair_videos' 
        AND policyname = 'Allow public read access'
    ) THEN
        CREATE POLICY "Allow public read access" ON public.repair_videos
            FOR SELECT USING (true);
    END IF;
END $$;

-- 3. Cleanup and Insert Data

DELETE FROM public.repair_videos WHERE sort_order = 0; -- Cleanup previous auto-imports if any

INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '8-nnjT62soE', '1000Miglia 2022 in Buonconvento Toscana - Mille Miglia R107 mechanic', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'N6LNKa0QBq4', '1972 to 1989 Mercedes R107 350SL 450SL 380SL 560SL Rear Hood Seal Challenges', 'Dachy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'N6LNKa0QBq4', '1972 to 1989 Mercedes R107 350SL 450SL 380SL 560SL Rear Hood Seal Challenges', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'DAjeLE7OvT0', '1972 to 1989 R107 Mercedes SL Convertible Hood Design Flaw: How to Avoid Injury', 'Dachy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '2ROwcOeThbg', '1977 to 1980 Mercedes Fuel Injection Delivery System Overhaul on the Bench: Before and After', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'BwZwle6xMvU', '1977 to 1985 Mercedes Diesel Rolling Restoration 2: Fix or Upgrade Lighting', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'BwZwle6xMvU', '1977 to 1985 Mercedes Diesel Rolling Restoration 2: Fix or Upgrade Lighting', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'eiwLgQkMQsY', '1981 to 1991 Mercedes Best Upgrade for the Automatic Climate Control', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'eiwLgQkMQsY', '1981 to 1991 Mercedes Best Upgrade for the Automatic Climate Control', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'ZEL9ZW5KqpA', '1981 to 1991 Mercedes Spasmodic Cabin Heat Troubleshooting Tips W123, R107 and W126 models', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'ZEL9ZW5KqpA', '1981 to 1991 Mercedes Spasmodic Cabin Heat Troubleshooting Tips W123, R107 and W126 models', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'Eo1z4ISfRp4', '220S 220SE 230SL 250SL 250SE 280SL 280SE Front Crank Seal Easy Install Tools', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Eo1z4ISfRp4', '220S 220SE 230SL 250SL 250SE 280SL 280SE Front Crank Seal Easy Install Tools', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'teIYDsPyyWQ', '280 SL Mercedes R107 - Impressions R107 screwdriver offside - Mercedes classics', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'teIYDsPyyWQ', '280 SL Mercedes R107 - Impressions R107 screwdriver offside - Mercedes classics', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'teIYDsPyyWQ', '280 SL Mercedes R107 - Impressions R107 screwdriver offside - Mercedes classics', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'teIYDsPyyWQ', '280 SL Mercedes R107 - Impressions R107 screwdriver offside - Mercedes classics', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'teIYDsPyyWQ', '280 SL Mercedes R107 - Impressions R107 screwdriver offside - Mercedes classics', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'teIYDsPyyWQ', '280 SL Mercedes R107 - Impressions R107 screwdriver offside - Mercedes classics', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'teIYDsPyyWQ', '280 SL Mercedes R107 - Impressions R107 screwdriver offside - Mercedes classics', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'teIYDsPyyWQ', '280 SL Mercedes R107 - Impressions R107 screwdriver offside - Mercedes classics', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'PLtUryA42n8', '280 SL R107 in the paint shop', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'e0EanAZAZyc', '350 SLC Mercedes C107 S-Class Coupe - predecessor of the C126', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'e0EanAZAZyc', '350 SLC Mercedes C107 S-Class Coupe - predecessor of the C126', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'lk2XlBeKBvY', '560 SEC Mercedes C126 - barn find R107 screwdriver offside', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'aA-y9WxAVdo', 'ATG Nano paint sealant - car care', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'F0N5bMujtZI', 'Adjusting the baffle plate - KE-Jetronic Mercedes 560SL R107', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '_kvOoXK_24A', 'Barrett Jackson Scottsdale Fall Oct 2025 Mercedes SL auction. USA prices holding up better than UK!!', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '_kvOoXK_24A', 'Barrett Jackson Scottsdale Fall Oct 2025 Mercedes SL auction. USA prices holding up better than UK!!', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'ULqR69RC_qQ', 'Bleed the cooling system of the Mercedes Benz W114 (M110) - /8 engine is getting too hot!!! #Mercedes Benz', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'ULqR69RC_qQ', 'Bleed the cooling system of the Mercedes Benz W114 (M110) - /8 engine is getting too hot!!! #Mercedes Benz', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'ULqR69RC_qQ', 'Bleed the cooling system of the Mercedes Benz W114 (M110) - /8 engine is getting too hot!!! #Mercedes Benz', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'YZ4Zx6SPlMU', 'Bosch K-Jetronic Performance: Why Change Fuel Injectors? New DIY Kits Available Now', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'YZ4Zx6SPlMU', 'Bosch K-Jetronic Performance: Why Change Fuel Injectors? New DIY Kits Available Now', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'AqKHZuYNjTY', 'Bosch KE-JETRONIC - Changing the baffle pot - Mercedes R107, W126, W201, W124', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'AqKHZuYNjTY', 'Bosch KE-JETRONIC - Changing the baffle pot - Mercedes R107, W126, W201, W124', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'tTfTmO34gsE', 'Bosch KE-JETRONIC - Changing the pressure plate potentiometer - Mercedes R107, W126, W201, W124', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'tTfTmO34gsE', 'Bosch KE-JETRONIC - Changing the pressure plate potentiometer - Mercedes R107, W126, W201, W124', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'tTfTmO34gsE', 'Bosch KE-JETRONIC - Changing the pressure plate potentiometer - Mercedes R107, W126, W201, W124', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'tTfTmO34gsE', 'Bosch KE-JETRONIC - Changing the pressure plate potentiometer - Mercedes R107, W126, W201, W124', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'tTfTmO34gsE', 'Bosch KE-JETRONIC - Changing the pressure plate potentiometer - Mercedes R107, W126, W201, W124', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'tTfTmO34gsE', 'Bosch KE-JETRONIC - Changing the pressure plate potentiometer - Mercedes R107, W126, W201, W124', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'tTfTmO34gsE', 'Bosch KE-JETRONIC - Changing the pressure plate potentiometer - Mercedes R107, W126, W201, W124', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', '3gFz2RA3Xs8', 'Can''t Decide Which Color LED Dash Bulb for your Old Benz? This Should Help!', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '3gFz2RA3Xs8', 'Can''t Decide Which Color LED Dash Bulb for your Old Benz? This Should Help!', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'wdgC9sYAe5k', 'Change and adjust electro-hydraulic actuator. KE-Jetronic from Bosch pressure actuator', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'wdgC9sYAe5k', 'Change and adjust electro-hydraulic actuator. KE-Jetronic from Bosch pressure actuator', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'wdgC9sYAe5k', 'Change and adjust electro-hydraulic actuator. KE-Jetronic from Bosch pressure actuator', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'wdgC9sYAe5k', 'Change and adjust electro-hydraulic actuator. KE-Jetronic from Bosch pressure actuator', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'BqAjKxtFy40', 'Change front shock absorber - Mercedes R107', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'BqAjKxtFy40', 'Change front shock absorber - Mercedes R107', 'Zawieszenie Przód', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'BqAjKxtFy40', 'Change front shock absorber - Mercedes R107', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'IwnHSWJeFH4', 'Change the front rubber bearing of the rear axle - Mercedes R107, W114, W115 W116, W123', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'IwnHSWJeFH4', 'Change the front rubber bearing of the rear axle - Mercedes R107, W114, W115 W116, W123', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'IwnHSWJeFH4', 'Change the front rubber bearing of the rear axle - Mercedes R107, W114, W115 W116, W123', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'IwnHSWJeFH4', 'Change the front rubber bearing of the rear axle - Mercedes R107, W114, W115 W116, W123', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'IwnHSWJeFH4', 'Change the front rubber bearing of the rear axle - Mercedes R107, W114, W115 W116, W123', 'Zawieszenie Przód', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'IwnHSWJeFH4', 'Change the front rubber bearing of the rear axle - Mercedes R107, W114, W115 W116, W123', 'Zawieszenie Tył', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'IwnHSWJeFH4', 'Change the front rubber bearing of the rear axle - Mercedes R107, W114, W115 W116, W123', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'IwnHSWJeFH4', 'Change the front rubber bearing of the rear axle - Mercedes R107, W114, W115 W116, W123', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'IwnHSWJeFH4', 'Change the front rubber bearing of the rear axle - Mercedes R107, W114, W115 W116, W123', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'IwnHSWJeFH4', 'Change the front rubber bearing of the rear axle - Mercedes R107, W114, W115 W116, W123', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'opz_tyiCt8A', 'Changing the coolant pump - Mercedes R107 C107 on the 350 SLC - Remove the water pump', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'opz_tyiCt8A', 'Changing the coolant pump - Mercedes R107 C107 on the 350 SLC - Remove the water pump', 'Zapłon', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'opz_tyiCt8A', 'Changing the coolant pump - Mercedes R107 C107 on the 350 SLC - Remove the water pump', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'dvBGe_ZadHQ', 'Check Bosch D-Jetronic pressure sensor - Mercedes W114 with M110 engine', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'dvBGe_ZadHQ', 'Check Bosch D-Jetronic pressure sensor - Mercedes W114 with M110 engine', 'D-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'dvBGe_ZadHQ', 'Check Bosch D-Jetronic pressure sensor - Mercedes W114 with M110 engine', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'MCzw_a_oTGo', 'Check KE-Jetronic from Bosch flow divider - system pressure and lower chamber pressure-Mercedes, Porsche, BMW', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'MCzw_a_oTGo', 'Check KE-Jetronic from Bosch flow divider - system pressure and lower chamber pressure-Mercedes, Porsche, BMW', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'MCzw_a_oTGo', 'Check KE-Jetronic from Bosch flow divider - system pressure and lower chamber pressure-Mercedes, Porsche, BMW', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'IRTDMHjsfqY', 'Check Mercedes KE-Jetronic acceleration enrichment on the flow divider. W126, R107, W124, W201', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'IRTDMHjsfqY', 'Check Mercedes KE-Jetronic acceleration enrichment on the flow divider. W126, R107, W124, W201', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'viqmCn07sgI', 'Check and adjust Bosch D-Jetronic pressure regulator - TN 0280 161 001', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'viqmCn07sgI', 'Check and adjust Bosch D-Jetronic pressure regulator - TN 0280 161 001', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'viqmCn07sgI', 'Check and adjust Bosch D-Jetronic pressure regulator - TN 0280 161 001', 'D-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '-zWRAX3BkfU', 'Check and adjust KE-Jetronic accumulation slide - Mercedes Bosch W201, W124, R107, W126, R129', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'uEQjpowC7Gk', 'Check cold start valve', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'uEQjpowC7Gk', 'Check cold start valve', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'uEQjpowC7Gk', 'Check cold start valve', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '8Yop_3mSP1I', 'Check fuel pump - K-Jetronic - M110 Mercedes W126', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '8Yop_3mSP1I', 'Check fuel pump - K-Jetronic - M110 Mercedes W126', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '8Yop_3mSP1I', 'Check fuel pump - K-Jetronic - M110 Mercedes W126', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', '8Yop_3mSP1I', 'Check fuel pump - K-Jetronic - M110 Mercedes W126', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '-BNUC0dhiGI', 'Check fuel pump relay - Mercedes R107, W126, W201, W124', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '-BNUC0dhiGI', 'Check fuel pump relay - Mercedes R107, W126, W201, W124', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '-BNUC0dhiGI', 'Check fuel pump relay - Mercedes R107, W126, W201, W124', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '-BNUC0dhiGI', 'Check fuel pump relay - Mercedes R107, W126, W201, W124', 'Zapłon', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', '-BNUC0dhiGI', 'Check fuel pump relay - Mercedes R107, W126, W201, W124', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '-BNUC0dhiGI', 'Check fuel pump relay - Mercedes R107, W126, W201, W124', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', 'E4IFr4MU4Pg', 'Classic R107 SL Repair Series Part 10: How to fix a Loose Rattling Transmission Shift Lever', 'Automatyczna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'E4IFr4MU4Pg', 'Classic R107 SL Repair Series Part 10: How to fix a Loose Rattling Transmission Shift Lever', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'jkulIEJ8jjo', 'Control pressure in the flow divider Mercedes R107 W126 W123 K-Jetronic system pressure regulator', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'jkulIEJ8jjo', 'Control pressure in the flow divider Mercedes R107 W126 W123 K-Jetronic system pressure regulator', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'JZd0SMJelZ0', 'Crank no start  - what to do if your Audi, VW, classic Mercedes or Fiat won''t start. FIX', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'JZd0SMJelZ0', 'Crank no start  - what to do if your Audi, VW, classic Mercedes or Fiat won''t start. FIX', 'Zapłon', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'JZd0SMJelZ0', 'Crank no start  - what to do if your Audi, VW, classic Mercedes or Fiat won''t start. FIX', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'JZd0SMJelZ0', 'Crank no start  - what to do if your Audi, VW, classic Mercedes or Fiat won''t start. FIX', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'LPZTK02NLTU', 'Cutting open a Mercedes R107 fuel tank…and modifying a non OEM tank', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'Xmgwmx62yFs', 'D Jetronic trigger points and pulse generator - removal, repair. Symptoms of faulty and worn points.', 'D-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '_LJh7L-ivsw', 'Determine idle speed with multimeter - Mercedes R107 560SL with X test socket', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '_LJh7L-ivsw', 'Determine idle speed with multimeter - Mercedes R107 560SL with X test socket', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', '_LJh7L-ivsw', 'Determine idle speed with multimeter - Mercedes R107 560SL with X test socket', 'Manualna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '_LJh7L-ivsw', 'Determine idle speed with multimeter - Mercedes R107 560SL with X test socket', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'M3c94Jp5-xw', 'Dismantle instrument cluster and repair clock for Mercedes SL R107 last series - R107 screwdriver', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'M3c94Jp5-xw', 'Dismantle instrument cluster and repair clock for Mercedes SL R107 last series - R107 screwdriver', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'M3c94Jp5-xw', 'Dismantle instrument cluster and repair clock for Mercedes SL R107 last series - R107 screwdriver', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'M3c94Jp5-xw', 'Dismantle instrument cluster and repair clock for Mercedes SL R107 last series - R107 screwdriver', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'M3c94Jp5-xw', 'Dismantle instrument cluster and repair clock for Mercedes SL R107 last series - R107 screwdriver', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'M3c94Jp5-xw', 'Dismantle instrument cluster and repair clock for Mercedes SL R107 last series - R107 screwdriver', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'M3c94Jp5-xw', 'Dismantle instrument cluster and repair clock for Mercedes SL R107 last series - R107 screwdriver', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'M3c94Jp5-xw', 'Dismantle instrument cluster and repair clock for Mercedes SL R107 last series - R107 screwdriver', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '9E8mRsZM608', 'Dismantle windscreen and insert new windscreen', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '9E8mRsZM608', 'Dismantle windscreen and insert new windscreen', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '9E8mRsZM608', 'Dismantle windscreen and insert new windscreen', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', '9E8mRsZM608', 'Dismantle windscreen and insert new windscreen', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '9E8mRsZM608', 'Dismantle windscreen and insert new windscreen', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', '9E8mRsZM608', 'Dismantle windscreen and insert new windscreen', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '9E8mRsZM608', 'Dismantle windscreen and insert new windscreen', 'Dachy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '9E8mRsZM608', 'Dismantle windscreen and insert new windscreen', 'Blacharka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '9E8mRsZM608', 'Dismantle windscreen and insert new windscreen', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '9E8mRsZM608', 'Dismantle windscreen and insert new windscreen', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'WwLl0rUtxfQ', 'EGR - check exhaust gas recirculation on KE-Jetronic - rough engine running', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '3pPqYKtfdFY', 'Early Bosch Fuel Injectors - different types +how to remove without damaging. Part 0280150024', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'hiKasKuWDE4', 'Early Mercedes R107 carpets and rear bench seat + floor pan cross members', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'DqsyZGk-aHY', 'Engine mounts Mercedes SL R107 M117 V8 engine - removal and installation classic car restoration', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'DqsyZGk-aHY', 'Engine mounts Mercedes SL R107 M117 V8 engine - removal and installation classic car restoration', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'DqsyZGk-aHY', 'Engine mounts Mercedes SL R107 M117 V8 engine - removal and installation classic car restoration', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'DqsyZGk-aHY', 'Engine mounts Mercedes SL R107 M117 V8 engine - removal and installation classic car restoration', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'DqsyZGk-aHY', 'Engine mounts Mercedes SL R107 M117 V8 engine - removal and installation classic car restoration', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'DqsyZGk-aHY', 'Engine mounts Mercedes SL R107 M117 V8 engine - removal and installation classic car restoration', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'DqsyZGk-aHY', 'Engine mounts Mercedes SL R107 M117 V8 engine - removal and installation classic car restoration', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'DqsyZGk-aHY', 'Engine mounts Mercedes SL R107 M117 V8 engine - removal and installation classic car restoration', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'GGMQzeYgn2U', 'Error readout for Mercedes R107 with X92 clutch classic car restoration', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'GGMQzeYgn2U', 'Error readout for Mercedes R107 with X92 clutch classic car restoration', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'GGMQzeYgn2U', 'Error readout for Mercedes R107 with X92 clutch classic car restoration', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'GGMQzeYgn2U', 'Error readout for Mercedes R107 with X92 clutch classic car restoration', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'GGMQzeYgn2U', 'Error readout for Mercedes R107 with X92 clutch classic car restoration', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', 'GGMQzeYgn2U', 'Error readout for Mercedes R107 with X92 clutch classic car restoration', 'Manualna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'GGMQzeYgn2U', 'Error readout for Mercedes R107 with X92 clutch classic car restoration', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'GGMQzeYgn2U', 'Error readout for Mercedes R107 with X92 clutch classic car restoration', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'GGMQzeYgn2U', 'Error readout for Mercedes R107 with X92 clutch classic car restoration', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'GGMQzeYgn2U', 'Error readout for Mercedes R107 with X92 clutch classic car restoration', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'sFHLTdajV4g', 'Gathering of Mercedes SL Convertibles Representing 48 years of Production: A Big Generation Gap.', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'ytTsQ6CPtTw', 'Hirschmann automatic antenna repair - Structure of an electrical antenna', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'ytTsQ6CPtTw', 'Hirschmann automatic antenna repair - Structure of an electrical antenna', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'ytTsQ6CPtTw', 'Hirschmann automatic antenna repair - Structure of an electrical antenna', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'ytTsQ6CPtTw', 'Hirschmann automatic antenna repair - Structure of an electrical antenna', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'ytTsQ6CPtTw', 'Hirschmann automatic antenna repair - Structure of an electrical antenna', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'ytTsQ6CPtTw', 'Hirschmann automatic antenna repair - Structure of an electrical antenna', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'ytTsQ6CPtTw', 'Hirschmann automatic antenna repair - Structure of an electrical antenna', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'ytTsQ6CPtTw', 'Hirschmann automatic antenna repair - Structure of an electrical antenna', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'Ta0AO9jDWk8', 'How to Avoid and Repair Damaged Spark Plug Threads', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'Ta0AO9jDWk8', 'How to Avoid and Repair Damaged Spark Plug Threads', 'Zapłon', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'z9SFrbiy-7M', 'How to Remove the 1974 to 1989 Mercedes R107 Fuel Tank Screen with Kent''s Special Tool', 'Ogólne', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'Rk9jer8UAkw', 'How to Replace a 380SL Thermostat and Short Coolant Hose', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'Rk9jer8UAkw', 'How to Replace a 380SL Thermostat and Short Coolant Hose', 'Chłodzenie', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'JILMQc7GHas', 'How to bench bleed (and disassemble) an ATE brake master cylinder. Mercedes R107 280SL.', 'Hydraulika i ABS', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'JILMQc7GHas', 'How to bench bleed (and disassemble) an ATE brake master cylinder. Mercedes R107 280SL.', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '--8WUYjuOCU', 'How to disassemble and repair the Auxiliary Air Slide valve on a classic Mercedes, Porsche & BMW etc', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', '--8WUYjuOCU', 'How to disassemble and repair the Auxiliary Air Slide valve on a classic Mercedes, Porsche & BMW etc', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '--8WUYjuOCU', 'How to disassemble and repair the Auxiliary Air Slide valve on a classic Mercedes, Porsche & BMW etc', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '9BgOQa50Zes', 'How to remove D Jetronic fuel-injectors and flow test Mercedes M110 engine', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'Ezmmbm7QYzc', 'How to remove a REALLY stuck brake piston when it is rusted and siezed in the caliper.', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'Ezmmbm7QYzc', 'How to remove a REALLY stuck brake piston when it is rusted and siezed in the caliper.', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'Ezmmbm7QYzc', 'How to remove a REALLY stuck brake piston when it is rusted and siezed in the caliper.', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'hCaCt00HlTA', 'How to remove the soft top hood on a R107 Mercedes SL. Detailed guide prior to fitting a new one.', 'Dachy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'R3F7qIHRRp4', 'How to test fuel injectors and trigger points using homemade NOID lights.', 'D-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', '7qIvciCFsoY', 'Ice blasting - car cleaning with dry ice on a 300SL', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', '8ER1F464Tgo', 'Indicator combination switch on the Mercedes R107 560SL - expansion and function', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', '8ER1F464Tgo', 'Indicator combination switch on the Mercedes R107 560SL - expansion and function', 'Oświetlenie i antena', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', '8ER1F464Tgo', 'Indicator combination switch on the Mercedes R107 560SL - expansion and function', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', '8ER1F464Tgo', 'Indicator combination switch on the Mercedes R107 560SL - expansion and function', 'Układ kierowniczy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', '8ER1F464Tgo', 'Indicator combination switch on the Mercedes R107 560SL - expansion and function', 'Uszczelki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'q5MB83SI8nM', 'Installing the exhaust manifold on the Mercedes M117 V8 engine', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'TCtYfPOymXo', 'Interior Carpet InstallationMercedes R107 SL', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'TCtYfPOymXo', 'Interior Carpet InstallationMercedes R107 SL', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'TCtYfPOymXo', 'Interior Carpet InstallationMercedes R107 SL', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'TCtYfPOymXo', 'Interior Carpet InstallationMercedes R107 SL', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'TCtYfPOymXo', 'Interior Carpet InstallationMercedes R107 SL', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'TCtYfPOymXo', 'Interior Carpet InstallationMercedes R107 SL', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'TCtYfPOymXo', 'Interior Carpet InstallationMercedes R107 SL', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', '3d8gqtNlzOo', 'K-JETRONIC basic setting of the STORAGE DISC', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '3d8gqtNlzOo', 'K-JETRONIC basic setting of the STORAGE DISC', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', '3d8gqtNlzOo', 'K-JETRONIC basic setting of the STORAGE DISC', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'IzbzVvLqLBQ', 'K-Jetronic warm-up regulator - Mercedes VW Audi - Revising a warm-up regulator Mercedes Restoration', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'IzbzVvLqLBQ', 'K-Jetronic warm-up regulator - Mercedes VW Audi - Revising a warm-up regulator Mercedes Restoration', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'IzbzVvLqLBQ', 'K-Jetronic warm-up regulator - Mercedes VW Audi - Revising a warm-up regulator Mercedes Restoration', 'Przekaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('kokpit', 'IzbzVvLqLBQ', 'K-Jetronic warm-up regulator - Mercedes VW Audi - Revising a warm-up regulator Mercedes Restoration', 'Wskaźniki', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'IzbzVvLqLBQ', 'K-Jetronic warm-up regulator - Mercedes VW Audi - Revising a warm-up regulator Mercedes Restoration', 'Hamulce Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'IzbzVvLqLBQ', 'K-Jetronic warm-up regulator - Mercedes VW Audi - Revising a warm-up regulator Mercedes Restoration', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'IzbzVvLqLBQ', 'K-Jetronic warm-up regulator - Mercedes VW Audi - Revising a warm-up regulator Mercedes Restoration', 'Wnętrze', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('serwis', 'IzbzVvLqLBQ', 'K-Jetronic warm-up regulator - Mercedes VW Audi - Revising a warm-up regulator Mercedes Restoration', 'Detailing', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', 'IzbzVvLqLBQ', 'K-Jetronic warm-up regulator - Mercedes VW Audi - Revising a warm-up regulator Mercedes Restoration', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'jhL6-v2irjc', 'K-Jetronic, KA-Jetronic warm-up regulator check control pressure, Mercedes #W116, #W126, #W123, #R107, #W460', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', 'jhL6-v2irjc', 'K-Jetronic, KA-Jetronic warm-up regulator check control pressure, Mercedes #W116, #W126, #W123, #R107, #W460', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', '_CzTF9w7iOM', 'K-Jetronic, warm-up regulator check control pressure, Mercedes #W116, #W126, #W123, #R107', 'K/KE-Jetronic', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('podzespoly', '_CzTF9w7iOM', 'K-Jetronic, warm-up regulator check control pressure, Mercedes #W116, #W126, #W123, #R107', 'Klimatyzacja', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'BnWtM7NAhQM', 'KE-JETRONIC Pressure accumulator replacement for warm start problems Mercedes R107, W124, W201, W126', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'BnWtM7NAhQM', 'KE-JETRONIC Pressure accumulator replacement for warm start problems Mercedes R107, W124, W201, W126', 'K/KE-Jetronic', 0);

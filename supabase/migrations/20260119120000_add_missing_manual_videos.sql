-- Manually add missing videos for Lusterka and Radio that were previously hardcoded

-- Lusterka (Mirrors)
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('lusterka', '2eI_oAstiWA', 'Naprawa lusterek bocznych R107', 'Lusterka', 10);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('lusterka', '4qqCftr_kzg', 'Demontaż i montaż lusterek', 'Lusterka', 20);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('lusterka', 'La_6nCFNiuc', 'Lusterka R107 - regulacja', 'Lusterka', 30);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('lusterka', '1ZqN9TpU810', 'Lusterka R107 - renowacja', 'Lusterka', 40);

-- Radio & Antena (Missing Manual Entries)
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'L_rMTrwDcis', 'Antena R107 - naprawa', 'Antena', 10);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'H93IUJlB5R0', 'Antena R107 - demontaż', 'Antena', 20);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', '-jG0uz1fA_g', 'Antena R107 - montaż', 'Antena', 30);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', '4sEIf49E0KU', 'Głośniki R107 - wymiana', 'Głośniki', 40);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('radio', 'DABVqcgAEOI', 'Radio Becker - serwis', 'Radio', 50);

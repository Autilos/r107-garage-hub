-- Clean everything and test with just 10 records

TRUNCATE public.repair_videos;

-- Insert 10 test videos from different categories
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('ogolne', '8-nnjT62soE', 'Test Ogolne 1', 'Poradnik zakupowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('naped', 'q-54H4-0eQs', 'Test Naped 1', 'Układ napędowy', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('skrzynia-biegow', 'E4IFr4MU4Pg', 'Test Skrzynia 1', 'Automatyczna', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('silnik', 'abc123', 'Test Silnik 1', 'Mechanika', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('hamulce', 'def456', 'Test Hamulce 1', 'Hamulce', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('elektryka', 'ghi789', 'Test Elektryka 1', 'Elektryka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('nadwozie', 'jkl012', 'Test Nadwozie 1', 'Karoseria', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('wnetrze', 'mno345', 'Test Wnetrze 1', 'Tapicerka', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('zawieszenie', 'pqr678', 'Test Zawieszenie 1', 'Amortyzatory', 0);
INSERT INTO public.repair_videos (category_slug, video_id, title, subcategory, sort_order) VALUES ('uklad-paliwowy', 'stu901', 'Test Uklad Paliwowy 1', 'Paliwowy', 0);

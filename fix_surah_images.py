# The user wants to fix the Surah image paths.
# Currently, the Surah IDs in the database start at 2 (الفاتحة) and go up.
# However, the images `quran_surah_names_X.png` range from 1 to 114, where 1 is الفاتحة.
# So `image_id` = `surah_id - 1`.

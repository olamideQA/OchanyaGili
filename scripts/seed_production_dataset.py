"""
Loop 16: Fast Controlled Seed Dataset Generator for Ochanya Gili Atelier
Optimized with batch multi-row SQL queries to complete in seconds.
"""

import urllib.request
import json
import sys

import os

sys.stdout.reconfigure(encoding='utf-8')

MGMT_URL = 'https://api.supabase.com/v1/projects/gfobzdetjbqwrxnutrkj/database/query'
MGMT_TOKEN = os.environ.get('SUPABASE_MGMT_TOKEN', '')

def run_sql(sql):
    headers = {
        'Authorization': f'Bearer {MGMT_TOKEN}',
        'Content-Type': 'application/json'
    }
    body = json.dumps({'query': sql}).encode()
    req = urllib.request.Request(MGMT_URL, data=body, headers=headers, method='POST')
    try:
        resp = urllib.request.urlopen(req)
        return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        err = e.read().decode()
        print(f"SQL Error: {err}")
        raise Exception(f"SQL Error: {err}")

print("=== STARTING FAST SEED GENERATOR ===")

# 1. Fetch user IDs
profiles = run_sql("SELECT id, email, role FROM public.profiles")
user_ids = {p['email']: p['id'] for p in profiles}

admin_id = user_ids['ochanya.admin.test@gmail.com']
designer_id = user_ids['ochanya.designer.test@gmail.com']
client_a_id = user_ids['ochanya.client.test@gmail.com']
client_b_id = user_ids['ochanya.client.b@gmail.com']
print(f"Loaded {len(user_ids)} profiles.")

# 2. Fetch Category and Collection IDs
categories = run_sql("SELECT id, slug FROM public.categories")
cat_ids = {c['slug']: c['id'] for c in categories}

collections = run_sql("SELECT id, slug FROM public.collections")
col_ids = {c['slug']: c['id'] for c in collections}

print(f"Loaded {len(cat_ids)} categories and {len(col_ids)} collections.")

# 3. 22 Products definition
products_data = [
    # 1. Evening Wear
    ('Sovereign Peplum Evening Gown', 'sovereign-peplum-evening-gown',
     'Architectural peplum gown in heavyweight duchess satin with structured shoulders.',
     'An icon of modern African couture. Featuring our signature flared peplum, hand-finished French seams, and an internal corset for sculpting elegance.',
     'made_to_order', 'evening-wear', 'the-sovereign-peplum', 385000, 420000,
     'Heavyweight Duchess Satin with Silk Habotai lining', 'Specialist dry clean only',
     14, '14 - 18 Days Atelier Handcrafting', True, 1,
     '["shoulder", "bust", "under_bust", "waist", "hip", "front_length", "dress_length"]',
     'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=1200&auto=format&fit=crop&q=80'),

    ('Idoma Ochanya Striped Mermaid Gown', 'idoma-ochanya-striped-mermaid-gown',
     'Floor-length mermaid gown woven in authentic red-and-black Idoma ceremonial cloth.',
     'Handwoven over three weeks on traditional wooden looms in Otukpo. Structured with horsehair braid hem for dramatic red carpet movement.',
     'made_to_order', 'evening-wear', 'idoma-heritage-grace', 495000, None,
     '100% Traditional Handwoven Idoma Cloth with Silk Satin lining', 'Dry clean by couture specialist',
     21, '21 Days Loom Weaving & Tailoring', True, 2,
     '["shoulder", "bust", "waist", "hip", "front_length", "dress_length"]',
     'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=1200&auto=format&fit=crop&q=80'),

    ('Lagos Midnight Velvet Column Gown', 'lagos-midnight-velvet-column-gown',
     'Sculpted column gown crafted from imported French silk velvet with gold bead shoulder fringe.',
     'Sleek and devastatingly elegant. The deep side slit reveals a flash of gold silk lining, complemented by hand-strung Japanese glass beads at the shoulder.',
     'ready_to_wear', 'evening-wear', 'lagos-noir', 275000, 310000,
     'French Silk Velvet with 100% Pure Silk Charmeuse lining', 'Specialist dry clean only',
     3, '3 - 5 Days Expedited Delivery', True, 3,
     '[]',
     'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=1200&auto=format&fit=crop&q=80'),

    ('Savanna Sunset Organza Cape Gown', 'savanna-sunset-organza-cape-gown',
     'Tiered saffron organza gown featuring a flowing detachable cathedral cape.',
     'Inspired by golden-hour horizons across the Jos Plateau. Over twenty yards of whisper-weight silk organza move dynamically with every step.',
     'made_to_order', 'evening-wear', 'savanna-sunset', 420000, None,
     'Silk Organza and Chiffon with Micro-pleated godets', 'Gentle dry clean only',
     14, '14 - 18 Days Atelier Delivery', True, 4,
     '["shoulder", "bust", "waist", "hip", "dress_length"]',
     'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=1200&auto=format&fit=crop&q=80'),

    ('Imperial Gold Brocade Evening Coat', 'imperial-gold-brocade-evening-coat',
     'Full-length evening coat woven with metallic gold thread and lined in midnight velvet.',
     'Wear open over silk trousers or belted as a formal evening coat. Features antique brass crest buttons and deep structured pockets.',
     'ready_to_wear', 'evening-wear', 'lagos-noir', 310000, None,
     'Metallic Jacquard Brocade with Velvet collar', 'Dry clean only',
     3, '3 - 5 Days Expedited Delivery', False, 5,
     '[]',
     'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=1200&auto=format&fit=crop&q=80'),

    # 2. Bridal & Ceremonial
    ('Monarch Pearl Embroidered Bridal Gown', 'monarch-pearl-bridal-gown',
     'Grand ballroom bridal gown embellished with 12,000 freshwater pearls and Swarovski elements.',
     'The pinnacle of the Ochanya Gili bridal atelier. Features an illusion neckline, hand-beaded chantilly lace bodice, and dramatic three-meter royal train.',
     'custom', 'bridal-ceremonial', 'monarch-bridal', 1850000, 2100000,
     'Chantilly Lace, French Tulle, Freshwater Pearls, Duchess Satin', 'Atelier preservation clean only',
     45, '45 - 60 Days Bespoke Craftsmanship & Private Fittings', True, 6,
     '["shoulder", "bust", "under_bust", "waist", "hip", "armhole", "sleeve_length", "back_length", "front_length", "dress_length"]',
     'https://images.unsplash.com/photo-1519741497674-611481863552?w=1200&auto=format&fit=crop&q=80'),

    ('Bespoke Royal Ceremonial Ensemble', 'bespoke-royal-ceremonial-ensemble',
     'Complete traditional three-piece coronation regalia with gold bullion embroidery.',
     'Includes handwoven metallic Aso Oke ipele, gele, and intricately beaded buba and iro ensemble tailored for royalty.',
     'custom', 'bridal-ceremonial', 'idoma-heritage-grace', 1250000, None,
     'Gold Bullion Thread, Handwoven Metallic Aso Oke, Coral Accents', 'Atelier storage preservation',
     30, '30 - 40 Days Custom Royal Weaving', True, 7,
     '["shoulder", "bust", "under_bust", "waist", "hip", "armhole", "sleeve_length", "bicep", "wrist", "back_length", "front_length", "dress_length", "trouser_waist", "trouser_hip", "trouser_length", "inseam", "thigh", "neck"]',
     'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=1200&auto=format&fit=crop&q=80'),

    ('Ivory Mikado Cathedral Wedding Dress', 'ivory-mikado-cathedral-dress',
     'Minimalist couture wedding dress in sculptural Italian silk Mikado with architectural back bow.',
     'Pure form, flawless silhouette. Featuring a dramatic off-the-shoulder fold, hidden pockets, and covered silk buttons cascading to the train tip.',
     'made_to_order', 'bridal-ceremonial', 'monarch-bridal', 850000, None,
     'Italian Silk Mikado with Silk Taffeta underskirt', 'Specialist dry clean only',
     28, '28 Days Atelier Construction', False, 8,
     '["shoulder", "bust", "waist", "hip", "front_length", "dress_length"]',
     'https://images.unsplash.com/photo-1522673607200-164d1b6ce486?w=1200&auto=format&fit=crop&q=80'),

    ('Crimson Coral Traditional Bridal Robe', 'crimson-coral-traditional-bridal-robe',
     'Heavily encrusted velvet bridal robe with authentic Benin and Niger-Delta coral beading.',
     'Worn during the traditional ceremony entrance. Weighs five kilograms with handset glass beads and semi-precious carnelian stones.',
     'custom', 'bridal-ceremonial', 'idoma-heritage-grace', 950000, None,
     'Heavy Velvet, Glass Coral Beads, Silk Lining', 'Specialist couture preservation',
     30, '30 - 45 Days Hand Beading', False, 9,
     '["shoulder", "bust", "waist", "hip", "sleeve_length", "dress_length"]',
     'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=1200&auto=format&fit=crop&q=80'),

    # 3. Tailored Suiting
    ('High-Waisted Silk Crepe Cigarette Trousers', 'high-waisted-silk-crepe-cigarette-trousers',
     'Sharply tailored high-rise trousers with satin waistband and side tuxedo stripe.',
     'Precision-cut bespoke trousers engineered to lengthen the silhouette. Custom-crafted to your unique waist, hip, inseam and thigh measurements.',
     'made_to_order', 'tailored-suiting', 'the-sovereign-peplum', 145000, None,
     '100% Wool Crepe with Silk Satin trim', 'Specialist dry clean only',
     10, '10 - 14 Days Atelier Craftsmanship', True, 10,
     '["trouser_waist", "trouser_hip", "trouser_length", "inseam", "thigh"]',
     'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=1200&auto=format&fit=crop&q=80'),

    ('Sovereign Double-Breasted Peplum Blazer', 'sovereign-double-breasted-peplum-blazer',
     'Sculptural wool crepe blazer with structured shoulders, horn buttons, and dramatic peplum flare.',
     'The definitive power silhouette. Hand-canvassed construction with padded shoulders and a nipped-in waist that flares over the hips.',
     'made_to_order', 'tailored-suiting', 'the-sovereign-peplum', 245000, 275000,
     'British Wool Crepe with Silk Jacquard lining', 'Specialist dry clean only',
     12, '12 - 16 Days Tailoring', True, 11,
     '["shoulder", "bust", "waist", "armhole", "sleeve_length", "bicep"]',
     'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=1200&auto=format&fit=crop&q=80'),

    ('Midnight Tuxedo Suit with Gold Lapels', 'midnight-tuxedo-suit-gold-lapels',
     'Two-piece women\'s tuxedo featuring hand-woven gold Aso Oke peak lapels and slim trousers.',
     'A bold reinterpretation of Black Tie. The trousers feature a satin side stripe while the single-button jacket commands the room.',
     'made_to_order', 'tailored-suiting', 'lagos-noir', 360000, None,
     'Super 150s Merino Wool with Handwoven Gold Aso Oke lapels', 'Dry clean only',
     14, '14 - 18 Days Master Tailoring', False, 12,
     '["shoulder", "bust", "waist", "hip", "sleeve_length", "trouser_waist", "trouser_hip", "inseam"]',
     'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=1200&auto=format&fit=crop&q=80'),

    ('Terracotta Silk Trench Suit', 'terracotta-silk-trench-suit',
     'Two-piece relaxed suit in washed raw silk with belted kimono jacket and wide-leg palazzo pants.',
     'Effortless luxury for tropical evenings. The heavy sandwashed silk drapes fluidly with storm flaps and horn buckle details.',
     'ready_to_wear', 'tailored-suiting', 'savanna-sunset', 295000, None,
     '100% Sandwashed Raw Silk', 'Gentle hand wash cold or dry clean',
     3, '3 - 5 Days Expedited Delivery', False, 13,
     '[]',
     'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=1200&auto=format&fit=crop&q=80'),

    # 4. Ready-to-Wear Luxury
    ('Asymmetrical Silk Charmeuse Midi Dress', 'asymmetrical-silk-charmeuse-midi-dress',
     'Liquid drape midi dress cut on the bias in emerald green silk charmeuse with draped cowl neckline.',
     'Cut on the true bias for a figure-skimming fit that flatters every curve. Features delicate spaghetti straps and a cascading handkerchief hemline.',
     'ready_to_wear', 'ready-to-wear-luxury', 'savanna-sunset', 185000, 210000,
     '100% Silk Charmeuse', 'Specialist dry clean only',
     3, '3 - 5 Days Expedited Delivery', True, 14,
     '[]',
     'https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?w=1200&auto=format&fit=crop&q=80'),

    ('Embroidered Organza Kimono Robe', 'embroidered-organza-kimono-robe',
     'Floor-skimming sheer black organza duster with hand-embroidered African flora motifs.',
     'Wear layered over swimwear at private resorts or over silk slip dresses for evening gala cocktails.',
     'ready_to_wear', 'ready-to-wear-luxury', 'lagos-noir', 165000, None,
     'Silk Organza with Viscose embroidery thread', 'Gentle dry clean only',
     3, '3 - 5 Days Expedited Delivery', False, 15,
     '[]',
     'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=1200&auto=format&fit=crop&q=80'),

    ('Pleated Sunburst Midi Skirt', 'pleated-sunburst-midi-skirt',
     'Accordion pleated skirt in molten metallic bronze with an elasticated grosgrain waistband.',
     'Engineered permanent sunburst pleats provide maximum fullness without bulk at the waist. Swirls dramatically in motion.',
     'ready_to_wear', 'ready-to-wear-luxury', 'savanna-sunset', 125000, None,
     'Metallic Poly-Silk Lamé', 'Spot clean or gentle dry clean',
     3, '3 - 5 Days Expedited Delivery', False, 16,
     '[]',
     'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=1200&auto=format&fit=crop&q=80'),

    ('Couture Corset Belt in Handwoven Aso Oke', 'couture-corset-belt-aso-oke',
     'Wide structured corset belt with steel boning, leather buckle closures, and handwoven tribal textiles.',
     'The quintessential layering statement. Elevate oversized white shirts, flowing gowns, or tailored blazers.',
     'ready_to_wear', 'ready-to-wear-luxury', 'idoma-heritage-grace', 85000, 95000,
     'Handwoven Cotton-Metallic Aso Oke with Vegetable-tanned Leather', 'Wipe clean with soft damp cloth',
     3, '3 - 5 Days Expedited Delivery', True, 17,
     '[]',
     'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=1200&auto=format&fit=crop&q=80'),

    ('Silk Chiffon Halter Maxi Dress', 'silk-chiffon-halter-maxi-dress',
     'Sunburst yellow tiered maxi dress featuring neck tie scarf and low open back.',
     'Weightless summer glamour. Designed for tropical galas, destination weddings, and coastal retreats.',
     'ready_to_wear', 'ready-to-wear-luxury', 'savanna-sunset', 195000, None,
     'Pure Silk Chiffon with Silk Georgette lining', 'Specialist dry clean',
     3, '3 - 5 Days Expedited Delivery', False, 18,
     '[]',
     'https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?w=1200&auto=format&fit=crop&q=80'),

    ('One-Shoulder Draped Crepe Jumpsuit', 'one-shoulder-draped-crepe-jumpsuit',
     'Architectural black jumpsuit with asymmetrical drape scarf and wide pleated palazzo leg.',
     'Modern alternative to the evening gown. Includes internal bustier support and deep side pockets.',
     'made_to_order', 'tailored-suiting', 'lagos-noir', 265000, None,
     'Heavy Wool Crepe with Silk Habotai lining', 'Specialist dry clean only',
     10, '10 - 14 Days Atelier Delivery', False, 19,
     '["shoulder", "bust", "waist", "hip", "trouser_waist", "trouser_hip", "inseam"]',
     'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=1200&auto=format&fit=crop&q=80'),

    ('Tiered Tulle Ballerina Midi Gown', 'tiered-tulle-ballerina-midi-gown',
     'Romantic blush midi dress with boned sweetheart bodice and twenty layers of French tulle.',
     'Whimsical atelier couture. Hand-gathered tulle layers create cloud-like volume for festive celebrations.',
     'ready_to_wear', 'evening-wear', 'monarch-bridal', 230000, None,
     'French Polyamide Tulle with Duchess Satin corset', 'Specialist dry clean only',
     3, '3 - 5 Days Expedited Delivery', False, 20,
     '[]',
     'https://images.unsplash.com/photo-1519741497674-611481863552?w=1200&auto=format&fit=crop&q=80'),

    ('Idoma Striped Peplum Cocktail Jacket', 'idoma-striped-peplum-cocktail-jacket',
     'Cropped structured peplum jacket in black and carmine red heritage weave with mandarin collar.',
     'Wear as a cocktail piece with slim trousers or over a pencil dress. Features hidden snap closures.',
     'made_to_order', 'evening-wear', 'idoma-heritage-grace', 215000, None,
     'Authentic Idoma Handwoven Textile with Silk Twill lining', 'Dry clean only',
     12, '12 - 16 Days Weaving & Tailoring', True, 21,
     '["shoulder", "bust", "waist", "sleeve_length"]',
     'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=1200&auto=format&fit=crop&q=80'),

    ('Sculpted Duchess Satin Wrap Bolero', 'sculpted-duchess-satin-wrap-bolero',
     'Folded architectural wrap bolero in champagne gold duchess satin with dramatic wing collar.',
     'The ultimate evening layer for sleeveless couture gowns. Tailored with interfacing for crisp shape retention.',
     'ready_to_wear', 'ready-to-wear-luxury', 'the-sovereign-peplum', 115000, None,
     'Italian Duchess Satin', 'Specialist dry clean only',
     3, '3 - 5 Days Expedited Delivery', False, 22,
     '[]',
     'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=1200&auto=format&fit=crop&q=80')
]

print("\n--- Inserting Products in Batch ---")
p_rows = []
for p in products_data:
    name, slug, s_desc, desc, p_type, cat_slug, col_slug, b_p, c_p, mat, care, p_days, del_est, is_feat, s_ord, req_m, img = p
    cat_id = cat_ids[cat_slug]
    cp_val = f"{c_p}" if c_p else "NULL"
    # escape single quotes
    name_esc = name.replace("'", "''")
    s_desc_esc = s_desc.replace("'", "''")
    desc_esc = desc.replace("'", "''")
    mat_esc = mat.replace("'", "''")
    care_esc = care.replace("'", "''")
    del_esc = del_est.replace("'", "''")
    
    p_rows.append(f"""(
        '{name_esc}', '{slug}', '{s_desc_esc}', '{desc_esc}', '{p_type}',
        '{cat_id}', {b_p}, {cp_val}, '{mat_esc}', '{care_esc}',
        {p_days}, '{del_esc}', {str(is_feat).lower()}, true, {s_ord}, '{req_m}'::jsonb
    )""")

p_sql = f"""
    INSERT INTO public.products (
        name, slug, short_description, description, product_type,
        category_id, base_price, compare_at_price, materials, care_instructions,
        production_time_days, delivery_estimate, is_featured, is_published,
        sort_order, required_measurements
    ) VALUES {', '.join(p_rows)}
    ON CONFLICT (slug) DO UPDATE SET
        name = EXCLUDED.name,
        base_price = EXCLUDED.base_price,
        compare_at_price = EXCLUDED.compare_at_price,
        product_type = EXCLUDED.product_type,
        required_measurements = EXCLUDED.required_measurements,
        is_published = true;
"""
run_sql(p_sql)
print("  Products inserted successfully.")

# Fetch all product IDs
all_prods = run_sql("SELECT id, slug, product_type FROM public.products")
p_map = {p['slug']: p['id'] for p in all_prods}
ptype_map = {p['slug']: p['product_type'] for p in all_prods}

# 4. Batch Insert Collection Mappings, Images & Variants
print("\n--- Inserting Collection Products, Images, and Variants in Batch ---")
col_rows = []
img_rows = []
var_rows = []

sizes = ['UK 8 / XS', 'UK 10 / S', 'UK 12 / M', 'UK 14 / L', 'UK 16 / XL']

for p in products_data:
    slug = p[1]
    col_slug = p[6]
    img_url = p[16]
    name = p[0].replace("'", "''")
    p_type = p[4]
    
    pid = p_map.get(slug)
    if not pid:
        continue
    cid = col_ids[col_slug]
    
    col_rows.append(f"('{cid}', '{pid}', {p[14]})")
    img_rows.append(f"('{pid}', '{img_url}', '{name} Atelier View', true, 1)")
    
    for idx, s in enumerate(sizes):
        sku = f"OG-{slug[:6].upper()}-{s[:4].replace(' ', '')}"
        stock = 5 if p_type == 'ready_to_wear' else 25
        var_rows.append(f"('{pid}', '{s}', 'Atelier Original', '{sku}', {stock}, true, {idx + 1})")

# Batch run mappings
run_sql(f"INSERT INTO public.collection_products (collection_id, product_id, sort_order) VALUES {', '.join(col_rows)} ON CONFLICT DO NOTHING;")

# Batch insert images and variants with ON CONFLICT DO NOTHING
run_sql(f"INSERT INTO public.product_images (product_id, image_url, alt_text, is_primary, sort_order) VALUES {', '.join(img_rows)} ON CONFLICT DO NOTHING;")
run_sql(f"INSERT INTO public.product_variants (product_id, size, colour, sku, stock_quantity, is_available, sort_order) VALUES {', '.join(var_rows)} ON CONFLICT DO NOTHING;")
print("  Collection mappings, images, and variants inserted successfully.")

# 5. Batch Measurement Profiles
print("\n--- Inserting Measurement Profiles in Batch ---")
measurements_data = [
    (client_a_id, 'Ochanya Formal Gala Profile', 15.5, 36.0, 31.0, 28.5, 39.5, 17.0, 24.0, 11.5, 6.5, 16.0, 15.0, 60.0, 29.0, 40.0, 42.0, 31.0, 22.0, 14.0),
    (client_b_id, 'Beverly Red Carpet Measurements', 16.0, 38.0, 33.0, 30.0, 42.0, 18.0, 24.5, 12.5, 7.0, 16.5, 15.5, 62.0, 31.0, 43.0, 43.5, 32.0, 23.5, 14.5),
    (user_ids['ochanya.client.amina@gmail.com'], 'Amina Ceremonial Profile', 15.0, 34.5, 29.5, 27.0, 38.0, 16.5, 23.5, 11.0, 6.0, 15.5, 14.5, 59.0, 27.5, 38.5, 41.0, 30.5, 21.0, 13.5),
    (user_ids['ochanya.client.chioma@gmail.com'], 'Chioma Bridal Profile', 16.5, 40.0, 35.0, 32.5, 44.5, 18.5, 25.0, 13.0, 7.0, 17.0, 16.0, 63.0, 33.0, 45.0, 44.0, 33.0, 24.0, 15.0),
    (user_ids['ochanya.client.folake@gmail.com'], 'Folake Evening Standard', 15.5, 36.5, 31.5, 29.0, 40.5, 17.0, 24.0, 12.0, 6.5, 16.0, 15.0, 61.0, 29.5, 41.0, 42.5, 31.5, 22.5, 14.0),
    (user_ids['ochanya.client.zainab@gmail.com'], 'Zainab Haute Fit', 14.5, 33.0, 28.0, 25.5, 36.5, 16.0, 23.0, 10.5, 6.0, 15.0, 14.0, 58.0, 26.0, 37.0, 40.0, 30.0, 20.5, 13.0),
    (user_ids['ochanya.client.nneka@gmail.com'], 'Dr. Nneka Executive Couture', 16.0, 37.0, 32.0, 29.5, 41.0, 17.5, 24.5, 12.0, 6.5, 16.5, 15.5, 60.5, 30.0, 42.0, 43.0, 32.0, 23.0, 14.5),
    (user_ids['ochanya.client.simi@gmail.com'], 'Simi Runway Measurements', 15.0, 34.0, 29.0, 26.5, 37.5, 16.5, 24.0, 11.0, 6.0, 15.5, 14.5, 62.0, 27.0, 38.0, 43.0, 33.0, 21.0, 13.5),
    (user_ids['ochanya.client.halima@gmail.com'], 'Hajia Halima Royal Kaftan', 17.0, 42.0, 37.0, 35.0, 46.0, 19.0, 25.5, 14.0, 7.5, 17.5, 16.5, 64.0, 36.0, 47.0, 44.5, 33.5, 25.0, 15.5),
    (user_ids['ochanya.client.tiwa@gmail.com'], 'Tiwa Stage & Gala Fit', 15.5, 35.5, 30.5, 28.0, 39.0, 17.0, 24.0, 11.5, 6.5, 16.0, 15.0, 60.0, 28.5, 39.5, 42.0, 31.0, 22.0, 14.0),
]

m_rows = []
for m in measurements_data:
    uid, m_name, sh, bu, ubu, wa, hi, arm, sl, bi, wr, bl, fl, dl, tw, th, tl, ins, thi, nk = m
    m_rows.append(f"""(
        '{uid}', '{m_name}', {sh}, {bu}, {ubu}, {wa}, {hi},
        {arm}, {sl}, {bi}, {wr}, {bl}, {fl},
        {dl}, {tw}, {th}, {tl},
        {ins}, {thi}, {nk}, 'inches', true
    )""")

run_sql(f"""
    INSERT INTO public.measurement_profiles (
        profile_id, name, shoulder, bust, under_bust, waist, hip,
        armhole, sleeve_length, bicep, wrist, back_length, front_length,
        dress_length, trouser_waist, trouser_hip, trouser_length,
        inseam, thigh, neck, unit, is_default
    ) VALUES {', '.join(m_rows)}
    ON CONFLICT DO NOTHING;
""")
print("  Measurement profiles inserted successfully.")

# Map profile_id -> measurement_profile_id
m_recs = run_sql("SELECT id, profile_id FROM public.measurement_profiles")
m_map = {m['profile_id']: m['id'] for m in m_recs}

# 6. Batch Customer Addresses
print("\n--- Inserting Addresses in Batch ---")
addresses_data = [
    (client_a_id, 'Home Villa', 'Lady Ochanya Audu', '+2348022221111', '14 Queen Amina Crescent, Maitama', 'Floor 2, Penthouse', 'Abuja', 'FCT', 'Nigeria', True),
    (client_a_id, 'Lagos Pied-a-terre', 'Lady Ochanya Audu', '+2348022221111', '8 Bourdillon Road, Ikoyi', 'Apt 4B', 'Lagos', 'Lagos State', 'Nigeria', False),
    (client_b_id, 'Duchess Estate', 'Duchess Beverly Vance', '+2348022222222', '24 Walter Carrington Crescent', 'Victoria Island', 'Lagos', 'Lagos State', 'Nigeria', True),
    (user_ids['ochanya.client.amina@gmail.com'], 'Abuja Residence', 'Amina Bello-Dikko', '+2348022223333', '10 Gana Street', 'Maitama', 'Abuja', 'FCT', 'Nigeria', True),
    (user_ids['ochanya.client.chioma@gmail.com'], 'GRA Port Harcourt', 'Chioma Nnamdi-Eze', '+2348022224444', '5 Tombia Street, GRA Phase 2', '', 'Port Harcourt', 'Rivers State', 'Nigeria', True),
    (user_ids['ochanya.client.folake@gmail.com'], 'Banana Island Villa', 'Folake Adeleke', '+2348022225555', 'Plot 12 Ocean Parade, Banana Island', '', 'Ikoyi, Lagos', 'Lagos State', 'Nigeria', True),
    (user_ids['ochanya.client.zainab@gmail.com'], 'Kano Manor', 'Zainab Al-Hassan', '+2348022226666', '18 Bompai Road', '', 'Kano', 'Kano State', 'Nigeria', True),
    (user_ids['ochanya.client.nneka@gmail.com'], 'Enugu Heights', 'Dr. Nneka Okonjo', '+2348022227777', '7 Independence Avenue', 'Independence Layout', 'Enugu', 'Enugu State', 'Nigeria', True),
    (user_ids['ochanya.client.simi@gmail.com'], 'London Residence', 'Simi Holloway-Cole', '+447911122233', '45 Kensington Palace Gardens', '', 'London', 'Greater London', 'United Kingdom', True),
    (user_ids['ochanya.client.halima@gmail.com'], 'Kaduna Estate', 'Hajia Halima Danjuma', '+2348022229999', '3 Sultan Road', '', 'Kaduna', 'Kaduna State', 'Nigeria', True),
    (user_ids['ochanya.client.tiwa@gmail.com'], 'Lekki Admiralty Penthouse', 'Tiwa Savage-Balogun', '+2348022220000', 'Plot 5 Admiralty Way', 'Lekki Phase 1', 'Lagos', 'Lagos State', 'Nigeria', True),
]

a_rows = []
for uid, label, fname, ph, a1, a2, city, state, country, is_def in addresses_data:
    a_rows.append(f"""(
        '{uid}', '{label}', '{fname}', '{ph}', '{a1}', '{a2}',
        '{city}', '{state}', '{country}', {str(is_def).lower()}
    )""")

run_sql(f"""
    INSERT INTO public.addresses (
        profile_id, label, full_name, phone, address_line1, address_line2,
        city, state, country, is_default
    ) VALUES {', '.join(a_rows)}
    ON CONFLICT DO NOTHING;
""")
print("  Addresses inserted successfully.")

# Map profile_id -> address_id
a_recs = run_sql("SELECT id, profile_id FROM public.addresses WHERE is_default = true")
a_map = {a['profile_id']: a['id'] for a in a_recs}

# 7. Batch Orders
print("\n--- Inserting 12 Orders, Items, and Status History in Batch ---")
orders_plan = [
    (client_a_id, 'OG-2026-001', 'delivered', 'successful', 385000, 15000, 400000, 25, 'Delivered to Maitama residence. Fitted impeccably.'),
    (client_a_id, 'OG-2026-002', 'in_production', 'successful', 145000, 10000, 155000, 5, 'Wool crepe cut; currently in hand-finishing.'),
    (client_b_id, 'OG-2026-003', 'shipped', 'successful', 275000, 15000, 290000, 8, 'Dispatched via DHL Luxury Courier to VI. Tracking: DHL-NG-88992.'),
    (client_b_id, 'OG-2026-004', 'ready_for_fitting', 'successful', 495000, 20000, 515000, 12, 'Loom weaving finished. Client fitting scheduled for Saturday.'),
    (user_ids['ochanya.client.amina@gmail.com'], 'OG-2026-005', 'paid', 'successful', 185000, 10000, 195000, 3, 'Payment confirmed via Paystack. Production queue position #2.'),
    (user_ids['ochanya.client.chioma@gmail.com'], 'OG-2026-006', 'pending_payment', 'pending', 850000, 25000, 875000, 1, 'Waiting for customer wire transfer verification.'),
    (user_ids['ochanya.client.folake@gmail.com'], 'OG-2026-007', 'delivered', 'successful', 360000, 15000, 375000, 40, 'Delivered to Banana Island. VIP client confirmed delight.'),
    (user_ids['ochanya.client.zainab@gmail.com'], 'OG-2026-008', 'in_production', 'successful', 245000, 15000, 260000, 6, 'Pattern drafting complete, fabric hand-cut.'),
    (user_ids['ochanya.client.nneka@gmail.com'], 'OG-2026-009', 'confirmed', 'successful', 310000, 15000, 325000, 4, 'Couturier assigned: Alache.'),
    (user_ids['ochanya.client.simi@gmail.com'], 'OG-2026-010', 'shipped', 'successful', 420000, 35000, 455000, 7, 'Air freight international delivery to Kensington London.'),
    (user_ids['ochanya.client.halima@gmail.com'], 'OG-2026-011', 'ready_for_fitting', 'successful', 1250000, 50000, 1300000, 18, 'Cathedral ensemble ready for royal private fitting.'),
    (user_ids['ochanya.client.tiwa@gmail.com'], 'OG-2026-012', 'pending_payment', 'pending', 165000, 10000, 175000, 2, 'Awaiting customer online payment completion.'),
]

o_nums = "('" + "','".join([o[1] for o in orders_plan]) + "')"
# First clean up dependent order items and status history
run_sql(f"DELETE FROM public.order_items WHERE order_id IN (SELECT id FROM public.orders WHERE order_number IN {o_nums});")
run_sql(f"DELETE FROM public.order_status_history WHERE order_id IN (SELECT id FROM public.orders WHERE order_number IN {o_nums});")
run_sql(f"DELETE FROM public.orders WHERE order_number IN {o_nums};")

o_rows = []
for uid, onum, st, pst, sub, dfee, tot, days_ago, note in orders_plan:
    aid = a_map.get(uid)
    aid_sql = f"'{aid}'" if aid else "NULL"
    o_rows.append(f"""(
        '{onum}', '{uid}', {aid_sql}, '{st}', {sub}, {dfee},
        0, {tot}, '{pst}', 'PAY-{onum}-REF', 'paystack',
        '{note}', 'Please package in signature Ochanya Gili gold ribbon box.',
        now() - interval '{days_ago} days', now() - interval '{days_ago - 1} days'
    )""")

run_sql(f"""
    INSERT INTO public.orders (
        order_number, profile_id, address_id, status, subtotal, delivery_fee,
        discount_amount, total, payment_status, payment_reference, payment_provider,
        notes, customer_notes, created_at, updated_at
    ) VALUES {', '.join(o_rows)};
""")

# Map order_number -> order_id
all_orders = run_sql(f"SELECT id, order_number, profile_id, subtotal FROM public.orders WHERE order_number IN {o_nums}")
order_map = {o['order_number']: o['id'] for o in all_orders}

oi_rows = []
osh_rows = []
prod_items = list(p_map.items())

for idx, (uid, onum, st, pst, sub, dfee, tot, days_ago, note) in enumerate(orders_plan):
    oid = order_map[onum]
    pslug, pid = prod_items[idx % len(prod_items)]
    pname = pslug.replace('-', ' ').title()
    mid = m_map.get(uid)
    mid_sql = f"'{mid}'" if mid else "NULL"
    
    oi_rows.append(f"('{oid}', '{pid}', '{pname}', 'UK 12 / M', 1, {sub}, {sub}, {mid_sql})")
    osh_rows.append(f"('{oid}', 'pending_payment', '{st}', '{admin_id}', 'Initial progression to {st}', now() - interval '{days_ago} days')")

run_sql(f"""
    INSERT INTO public.order_items (
        order_id, product_id, product_name, variant_label, quantity,
        unit_price, total_price, measurement_profile_id
    ) VALUES {', '.join(oi_rows)};
""")

run_sql(f"""
    INSERT INTO public.order_status_history (
        order_id, from_status, to_status, changed_by, notes, created_at
    ) VALUES {', '.join(osh_rows)};
""")
print("  Orders, items, and status history inserted successfully.")

# 8. Batch Custom Requests & Quotes
print("\n--- Inserting Custom Requests & Quotes in Batch ---")
custom_requests_plan = [
    (client_a_id, 'CR-2026-001', 'State Banquet Presidential Ball', 'structured_peplum',
     'Floor-length emerald duchess satin peplum ballgown with handwoven Aso Oke collar.',
     'emerald duchess satin, metallic Aso Oke', 'Deep Emerald & Gold', 'production',
     'Pattern cut, embroidery frame mounted. 40 hours completed by Danladi.'),
    
    (client_b_id, 'CR-2026-002', 'Cannes Film Festival Red Carpet', 'flowing_chiffon',
     'Liquid silver lame gown with dramatic shoulder cape flowing into train.',
     'Liquid metallic lame, silk chiffon', 'Liquid Platinum Silver', 'customer_approved',
     'Quote accepted. 50% deposit received. Material dispatch from Milan confirmed.'),

    (user_ids['ochanya.client.amina@gmail.com'], 'CR-2026-003', 'Sister Royal Wedding in Kano', 'monarch_bridal',
     'Bespoke three-piece ceremonial iro and buba with 3D crystal floral appliqués.',
     'French Chantilly lace, silk organza', 'Lilac & Silver Dust', 'quote_sent',
     'Quote v2 issued reflecting customer change to add crystal sleeves.'),

    (user_ids['ochanya.client.chioma@gmail.com'], 'CR-2026-004', 'Governor Inaugural Gala', 'sculpted_corset',
     'Asymmetric sculpted velvet corset gown with dramatic pleated sunburst hip drape.',
     'Royal purple French velvet', 'Royal Amethyst Purple', 'under_review',
     'Senior couturier reviewing fabric swatch options and structure feasibility.'),

    (user_ids['ochanya.client.folake@gmail.com'], 'CR-2026-005', '50th Golden Jubilee Celebration', 'regal_coronation',
     'Cathedral-length cape ensemble completely hand-beaded with gold bugle beads.',
     'Heavy silk faille, 24k gold bullion thread', 'Pure Imperial Gold', 'requested',
     'Intake received. Ready for designer sketch review.'),

    (user_ids['ochanya.client.tiwa@gmail.com'], 'CR-2026-006', 'World Tour Opening Night', 'modern_architectural',
     'Structural peplum jumpsuit with laser-cut metallic leather shoulder wings.',
     'Metallic calfskin, high-twist wool crepe', 'Obsidian Black & Bronze', 'delivered',
     'Garment delivered and worn on stage to acclaim.')
]

cr_nums = "('" + "','".join([c[1] for c in custom_requests_plan]) + "')"
run_sql(f"DELETE FROM public.quote_items WHERE quote_id IN (SELECT id FROM public.quotes WHERE custom_request_id IN (SELECT id FROM public.custom_requests WHERE request_number IN {cr_nums}));")
run_sql(f"DELETE FROM public.quotes WHERE custom_request_id IN (SELECT id FROM public.custom_requests WHERE request_number IN {cr_nums});")
run_sql(f"DELETE FROM public.custom_request_status_history WHERE custom_request_id IN (SELECT id FROM public.custom_requests WHERE request_number IN {cr_nums});")
run_sql(f"DELETE FROM public.custom_request_images WHERE custom_request_id IN (SELECT id FROM public.custom_requests WHERE request_number IN {cr_nums});")
run_sql(f"DELETE FROM public.custom_requests WHERE request_number IN {cr_nums};")

cr_rows = []
for uid, rnum, occ, direc, insp, fab, col, st, dnotes in custom_requests_plan:
    mid = m_map.get(uid)
    mid_sql = f"'{mid}'" if mid else "NULL"
    cr_rows.append(f"""(
        '{rnum}', '{uid}', '{occ}', '{direc}', '{insp}',
        '{fab}', '{col}', {mid_sql}, '{st}', '{designer_id}', '{dnotes}',
        now() - interval '14 days', now()
    )""")

run_sql(f"""
    INSERT INTO public.custom_requests (
        request_number, profile_id, occasion, direction, inspiration_text,
        fabric, colour, measurement_profile_id, status, assigned_to, designer_notes,
        created_at, updated_at
    ) VALUES {', '.join(cr_rows)};
""")

all_crs = run_sql(f"SELECT id, request_number, status FROM public.custom_requests WHERE request_number IN {cr_nums}")
cr_map = {c['request_number']: c['id'] for c in all_crs}

# Quotes
q_rows = []
for uid, rnum, occ, direc, insp, fab, col, st, dnotes in custom_requests_plan:
    crid = cr_map[rnum]
    if st in ['quote_sent', 'customer_approved', 'production', 'delivered']:
        q_status = 'sent' if st == 'quote_sent' else 'accepted'
        tot = 650000.00
        dep = tot * 0.5
        bal = tot - dep
        q_rows.append(f"""(
            '{crid}', 1, {tot}, {tot}, 50.00, {dep}, {bal}, '{q_status}',
            now() + interval '30 days',
            'Atelier bespoke quote including two private fittings and silk lining.',
            '{designer_id}'
        )""")

run_sql(f"""
    INSERT INTO public.quotes (
        custom_request_id, version, subtotal, total, deposit_percentage,
        deposit_amount, balance_amount, status, valid_until, notes, created_by
    ) VALUES {', '.join(q_rows)};
""")

all_qs = run_sql("SELECT id, custom_request_id FROM public.quotes")
qi_rows = []
for q in all_qs:
    qid = q['id']
    qi_rows.append(f"('{qid}', 'Bespoke Atelier Pattern Drafting & 3D Toile Fitting', 1, 150000.00, 150000.00, 1)")
    qi_rows.append(f"('{qid}', 'Master Loom Handwoven Fabric & Silk Charmeuse Sourcing', 1, 320000.00, 320000.00, 2)")
    qi_rows.append(f"('{qid}', 'Artisanal Hand-Beading & Couture Finishing (80 Hours)', 1, 180000.00, 180000.00, 3)")

run_sql(f"""
    INSERT INTO public.quote_items (quote_id, description, quantity, unit_price, total_price, sort_order)
    VALUES {', '.join(qi_rows)};
""")
print("  Custom requests, quotes, and line items inserted successfully.")

# 9. Batch Appointments
print("\n--- Inserting Appointments in Batch ---")
app_types = run_sql("SELECT id, slug FROM public.appointment_types")
app_type_map = {r['slug']: r['id'] for r in app_types}
def_at = list(app_type_map.values())[0]

appointments_data = [
    (client_a_id, 'bespoke_fitting', '2026-10-05', '14:00:00', '15:30:00', 'confirmed', True, 'Second fitting for Sovereign evening peplum gown.'),
    (client_b_id, 'vip_consultation', '2026-10-06', '11:00:00', '12:30:00', 'confirmed', True, 'Consultation for upcoming London charity gala.'),
    (user_ids['ochanya.client.amina@gmail.com'], 'virtual_consultation', '2026-10-08', '15:00:00', '16:00:00', 'confirmed', True, 'Virtual fabric review for bridal ceremony.'),
    (user_ids['ochanya.client.chioma@gmail.com'], 'vip_consultation', '2026-10-10', '10:00:00', '11:30:00', 'confirmed', True, 'Full bridal party measurement session.'),
    (user_ids['ochanya.client.folake@gmail.com'], 'bespoke_fitting', '2026-10-12', '16:00:00', '17:00:00', 'confirmed', False, 'Final fitting before overseas travel.'),
    (user_ids['ochanya.client.tiwa@gmail.com'], 'wardrobe_styling', '2026-09-20', '13:00:00', '15:00:00', 'completed', True, 'Completed wardrobe curation for album tour.')
]

run_sql("DELETE FROM public.appointments;")
app_rows = []
for uid, tslug, sdate, stime, etime, st, fee_paid, notes in appointments_data:
    tid = app_type_map.get(tslug, def_at)
    app_rows.append(f"""(
        '{uid}', '{tid}', '{sdate}', '{stime}', '{etime}',
        '{st}', {str(fee_paid).lower()}, '{notes}', 'Private salon prepared with champagne reception.'
    )""")

run_sql(f"""
    INSERT INTO public.appointments (
        profile_id, appointment_type_id, scheduled_date, start_time, end_time,
        status, booking_fee_paid, notes, designer_notes
    ) VALUES {', '.join(app_rows)};
""")
print("  Appointments inserted successfully.")

# 10. Batch Journal Posts
print("\n--- Inserting Journal Posts in Batch ---")
journal_posts = [
    ('The Architecture of African Haute Couture', 'architecture-of-african-haute-couture',
     'Exploring how structural peplums and handwoven textiles redefine modern luxury.',
     'At Ochanya Gili, luxury is not merely an aesthetic; it is an architectural dialogue between ancient craftsmanship and contemporary sculptural form. When we look at traditional Idoma weaving, we do not simply see fabric -- we observe centuries of rhythmic geometry engineered by women weavers across generations.',
     'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=1600&auto=format&fit=crop&q=80',
     True, ['Couture', 'Craftsmanship', 'Heritage']),

    ('120 Hours of Beadwork: The Making of the Sovereign Gown', '120-hours-of-beadwork-sovereign-gown',
     'Inside our Lagos atelier as master artisans hand-apply thousands of bugle beads and freshwater pearls.',
     'Every single bead on our Sovereign Peplum gown is placed by hand in our private Victoria Island atelier. Master artisan Danladi leads a team of six embroiderers working under magnification to tension each silk thread to exact micro-specifications.',
     'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=1600&auto=format&fit=crop&q=80',
     True, ['Atelier', 'Behind The Scenes', 'Embroidery']),

    ('The Royal Bride: Crafting Ceremonial Majesty', 'royal-bride-crafting-ceremonial-majesty',
     'A comprehensive guide to bespoke bridal couture, private toile fittings, and cathedral-length drama.',
     'The Ochanya Gili bridal journey is an intimate six-month collaboration. From the initial silhouette sketch with our Creative Director to the final silk hand-pressing, every detail honors both personal romance and cultural royalty.',
     'https://images.unsplash.com/photo-1519741497674-611481863552?w=1600&auto=format&fit=crop&q=80',
     True, ['Bridal', 'Bespoke', 'Weddings']),

    ('Sourcing the Savanna: Natural Pigments and Raw Silk', 'sourcing-the-savanna-natural-pigments',
     'How the warm palette of the Nigerian savanna inspires our seasonal resort collection.',
     'From deep terracotta red earth to sun-baked ochre clays, our color development process draws directly from regional botanical dyes and raw unbleached silks, celebrating the organic power of West African nature.',
     'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=1600&auto=format&fit=crop&q=80',
     True, ['Sustainability', 'Textiles', 'Resort'])
]

j_rows = []
for title, slug, excerpt, content, cover, is_pub, tags in journal_posts:
    tag_str = "{" + ",".join([f'"{t}"' for t in tags]) + "}"
    title_esc = title.replace("'", "''")
    excerpt_esc = excerpt.replace("'", "''")
    content_esc = content.replace("'", "''")
    j_rows.append(f"""(
        '{title_esc}', '{slug}', '{excerpt_esc}', '{content_esc}', '{cover}',
        '{designer_id}', {str(is_pub).lower()}, now() - interval '5 days', '{tag_str}'
    )""")

run_sql(f"""
    INSERT INTO public.journal_posts (
        title, slug, excerpt, content, cover_image_url,
        author_id, is_published, published_at, tags
    ) VALUES {', '.join(j_rows)}
    ON CONFLICT (slug) DO UPDATE SET
        content = EXCLUDED.content,
        is_published = true;
""")
print("  Journal posts inserted successfully.")

# 11. Batch Lookbook
print("\n--- Inserting Lookbook in Batch ---")
lookbook_entries = [
    ('Look 01 -- Sovereign Peplum in Royal Gold', 'look-01-sovereign-peplum-gold',
     'Opening runway silhouette featuring structured double peplum in duchess satin.',
     'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=1200&auto=format&fit=crop&q=80',
     'Adut Akech', 'Kelechi Amadi-Obi', 1),
    ('Look 02 -- Idoma Heritage Loom Column', 'look-02-idoma-heritage-column',
     'Handwoven red and black ceremonial column with sculptural shoulder fold.',
     'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=1200&auto=format&fit=crop&q=80',
     'Mayowa Nicholas', 'Lakin Ogunbanwo', 2),
    ('Look 03 -- Lagos Noir Velvet Tuxedo', 'look-03-lagos-noir-tuxedo',
     'Sharp shoulder midnight tuxedo suit with molten metallic lapels.',
     'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=1200&auto=format&fit=crop&q=80',
     'Oluchi Onweagba', 'Kelechi Amadi-Obi', 3),
    ('Look 04 -- Savanna Sunset Organza Flow', 'look-04-savanna-sunset-flow',
     'Tiered saffron gown catching the golden-hour wind with cathedral cape.',
     'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=1200&auto=format&fit=crop&q=80',
     'Ubah Hassan', 'Trevor Stuurman', 4),
    ('Look 05 -- Monarch Pearl Bridal Finale', 'look-05-monarch-pearl-bridal-finale',
     'Couture finale bridal gown featuring hand-embroidered veil and pearl encrusting.',
     'https://images.unsplash.com/photo-1519741497674-611481863552?w=1200&auto=format&fit=crop&q=80',
     'Alek Wek', 'Misan Harriman', 5),
    ('Look 06 -- Liquid Emerald Silk Charmeuse', 'look-06-liquid-emerald-silk',
     'Bias-cut evening elegance with cascading cowl back and side slit.',
     'https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?w=1200&auto=format&fit=crop&q=80',
     'Adwoa Aboah', 'Lakin Ogunbanwo', 6),
]

lb_rows = []
for title, slug, desc, img, model, photog, sort in lookbook_entries:
    desc_esc = desc.replace("'", "''")
    lb_rows.append(f"""(
        '{title}', '{slug}', '{desc_esc}', '{img}', '{img}',
        '{model}', '{photog}', true, {sort}
    )""")

run_sql(f"""
    INSERT INTO public.lookbook (
        title, slug, description, cover_image_url, full_image_url,
        model_name, photographer, is_published, sort_order
    ) VALUES {', '.join(lb_rows)}
    ON CONFLICT (slug) DO UPDATE SET
        description = EXCLUDED.description,
        is_published = true;
""")
print("  Lookbook entries inserted successfully.")

# 12. Batch Discounts
print("\n--- Inserting Discounts in Batch ---")
discounts = [
    ('ATELIER10', '10% Welcome gift for registered atelier clients', 'percentage', 10.0, 100000.0, 500),
    ('SOVEREIGN20', 'VIP 20% discount on Sovereign Peplum collection', 'percentage', 20.0, 300000.0, 100),
    ('ROYALBRIDAL', 'N50,000 credit on bespoke bridal consultations', 'fixed', 50000.0, 500000.0, 50),
    ('VIPCLIENT', '15% Exclusive invitation discount for couture clients', 'percentage', 15.0, 200000.0, 200),
]

disc_rows = []
for code, desc, dtype, val, min_o, max_u in discounts:
    disc_rows.append(f"('{code}', '{desc}', '{dtype}', {val}, {min_o}, {max_u}, true)")

run_sql(f"""
    INSERT INTO public.discounts (
        code, description, type, value, min_order_amount, max_uses, is_active
    ) VALUES {', '.join(disc_rows)}
    ON CONFLICT (code) DO UPDATE SET
        is_active = true,
        value = EXCLUDED.value;
""")
print("  Discounts inserted successfully.")

print("\n=== FAST SEED GENERATOR COMPLETED SUCCESSFULLY! ===")

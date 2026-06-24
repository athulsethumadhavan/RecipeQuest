import 'dart:convert';
import 'package:sqflite/sqflite.dart';

class DatabaseSeeder {
  DatabaseSeeder._();

  static Future<void> seed(Database db) async {
    await _seedCuisines(db);
    await _seedDishes(db);
    await _seedDishDetails(db);
  }

  // ── Cuisines ──────────────────────────────────────────────────────────────

  static Future<void> _seedCuisines(Database db) async {
    final cuisines = [
      {
        'id': 1,
        'name': 'Indian',
        'flag': '🇮🇳',
        'description':
            'A rich tapestry of bold spices, aromatic herbs, and centuries of culinary tradition spanning from the snow-capped Himalayas to the tropical coasts.',
        'gradient_start': '4A90E2',
        'gradient_end': '2F74CC',
        'thumbnail_url':
            'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=600&q=80&fit=crop',
      },
      {
        'id': 2,
        'name': 'Arabic',
        'flag': '🌙',
        'description':
            'A heritage of generous flavours rooted in ancient trade routes — fragrant rice, slow-cooked meats, fresh herbs, and honeyed sweets that tell stories of desert nights.',
        'gradient_start': '1B4F72',
        'gradient_end': '2980B9',
        'thumbnail_url':
            'https://images.unsplash.com/photo-1561758033-d89a9ad46330?w=600&q=80&fit=crop',
      },
    ];
    for (final c in cuisines) {
      await db.insert('cuisines', c);
    }
  }

  // ── Dishes ────────────────────────────────────────────────────────────────

  static Future<void> _seedDishes(Database db) async {
    final dishes = [
      // ── Indian (cuisine_id = 1) ──────────────────────────────────────────
      {
        'id': 1,
        'cuisine_id': 1,
        'name': 'Butter Chicken',
        'thumbnail_url':
            'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=600&q=80&fit=crop',
        'category': 'Main Course',
        'short_description':
            'Tender chicken in a rich, velvety tomato-cream sauce.',
      },
      {
        'id': 2,
        'cuisine_id': 1,
        'name': 'Chicken Biryani',
        'thumbnail_url':
            'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&q=80&fit=crop',
        'category': 'Rice Dish',
        'short_description':
            'Fragrant saffron rice layered with spiced chicken and caramelised onions.',
      },
      {
        'id': 3,
        'cuisine_id': 1,
        'name': 'Palak Paneer',
        'thumbnail_url':
            'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=600&q=80&fit=crop',
        'category': 'Vegetarian',
        'short_description':
            'Soft cottage cheese cubes in a vibrant, spiced spinach puree.',
      },
      {
        'id': 4,
        'cuisine_id': 1,
        'name': 'Dal Makhani',
        'thumbnail_url':
            'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=600&q=80&fit=crop',
        'category': 'Vegetarian',
        'short_description':
            'Slow-cooked black lentils simmered with butter and cream overnight.',
      },
      {
        'id': 5,
        'cuisine_id': 1,
        'name': 'Samosa',
        'thumbnail_url':
            'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600&q=80&fit=crop',
        'category': 'Snack',
        'short_description':
            'Crispy pastry parcels filled with spiced potatoes and peas.',
      },
      {
        'id': 6,
        'cuisine_id': 1,
        'name': 'Gulab Jamun',
        'thumbnail_url':
            'https://images.unsplash.com/photo-1571761274526-a7a7ed58b4c6?w=600&q=80&fit=crop',
        'category': 'Dessert',
        'short_description':
            'Spongy milk-solid dumplings soaked in rose-cardamom sugar syrup.',
      },
      // ── Arabic (cuisine_id = 2) ──────────────────────────────────────────
      {
        'id': 7,
        'cuisine_id': 2,
        'name': 'Chicken Shawarma',
        'thumbnail_url':
            'https://images.unsplash.com/photo-1561758033-d89a9ad46330?w=600&q=80&fit=crop',
        'category': 'Street Food',
        'short_description':
            'Marinated chicken roasted on a spit, wrapped in flatbread with garlic sauce.',
      },
      {
        'id': 8,
        'cuisine_id': 2,
        'name': 'Hummus',
        'thumbnail_url':
            'https://images.unsplash.com/photo-1590080877607-f9c9cca5d9d5?w=600&q=80&fit=crop',
        'category': 'Mezze',
        'short_description':
            'Velvety blended chickpeas with tahini, lemon, and garlic.',
      },
      {
        'id': 9,
        'cuisine_id': 2,
        'name': 'Kabsa',
        'thumbnail_url':
            'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600&q=80&fit=crop',
        'category': 'Main Course',
        'short_description':
            "Saudi Arabia's national dish — aromatic spiced rice with tender slow-cooked meat.",
      },
      {
        'id': 10,
        'cuisine_id': 2,
        'name': 'Falafel',
        'thumbnail_url':
            'https://images.unsplash.com/photo-1593001872095-7d5b3868dd20?w=600&q=80&fit=crop',
        'category': 'Street Food',
        'short_description':
            'Crispy fried chickpea balls packed with fresh herbs and cumin.',
      },
      {
        'id': 11,
        'cuisine_id': 2,
        'name': 'Mansaf',
        'thumbnail_url':
            'https://images.unsplash.com/photo-1574484284002-952d92456975?w=600&q=80&fit=crop',
        'category': 'Main Course',
        'short_description':
            "Jordan's celebratory lamb dish served over rice in fermented yogurt sauce.",
      },
      {
        'id': 12,
        'cuisine_id': 2,
        'name': 'Baklava',
        'thumbnail_url':
            'https://images.unsplash.com/photo-1519676867240-f03562e64548?w=600&q=80&fit=crop',
        'category': 'Dessert',
        'short_description':
            'Crispy phyllo layers filled with pistachios and drenched in honey-rose syrup.',
      },
    ];
    for (final d in dishes) {
      await db.insert('dishes', d);
    }
  }

  // ── Dish Details ──────────────────────────────────────────────────────────

  static Future<void> _seedDishDetails(Database db) async {
    final details = [
      // 1 ── Butter Chicken
      {
        'dish_id': 1,
        'full_description':
            'Butter Chicken (Murgh Makhani) was created in the 1950s at Moti Mahal restaurant in Delhi. Leftover tandoori chicken was simmered in a luscious tomato-butter-cream sauce, and a legend was born. Today it is arguably the most recognised Indian dish worldwide, prized for its mild heat and silky texture.',
        'ingredients': _encode([
          {'name': 'Chicken thighs', 'measure': '500 g'},
          {'name': 'Plain yogurt', 'measure': '3 tbsp'},
          {'name': 'Ginger-garlic paste', 'measure': '2 tbsp'},
          {'name': 'Kashmiri red chili powder', 'measure': '1 tsp'},
          {'name': 'Garam masala', 'measure': '1½ tsp'},
          {'name': 'Butter', 'measure': '3 tbsp'},
          {'name': 'Onion, finely chopped', 'measure': '1 large'},
          {'name': 'Tomatoes, pureed', 'measure': '4 large'},
          {'name': 'Heavy cream', 'measure': '100 ml'},
          {'name': 'Kasuri methi (dried fenugreek)', 'measure': '1 tsp'},
          {'name': 'Cumin seeds', 'measure': '1 tsp'},
          {'name': 'Coriander powder', 'measure': '1 tsp'},
          {'name': 'Salt', 'measure': 'to taste'},
          {'name': 'Sugar', 'measure': '1 tsp'},
        ]),
        'preparation':
            'Marinate chicken in yogurt, 1 tbsp ginger-garlic paste, chili powder, and a pinch of salt for at least 2 hours.\n'
            'Grill or pan-fry the marinated chicken on high heat until charred at the edges. Set aside.\n'
            'Melt butter in a heavy pan. Add cumin seeds and let them splutter.\n'
            'Add onions and sauté until deep golden brown, about 12 minutes.\n'
            'Add remaining ginger-garlic paste and cook for 2 minutes until raw smell disappears.\n'
            'Pour in tomato puree and cook on medium heat until oil separates from the masala, about 15 minutes.\n'
            'Allow the masala to cool slightly, then blend smooth. Pass through a sieve for an ultra-silky sauce.\n'
            'Return sauce to the pan. Add cream, garam masala, kasuri methi, and sugar. Simmer for 5 minutes.\n'
            'Add grilled chicken pieces to the sauce and simmer together for 10 minutes.\n'
            'Finish with a cube of butter and serve hot with naan or steamed basmati rice.',
        'video_url': 'https://www.youtube.com/watch?v=a03U45jFxOI',
      },

      // 2 ── Chicken Biryani
      {
        'dish_id': 2,
        'full_description':
            'Biryani traces its roots to Persia and arrived in India with the Mughal emperors. The Hyderabadi and Lucknowi styles are the most celebrated, each with distinct layering and dum (slow steam) techniques. This fragrant one-pot celebration dish is the centrepiece of weddings and festivals across South Asia.',
        'ingredients': _encode([
          {'name': 'Basmati rice, soaked 30 min', 'measure': '2 cups'},
          {'name': 'Chicken pieces on bone', 'measure': '750 g'},
          {'name': 'Onions, thinly sliced', 'measure': '3 large'},
          {'name': 'Plain yogurt', 'measure': '1 cup'},
          {'name': 'Biryani masala', 'measure': '2 tbsp'},
          {'name': 'Ginger-garlic paste', 'measure': '2 tbsp'},
          {'name': 'Saffron strands', 'measure': 'a pinch'},
          {'name': 'Warm milk', 'measure': '3 tbsp'},
          {'name': 'Ghee', 'measure': '4 tbsp'},
          {'name': 'Fresh mint leaves', 'measure': 'large handful'},
          {'name': 'Fresh coriander', 'measure': 'large handful'},
          {'name': 'Bay leaves', 'measure': '2'},
          {'name': 'Green cardamom', 'measure': '4 pods'},
          {'name': 'Cloves', 'measure': '4'},
          {'name': 'Cinnamon stick', 'measure': '1'},
          {'name': 'Salt', 'measure': 'to taste'},
          {'name': 'Oil for frying', 'measure': 'as needed'},
        ]),
        'preparation':
            'Fry sliced onions in oil until deep golden and crispy (birista). Drain on paper and set aside.\n'
            'Marinate chicken with yogurt, biryani masala, ginger-garlic paste, half the fried onions, salt, mint, and coriander for 1 hour.\n'
            'Infuse saffron in warm milk and set aside.\n'
            'Parboil soaked rice with whole spices (bay leaves, cardamom, cloves, cinnamon) and salt until 70% cooked. Drain.\n'
            'In a heavy pot, spread the marinated chicken at the bottom in a single layer.\n'
            'Layer the parboiled rice evenly over the chicken.\n'
            'Drizzle saffron milk, ghee, remaining fried onions, mint, and coriander on top.\n'
            'Seal the pot tightly with a lid (use dough if needed) and cook on high heat for 5 minutes.\n'
            'Reduce to the lowest heat and cook (dum) for 25 minutes. Do not open the lid.\n'
            'Rest for 10 minutes before opening. Serve gently with raita.',
        'video_url': 'https://www.youtube.com/watch?v=e5dTB5ZD4oM',
      },

      // 3 ── Palak Paneer
      {
        'dish_id': 3,
        'full_description':
            'Palak Paneer is a beloved North Indian vegetarian curry where fresh spinach is blanched and blended into a vivid green sauce that cradles golden-fried cubes of paneer (Indian cottage cheese). It is as nutritious as it is delicious, and a staple in homes and restaurants across India.',
        'ingredients': _encode([
          {'name': 'Fresh spinach, washed', 'measure': '500 g'},
          {'name': 'Paneer, cubed', 'measure': '250 g'},
          {'name': 'Onion, finely chopped', 'measure': '1 large'},
          {'name': 'Tomatoes, chopped', 'measure': '2 medium'},
          {'name': 'Garlic cloves', 'measure': '3'},
          {'name': 'Ginger', 'measure': '1 inch piece'},
          {'name': 'Green chilies', 'measure': '2'},
          {'name': 'Heavy cream', 'measure': '2 tbsp'},
          {'name': 'Butter', 'measure': '2 tbsp'},
          {'name': 'Oil', 'measure': '1 tbsp'},
          {'name': 'Cumin seeds', 'measure': '1 tsp'},
          {'name': 'Turmeric powder', 'measure': '¼ tsp'},
          {'name': 'Garam masala', 'measure': '½ tsp'},
          {'name': 'Salt', 'measure': 'to taste'},
        ]),
        'preparation':
            'Blanch spinach in boiling salted water for exactly 2 minutes. Transfer immediately to ice-cold water to retain the vivid green colour.\n'
            'Blend blanched spinach with green chilies to a smooth, bright-green puree. Set aside.\n'
            'Heat oil and butter in a pan. Add cumin seeds and let them sizzle.\n'
            'Add onions and cook on medium heat until golden, about 8 minutes.\n'
            'Add grated ginger and garlic, cook 2 minutes until fragrant.\n'
            'Add tomatoes and cook until completely soft and oil begins to separate.\n'
            'Add turmeric and a pinch of salt, then fold in the spinach puree.\n'
            'Simmer the spinach masala for 5 minutes to develop flavours.\n'
            'Gently slide in the paneer cubes. Add cream and garam masala.\n'
            'Simmer together for 3–4 minutes. Adjust salt.\n'
            'Serve hot with whole-wheat roti or naan.',
        'video_url': 'https://www.youtube.com/watch?v=S6UcVbmGPE8',
      },

      // 4 ── Dal Makhani
      {
        'dish_id': 4,
        'full_description':
            'Dal Makhani is one of the most luxurious lentil dishes in the world. The restaurant version is cooked for hours — sometimes overnight — in a tandoor with generous amounts of butter and cream. The result is an impossibly rich, mahogany-coloured dal with a smoky depth unlike any other.',
        'ingredients': _encode([
          {'name': 'Whole black lentils (urad dal)', 'measure': '1 cup'},
          {'name': 'Red kidney beans (rajma)', 'measure': '¼ cup'},
          {'name': 'Butter', 'measure': '4 tbsp'},
          {'name': 'Heavy cream', 'measure': '3 tbsp'},
          {'name': 'Onion, finely chopped', 'measure': '1 large'},
          {'name': 'Tomatoes, pureed', 'measure': '3'},
          {'name': 'Garlic cloves', 'measure': '5'},
          {'name': 'Ginger', 'measure': '1 inch piece'},
          {'name': 'Cumin seeds', 'measure': '1 tsp'},
          {'name': 'Coriander powder', 'measure': '1 tsp'},
          {'name': 'Red chili powder', 'measure': '1 tsp'},
          {'name': 'Garam masala', 'measure': '1 tsp'},
          {'name': 'Salt', 'measure': 'to taste'},
        ]),
        'preparation':
            'Soak black lentils and kidney beans in water overnight for at least 8 hours.\n'
            'Drain and pressure-cook with fresh water and salt for 20–25 minutes until completely soft and mashable.\n'
            'Melt butter in a heavy pot. Add cumin seeds and let them splutter.\n'
            'Add onions and cook slowly over medium heat until deep golden, about 15 minutes.\n'
            'Add grated ginger and garlic, cook for 2–3 minutes.\n'
            'Pour in tomato puree and cook until oil separates, about 12 minutes.\n'
            'Add chili powder, coriander powder, and garam masala. Stir well.\n'
            'Add the cooked lentils to the masala and stir to combine.\n'
            'Simmer on very low heat for a minimum of 1 hour, stirring occasionally, adding a little water if needed.\n'
            'Finish with butter and cream. Simmer 5 more minutes.\n'
            'Serve with a swirl of cream, a knob of butter, and hot naan.',
        'video_url': 'https://www.youtube.com/watch?v=uMfvHtWvHjA',
      },

      // 5 ── Samosa
      {
        'dish_id': 5,
        'full_description':
            "Samosas may be India's most iconic street food — hot, golden, and impossibly crispy triangles of pastry stuffed with a spiced potato and pea filling. Enjoyed at every tea stall, festival, and family gathering, the samosa has also conquered palates worldwide.",
        'ingredients': _encode([
          {'name': 'All-purpose flour (maida)', 'measure': '2 cups'},
          {'name': 'Oil or ghee for dough', 'measure': '3 tbsp'},
          {'name': 'Cold water', 'measure': 'as needed'},
          {'name': 'Potatoes, boiled and mashed', 'measure': '4 large'},
          {'name': 'Green peas, cooked', 'measure': '½ cup'},
          {'name': 'Onion, finely chopped', 'measure': '1 medium'},
          {'name': 'Green chilies, chopped', 'measure': '2'},
          {'name': 'Ginger, grated', 'measure': '1 inch piece'},
          {'name': 'Cumin seeds', 'measure': '1 tsp'},
          {'name': 'Coriander seeds, crushed', 'measure': '1 tsp'},
          {'name': 'Amchur (dry mango powder)', 'measure': '1 tsp'},
          {'name': 'Garam masala', 'measure': '1 tsp'},
          {'name': 'Fresh coriander, chopped', 'measure': 'small handful'},
          {'name': 'Salt', 'measure': 'to taste'},
          {'name': 'Oil for deep frying', 'measure': 'as needed'},
        ]),
        'preparation':
            'Make a stiff dough with flour, ghee, salt, and just enough cold water. Knead 5 minutes, cover and rest 30 minutes.\n'
            'Heat 1 tbsp oil in a pan. Splutter cumin and coriander seeds.\n'
            'Add onion, ginger, and green chili. Cook until onion softens.\n'
            'Add mashed potatoes and peas. Mix in amchur, garam masala, fresh coriander, and salt. Cook 3 minutes. Cool completely.\n'
            'Divide dough into equal balls. Roll each into an oval.\n'
            'Cut each oval in half. Form a cone from one semicircle by overlapping the cut edges and sealing with a little water.\n'
            'Fill the cone with the potato mixture — do not overfill.\n'
            'Seal the open edge firmly by pinching and pressing.\n'
            'Heat oil to 160°C (not too hot). Fry samosas on medium-low heat for 12–15 minutes, turning, until deep golden and very crispy.\n'
            'Serve hot with green mint chutney and tamarind sauce.',
        'video_url': 'https://www.youtube.com/watch?v=RuSJ6B5ZTJA',
      },

      // 6 ── Gulab Jamun
      {
        'dish_id': 6,
        'full_description':
            'Gulab Jamun is the queen of Indian desserts. The name comes from Persian — "gulab" (rose water) and "jamun" (a dark Indian berry the dumplings resemble). These spongy, syrup-soaked spheres made from khoya (reduced milk solids) are served warm at every Indian celebration.',
        'ingredients': _encode([
          {'name': 'Milk powder (full fat)', 'measure': '1 cup'},
          {'name': 'All-purpose flour', 'measure': '3 tbsp'},
          {'name': 'Baking soda', 'measure': '¼ tsp'},
          {'name': 'Ghee', 'measure': '1 tbsp'},
          {'name': 'Whole milk (to bind)', 'measure': 'as needed'},
          {'name': 'Sugar (for syrup)', 'measure': '2 cups'},
          {'name': 'Water (for syrup)', 'measure': '1 cup'},
          {'name': 'Green cardamom pods', 'measure': '4, lightly crushed'},
          {'name': 'Rose water', 'measure': '1 tsp'},
          {'name': 'Saffron strands', 'measure': 'a pinch'},
          {'name': 'Oil for deep frying', 'measure': 'as needed'},
        ]),
        'preparation':
            'Prepare syrup first: boil sugar, water, cardamom, and saffron for 5 minutes until slightly sticky. Remove from heat, stir in rose water. Keep warm.\n'
            'Combine milk powder, flour, and baking soda in a bowl. Mix well.\n'
            'Add ghee and rub it into the dry mix.\n'
            'Add milk, a tablespoon at a time, kneading gently to form a very soft, smooth dough. Do not overwork.\n'
            'Divide into 18–20 portions. Roll into perfectly smooth, crack-free balls between greased palms.\n'
            'Heat oil to 140°C — this low temperature is critical for cooking through without burning.\n'
            'Add balls to the oil and let them float up on their own. Stir gently and continuously for even browning.\n'
            'Fry for 8–10 minutes until deep mahogany brown all over.\n'
            'Transfer hot jamuns straight into the warm sugar syrup. Let them soak for a minimum of 2 hours.\n'
            'Serve warm, garnished with chopped pistachios and a few saffron strands.',
        'video_url': 'https://www.youtube.com/watch?v=s27BSCQBKCE',
      },

      // 7 ── Chicken Shawarma
      {
        'dish_id': 7,
        'full_description':
            'Shawarma is the ultimate Middle Eastern street food — spiced meat stacked on a rotating spit, shaved to order and wrapped in warm flatbread with creamy garlic sauce, pickles, and vegetables. The word "shawarma" derives from the Turkish "çevirme" meaning "turning". Every city across the Arab world has its own beloved version.',
        'ingredients': _encode([
          {'name': 'Chicken thighs, boneless', 'measure': '750 g'},
          {'name': 'Plain yogurt', 'measure': '½ cup'},
          {'name': 'Lemon juice', 'measure': '3 tbsp'},
          {'name': 'Olive oil', 'measure': '3 tbsp'},
          {'name': 'Garlic cloves, minced', 'measure': '4'},
          {'name': 'Ground cumin', 'measure': '2 tsp'},
          {'name': 'Ground coriander', 'measure': '1 tsp'},
          {'name': 'Turmeric', 'measure': '½ tsp'},
          {'name': 'Cinnamon', 'measure': '¼ tsp'},
          {'name': 'Cardamom', 'measure': '¼ tsp'},
          {'name': 'Smoked paprika', 'measure': '1 tsp'},
          {'name': 'Salt and black pepper', 'measure': 'to taste'},
          {'name': 'Pita or flatbread', 'measure': '4 pieces'},
          {'name': 'Tomatoes, sliced', 'measure': '2'},
          {'name': 'Pickled cucumbers', 'measure': 'to serve'},
          {'name': 'Toum (garlic sauce)', 'measure': 'to serve'},
        ]),
        'preparation':
            'Combine yogurt, lemon juice, olive oil, garlic, and all spices to make the marinade.\n'
            'Score the chicken thighs and coat thoroughly in the marinade. Refrigerate for at least 4 hours, or overnight for best results.\n'
            'To make toum: blend 1 head of garlic with lemon juice and salt, then slowly drizzle in ½ cup neutral oil until thick and creamy.\n'
            'Remove chicken from fridge 30 minutes before cooking.\n'
            'Heat a cast-iron grill pan or oven to 220°C. Cook chicken 6–7 minutes per side until charred and fully cooked through.\n'
            'Rest the chicken 5 minutes, then slice thinly across the grain.\n'
            'Warm flatbread on a dry griddle for 30 seconds per side.\n'
            'Spread toum generously on the bread. Layer chicken, tomatoes, and pickles.\n'
            'Roll tightly and wrap in parchment paper. Serve immediately.',
        'video_url': 'https://www.youtube.com/watch?v=rKpMFVCY1nU',
      },

      // 8 ── Hummus
      {
        'dish_id': 8,
        'full_description':
            'Hummus bi tahini is far more than a dip — it is a centuries-old staple of Levantine cuisine, a source of cultural pride, and arguably the world\'s most disputed food (Lebanon, Israel, and Palestine all claim it). True hummus is made from scratch with dried chickpeas, high-quality tahini, fresh lemon, and good olive oil. The texture should be cloud-like, never grainy.',
        'ingredients': _encode([
          {'name': 'Dried chickpeas, soaked overnight', 'measure': '250 g'},
          {'name': 'Baking soda (for cooking)', 'measure': '½ tsp'},
          {'name': 'Good-quality tahini', 'measure': '4 tbsp'},
          {'name': 'Fresh lemon juice', 'measure': '3 tbsp'},
          {'name': 'Garlic cloves', 'measure': '2'},
          {'name': 'Ice-cold water', 'measure': '4–6 tbsp'},
          {'name': 'Salt', 'measure': 'to taste'},
          {'name': 'Extra-virgin olive oil', 'measure': 'to finish'},
          {'name': 'Paprika', 'measure': 'pinch, to garnish'},
          {'name': 'Fresh flat-leaf parsley', 'measure': 'to garnish'},
          {'name': 'Whole cooked chickpeas', 'measure': 'to garnish'},
        ]),
        'preparation':
            'Drain soaked chickpeas. Cook in fresh water with baking soda until extremely soft — they should crush between two fingers effortlessly (about 1.5–2 hours).\n'
            'While still hot, transfer chickpeas to a food processor. The heat is key for smooth hummus.\n'
            'Process the hot chickpeas alone for 3 minutes until a thick paste forms.\n'
            'Add garlic, lemon juice, and salt. Process another 2 minutes.\n'
            'Add tahini and process for 2 minutes more.\n'
            'With the machine running, add ice-cold water tablespoon by tablespoon until the hummus is pale, airy, and very smooth.\n'
            'Taste and adjust lemon, salt, and tahini to your preference.\n'
            'To serve: spread on a wide plate with the back of a spoon in a circular motion to create a well in the centre.\n'
            'Fill the well with olive oil. Sprinkle paprika and garnish with whole chickpeas and fresh parsley.\n'
            'Serve with warm pita or as part of a mezze spread.',
        'video_url': 'https://www.youtube.com/watch?v=D3I9jGJvEJM',
      },

      // 9 ── Kabsa
      {
        'dish_id': 9,
        'full_description':
            "Kabsa is the undisputed national dish of Saudi Arabia and is beloved across the Gulf states. A feast of long-grain rice cooked in a deeply spiced broth with whole chicken or lamb, dried limes (loomi), and finished with a topping of fried nuts and raisins. It is the dish of hospitality — traditionally served on a communal tray for family gatherings.",
        'ingredients': _encode([
          {'name': 'Whole chicken, cut into pieces', 'measure': '1.2 kg'},
          {'name': 'Basmati rice, soaked 30 min', 'measure': '3 cups'},
          {'name': 'Onions, finely diced', 'measure': '2 large'},
          {'name': 'Tomatoes, chopped', 'measure': '3'},
          {'name': 'Tomato paste', 'measure': '2 tbsp'},
          {'name': 'Garlic cloves', 'measure': '5'},
          {'name': 'Dried limes (loomi)', 'measure': '3, pierced'},
          {'name': 'Kabsa spice mix', 'measure': '2 tbsp'},
          {'name': 'Green cardamom', 'measure': '4 pods'},
          {'name': 'Cinnamon sticks', 'measure': '2'},
          {'name': 'Cloves', 'measure': '4'},
          {'name': 'Bay leaves', 'measure': '3'},
          {'name': 'Saffron in warm water', 'measure': 'a pinch'},
          {'name': 'Raisins', 'measure': '¼ cup'},
          {'name': 'Blanched almonds', 'measure': '¼ cup'},
          {'name': 'Butter', 'measure': '2 tbsp'},
          {'name': 'Salt', 'measure': 'to taste'},
        ]),
        'preparation':
            'Heat oil in a large pot. Brown chicken pieces on all sides. Remove and set aside.\n'
            'In the same pot, sauté onions and garlic until deeply golden.\n'
            'Add tomatoes and tomato paste, cook until a thick masala forms.\n'
            'Return chicken to the pot. Add whole spices (cardamom, cinnamon, cloves, bay leaves) and pierced dried limes.\n'
            'Add enough water to cover the chicken. Bring to a boil, skim foam, then simmer covered for 45 minutes until chicken is tender.\n'
            'Remove chicken. Strain the broth and measure 5 cups.\n'
            'Add kabsa spice mix and saffron water to the strained broth and bring to a boil.\n'
            'Add drained rice. Cook uncovered until water is absorbed to the level of the rice.\n'
            'Cover tightly and steam on very low heat for 20 minutes.\n'
            'Fry almonds and raisins in butter until golden. Set aside for garnish.\n'
            'Spread rice on a large serving tray, arrange chicken on top, garnish with nuts and raisins.',
        'video_url': 'https://www.youtube.com/watch?v=7yKHVvtpBJI',
      },

      // 10 ── Falafel
      {
        'dish_id': 10,
        'full_description':
            'Falafel is one of the Arab world\'s greatest contributions to global street food culture. Made from raw soaked chickpeas (never canned!) ground with masses of fresh parsley and coriander, these emerald-green-centred crispy balls are a staple from Cairo to Beirut. The golden, crunchy exterior giving way to a herb-flecked, fluffy interior is simply irresistible.',
        'ingredients': _encode([
          {'name': 'Dried chickpeas, soaked overnight', 'measure': '2 cups'},
          {'name': 'Onion, roughly chopped', 'measure': '1 large'},
          {'name': 'Garlic cloves', 'measure': '4'},
          {'name': 'Fresh flat-leaf parsley', 'measure': 'large bunch'},
          {'name': 'Fresh coriander', 'measure': 'large bunch'},
          {'name': 'Ground cumin', 'measure': '2 tsp'},
          {'name': 'Ground coriander', 'measure': '1 tsp'},
          {'name': 'Baking soda', 'measure': '½ tsp'},
          {'name': 'Sesame seeds', 'measure': '2 tbsp'},
          {'name': 'Salt and black pepper', 'measure': 'to taste'},
          {'name': 'Oil for deep frying', 'measure': 'as needed'},
          {'name': 'Pita bread', 'measure': 'to serve'},
          {'name': 'Tahini sauce', 'measure': 'to serve'},
          {'name': 'Pickled turnips', 'measure': 'to serve'},
        ]),
        'preparation':
            'Drain soaked chickpeas thoroughly — they must be raw, not cooked. Excess moisture will cause falafel to fall apart.\n'
            'Pulse chickpeas in a food processor until coarsely ground (not a paste). Transfer to a large bowl.\n'
            'In the same processor, blend onion, garlic, parsley, and coriander until finely chopped.\n'
            'Combine the herb mixture with the ground chickpeas. Add cumin, coriander, salt, and pepper. Mix well.\n'
            'Add baking soda and sesame seeds. Mix again. The mixture should hold shape when pressed.\n'
            'Refrigerate the mixture for at least 1 hour — this is essential for them to hold together during frying.\n'
            'Heat oil in a deep pan to 175°C.\n'
            'Shape mixture into balls or patties using a falafel scoop or wet hands.\n'
            'Fry in small batches for 3–4 minutes until deep golden brown all over. Do not crowd the pan.\n'
            'Drain on paper towels. Serve immediately in pita with tahini sauce, tomatoes, cucumber, and pickled turnips.',
        'video_url': 'https://www.youtube.com/watch?v=7mHQCFh2yAg',
      },

      // 11 ── Mansaf
      {
        'dish_id': 11,
        'full_description':
            "Mansaf is Jordan's soul food and its most important cultural dish — the centrepiece of weddings, religious celebrations, and acts of reconciliation. Lamb is cooked low and slow in jameed, a pungent fermented dried goat yogurt that gives the dish its unique, deeply tangy flavour. It is served on a communal tray with rice, with the sauce poured generously over everything.",
        'ingredients': _encode([
          {'name': 'Lamb shoulder or leg, bone-in', 'measure': '1.5 kg'},
          {'name': 'Jameed (dried fermented yogurt)', 'measure': '500 g'},
          {'name': 'Warm water (to dissolve jameed)', 'measure': '4 cups'},
          {'name': 'Basmati rice', 'measure': '3 cups'},
          {'name': 'Onion, halved', 'measure': '1 large'},
          {'name': 'Ghee', 'measure': '3 tbsp'},
          {'name': 'Turmeric', 'measure': '1 tsp'},
          {'name': 'Black pepper', 'measure': '1 tsp'},
          {'name': 'Bay leaves', 'measure': '2'},
          {'name': 'Blanched almonds', 'measure': '½ cup'},
          {'name': 'Pine nuts', 'measure': '¼ cup'},
          {'name': 'Salt', 'measure': 'to taste'},
          {'name': 'Flatbread (shrak)', 'measure': 'to serve'},
          {'name': 'Fresh parsley', 'measure': 'to garnish'},
        ]),
        'preparation':
            'Soak the hard jameed in 4 cups of warm water overnight, breaking it into pieces as it softens.\n'
            'Place lamb in a large pot with onion, turmeric, black pepper, bay leaves, and salt. Cover with water and bring to a boil.\n'
            'Skim foam from the surface. Cover and simmer for 1.5–2 hours until the lamb is very tender and falls off the bone.\n'
            'Remove lamb from the broth. Keep both separately.\n'
            'Strain the soaked jameed mixture through a fine sieve into a pot to make a smooth sauce.\n'
            'Add 2 cups of the lamb broth to the jameed sauce. Warm gently over medium heat, stirring constantly — do not let it boil or it will curdle.\n'
            'Cook rice in remaining lamb broth with ghee until fluffy.\n'
            'Fry almonds and pine nuts in ghee until golden. Set aside.\n'
            'To assemble: lay shrak flatbread on a large round tray. Mound the rice on top. Place lamb pieces over the rice.\n'
            'Pour the jameed sauce over everything generously. Garnish with toasted nuts and fresh parsley.\n'
            'Serve immediately with extra jameed sauce on the side.',
        'video_url': 'https://www.youtube.com/watch?v=M_X0nJkK5xU',
      },

      // 12 ── Baklava
      {
        'dish_id': 12,
        'full_description':
            'Baklava is the jewel of Arabic and Ottoman pastry — paper-thin phyllo sheets alternating with a fragrant pistachio and walnut filling, baked until shatteringly crispy, then immediately drenched in cold fragrant syrup. The contrast of textures and the perfume of rose water and orange blossom make it utterly irresistible. True baklava requires patience, butter, and generosity.',
        'ingredients': _encode([
          {'name': 'Phyllo dough sheets', 'measure': '500 g (thawed)'},
          {'name': 'Unsalted butter, clarified', 'measure': '250 g'},
          {'name': 'Unsalted pistachios, shelled', 'measure': '200 g'},
          {'name': 'Walnuts', 'measure': '100 g'},
          {'name': 'Sugar (for filling)', 'measure': '2 tbsp'},
          {'name': 'Ground cinnamon', 'measure': '1 tsp'},
          {'name': 'Sugar (for syrup)', 'measure': '1½ cups'},
          {'name': 'Water (for syrup)', 'measure': '¾ cup'},
          {'name': 'Honey', 'measure': '3 tbsp'},
          {'name': 'Lemon juice', 'measure': '1 tbsp'},
          {'name': 'Rose water', 'measure': '1 tbsp'},
          {'name': 'Orange blossom water', 'measure': '1 tbsp'},
        ]),
        'preparation':
            'Make the syrup first: combine sugar and water, bring to a boil, stir until sugar dissolves. Add honey, lemon juice, rose water, and orange blossom water. Simmer 10 minutes until slightly thickened. Cool completely in the fridge — cold syrup on hot baklava is essential.\n'
            'Pulse pistachios and walnuts in a processor until coarsely chopped. Mix with sugar and cinnamon.\n'
            'Clarify butter by melting gently and skimming foam off the top.\n'
            'Preheat oven to 160°C. Brush a 30 x 20 cm baking pan with butter.\n'
            'Layer 8 sheets of phyllo in the pan, brushing each generously with clarified butter.\n'
            'Spread a thin, even layer of the nut mixture over the phyllo.\n'
            'Layer 3 more buttered phyllo sheets, then another layer of nuts.\n'
            'Repeat until nuts are used. Finish with the remaining phyllo sheets, all well-buttered.\n'
            'With a very sharp knife, cut the baklava into diamonds or squares before baking — cut all the way through.\n'
            'Bake for 45–50 minutes until deeply golden on top.\n'
            'Remove from oven and immediately pour the cold syrup evenly over the hot baklava. It will sizzle dramatically.\n'
            'Leave to soak at room temperature for a minimum of 4 hours before serving.',
        'video_url': 'https://www.youtube.com/watch?v=P0bEKMDFBKk',
      },
    ];

    for (final d in details) {
      await db.insert('dish_details', d);
    }
  }

  static String _encode(List<Map<String, String>> list) =>
      jsonEncode(list);
}

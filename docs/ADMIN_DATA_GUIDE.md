# 🔐 ADMIN GUIDE: Adding Deities & Mantras to Database

## 📋 **OVERVIEW**

This guide explains how to add deities and mantras to your Supabase database after removing hardcoded data.

---

## 🚀 **QUICK START**

### **Option 1: Using Supabase Table Editor (Recommended for Initial Setup)**

1. Go to: https://dsoaiypfqxdqbvjsxikd.supabase.co
2. Click **Table Editor** in sidebar
3. Follow steps below

### **Option 2: Using Admin Panel (Coming Soon)**

Your admin panel will have forms to add/edit/delete deities and mantras easily.

---

## 👼 **ADDING DEITIES**

### **Step-by-Step:**

1. **Open Supabase Dashboard**
   - Navigate to **Table Editor**
   - Select **`deities`** table

2. **Click "Insert" → "Insert row"**

3. **Fill Required Fields:**

| Field | Example | Notes |
|-------|---------|-------|
| `english_name` | "Durga Ji" | Display name in English |
| `hindi_name` | "दुर्गा जी" | Display name in Hindi |
| `icon` | "🕉️" | Emoji icon |
| `description_en` | "Goddess of Power" | English description |
| `description_hi` | "शक्ति की देवी" | Hindi description |
| `colors` | `["#FF6B6B", "#FF8E8E"]` | JSON array of hex colors |
| `image_url` | "https://..." | Optional image URL |
| `is_active` | `true` | Show in app |
| `is_custom` | `false` | Default deities |
| `display_order` | `0` | Sort order |

4. **Click Save**

5. **Copy the UUID** (you'll need it for mantras)

### **Example Deity Data:**

```json
{
  "english_name": "Ganesha Ji",
  "hindi_name": "गणेश जी",
  "icon": "🐘",
  "description_en": "Remover of Obstacles",
  "description_hi": "बाधाओं को दूर करने वाले",
  "colors": ["#4ECDC4", "#6ED5CD", "#8EDDD6"],
  "image_url": "https://example.com/ganesha.jpg",
  "is_active": true,
  "is_custom": false,
  "display_order": 1
}
```

---

## 🕉️ **ADDING MANTRAS**

### **Step-by-Step:**

1. **Open Supabase Dashboard**
   - Navigate to **Table Editor**
   - Select **`mantras`** table

2. **Click "Insert" → "Insert row"**

3. **Fill Required Fields:**

| Field | Example | Notes |
|-------|---------|-------|
| `mantra_en` | "Om Gam Ganapataye" | Mantra in English |
| `mantra_hi` | "ॐ गं गणपतये" | Mantra in Devanagari |
| `meaning_en` | "Salutations to Ganesha" | English meaning |
| `meaning_hi` | "गणेश को नमन" | Hindi meaning |
| `benefits_en` | "Removes obstacles" | English benefits |
| `benefits_hi` | "बाधाओं को दूर करता है" | Hindi benefits |
| `deity_id` | `[UUID from deities table]` | Link to deity |
| `category` | "Ganesha" | Category name |
| `difficulty_level` | "easy" | `easy`, `medium`, or `difficult` |
| `is_active` | `true` | Show in app |
| `is_custom` | `false` | Default mantras |
| `display_order` | `0` | Sort order |

4. **Click Save**

### **Example Mantra Data:**

```json
{
  "mantra_en": "Om Gam Ganapataye Namah",
  "mantra_hi": "ॐ गं गणपतये नमः",
  "meaning_en": "I bow to Lord Ganesha, the remover of obstacles",
  "meaning_hi": "मैं बाधाओं को दूर करने वाले भगवान गणेश को नमन करता हूं",
  "benefits_en": "Removes obstacles, grants wisdom, and brings success",
  "benefits_hi": "बाधाओं को दूर करता है, ज्ञान प्रदान करता है, और सफलता लाता है",
  "deity_id": "12345678-1234-1234-1234-123456789abc",
  "category": "Ganesha",
  "difficulty_level": "easy",
  "is_active": true,
  "is_custom": false,
  "display_order": 0
}
```

---

## 📊 **BULK INSERT (For Multiple Mantras)**

If you have many mantras to add, use SQL bulk insert:

```sql
-- Insert multiple mantras at once
INSERT INTO public.mantras 
  (mantra_en, mantra_hi, meaning_en, meaning_hi, benefits_en, benefits_hi, 
   deity_id, category, difficulty_level, is_active, display_order)
VALUES
  ('Om Dum Durgayei', 'ॐ दुं दुर्गायै', 
   'I bow to Goddess Durga', 'मैं देवी दुर्गा को नमन करता हूं',
   'Provides protection', 'सुरक्षा प्रदान करता है',
   '12345678-1234-1234-1234-123456789abc', 'Durga', 'easy', true, 0),
   
  ('Om Katyayani Namah', 'ॐ कात्यायनी नमः',
   'Salutations to Katyayani', 'कात्यायनी को नमन',
   'Bestows wisdom', 'ज्ञान प्रदान करता है',
   '12345678-1234-1234-1234-123456789abc', 'Durga', 'medium', true, 1);
```

---

## 🎨 **CATEGORY NAMING CONVENTIONS**

Use consistent category names to ensure filters work properly:

| Deity | Category Name | Hindi |
|-------|---------------|-------|
| Durga | "Durga" | दुर्गा |
| Ganesha | "Ganesha" | गणेश |
| Hanuman | "Hanuman" | हनुमान |
| Krishna | "Krishna" | कृष्ण |
| Lakshmi | "Lakshmi" | लक्ष्मी |
| Shiv | "Shiv" | शिव |
| Ram | "Ram" | राम |
| Saraswati | "Saraswati" | सरस्वती |
| Vishnu | "Vishnu" | विष्णु |

**⚠️ Important:** Category must exactly match for filters to work!

---

## 🔢 **DIFFICULTY LEVELS**

Only use these three values:

| Level | When to Use |
|-------|-------------|
| `easy` | Short mantras, simple pronunciation |
| `medium` | Medium length, moderate difficulty |
| `difficult` | Long mantras, complex Sanskrit words |

**Example:**
- Easy: "Om Namah Shivaya"
- Medium: "Om Namo Bhagavate Vasudevaya"
- Difficult: "Ya Devi Sarvabhuteshu Shakti Rupena Samsthita..."

---

## 🎯 **DISPLAY ORDER**

Use `display_order` to control the sequence:

- **Lower numbers appear first** (0, 1, 2, 3...)
- All items with same order are sorted by `created_at`

**Example:**
```
display_order: 0  → "Om Gam Ganapataye"  (shows first)
display_order: 1  → "Om Namah Shivaya"   (shows second)
display_order: 2  → "Om Namo Narayanaya" (shows third)
```

---

## 🖼️ **IMAGE URLS**

For deity images, you can:

1. **Upload to Supabase Storage:**
   - Go to **Storage** in Supabase Dashboard
   - Create bucket: `deity-images`
   - Upload images
   - Get public URL
   - Use in `image_url` field

2. **Use External URLs:**
   - Use any publicly accessible image URL
   - Recommended: Use CDN URLs for better performance

**Example URLs:**
```
Supabase: https://dsoaiypfqxdqbvjsxikd.supabase.co/storage/v1/object/public/deity-images/ganesha.jpg
External: https://your-cdn.com/images/ganesha.jpg
```

---

## 🧪 **TESTING YOUR DATA**

After adding data:

1. **Open App**
2. **Navigate to Ram Naam Lekhan → Mantras**
3. **Verify:**
   - [ ] Mantras appear
   - [ ] Search works
   - [ ] Category filters work
   - [ ] Difficulty badges show correct color
   - [ ] Deity images load
   - [ ] Hindi text displays correctly

---

## 🔄 **UPDATING DATA**

### **To Update a Mantra:**

1. Go to **Table Editor → mantras**
2. Find the mantra you want to update
3. Click the row
4. Click **Edit**
5. Modify fields
6. Click **Save**

### **To Deactivate (Hide) a Mantra:**

1. Go to **Table Editor → mantras**
2. Find the mantra
3. Set `is_active = false`
4. Click **Save**

The mantra will immediately disappear from the app.

### **To Delete Permanently:**

**⚠️ Warning:** This cannot be undone!

1. Go to **Table Editor → mantras**
2. Find the mantra
3. Click the row
4. Click **Delete**
5. Confirm deletion

---

## 📊 **DATA VALIDATION**

Before saving, verify:

✅ **Required Fields:**
- [ ] `mantra_en` is filled
- [ ] `mantra_hi` is filled
- [ ] `category` matches deity name
- [ ] `difficulty_level` is one of: easy, medium, difficult

✅ **Optional but Recommended:**
- [ ] `meaning_en` is filled
- [ ] `meaning_hi` is filled
- [ ] `benefits_en` is filled
- [ ] `benefits_hi` is filled
- [ ] `deity_id` is set (links to deity)

✅ **Formatting:**
- [ ] Hindi text uses proper Devanagari script
- [ ] Colors are valid hex codes (e.g., "#FF6B6B")
- [ ] Image URLs are accessible

---

## 🚨 **COMMON MISTAKES**

### ❌ **Wrong:**
```json
{
  "difficulty_level": "Easy"  // Capital E
}
```

### ✅ **Correct:**
```json
{
  "difficulty_level": "easy"  // lowercase
}
```

---

### ❌ **Wrong:**
```json
{
  "colors": "#FF6B6B, #FF8E8E"  // String, not array
}
```

### ✅ **Correct:**
```json
{
  "colors": ["#FF6B6B", "#FF8E8E"]  // JSON array
}
```

---

### ❌ **Wrong:**
```json
{
  "category": "ganesh"  // lowercase, missing Ji
}
```

### ✅ **Correct:**
```json
{
  "category": "Ganesha"  // Proper case
}
```

---

## 🎓 **EXAMPLE: COMPLETE WORKFLOW**

### **1. Add a Deity (Lakshmi)**

```sql
INSERT INTO public.deities 
  (english_name, hindi_name, icon, description_en, description_hi, 
   colors, is_active, display_order)
VALUES
  ('Lakshmi Ji', 'लक्ष्मी जी', '💰',
   'Goddess of Wealth and Prosperity', 'धन और समृद्धि की देवी',
   '["#FFD700", "#FFE55C", "#FFEB8A"]'::jsonb, true, 4);
```

**Note the UUID returned:** `a1b2c3d4-e5f6-7890-abcd-ef1234567890`

### **2. Add Mantras for Lakshmi**

```sql
INSERT INTO public.mantras 
  (mantra_en, mantra_hi, meaning_en, meaning_hi, benefits_en, benefits_hi,
   deity_id, category, difficulty_level, is_active, display_order)
VALUES
  -- Easy mantra
  ('Om Shreem Mahalakshmyai', 'ॐ श्रीं महालक्ष्म्यै',
   'I bow to Goddess Lakshmi', 'मैं देवी लक्ष्मी को नमन करता हूं',
   'Attracts prosperity and wealth', 'समृद्धि और धन को आकर्षित करता है',
   'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Lakshmi', 'easy', true, 0),
   
  -- Medium mantra
  ('Om Mahalakshmyai Cha Vidmahe', 'ॐ महालक्ष्म्यै च विद्महे',
   'I meditate upon Goddess Lakshmi', 'मैं देवी लक्ष्मी का ध्यान करता हूं',
   'Brings success and spiritual prosperity', 'सफलता और आध्यात्मिक समृद्धि लाता है',
   'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Lakshmi', 'medium', true, 1);
```

### **3. Test in App**

1. Open app
2. Go to Mantras
3. Filter by "Lakshmi" category
4. Should see 2 mantras
5. Verify difficulty badges (green for easy, orange for medium)

---

## 📞 **NEED HELP?**

### **Common Issues:**

**Q: Mantras not showing in app?**
- Check `is_active = true`
- Verify internet connection
- Check Supabase RLS policies

**Q: Category filter not working?**
- Verify category name matches exactly
- Check for typos or extra spaces

**Q: Hindi text shows as boxes?**
- Use proper Devanagari Unicode characters
- Copy from a reliable source

**Q: Images not loading?**
- Verify URL is publicly accessible
- Check for CORS issues
- Try opening URL directly in browser

---

## ✅ **CHECKLIST FOR NEW MANTRA**

Before adding a new mantra:

- [ ] Deity exists in `deities` table
- [ ] Have deity's UUID ready
- [ ] Mantra text (English & Hindi) ready
- [ ] Meaning (English & Hindi) ready
- [ ] Benefits (English & Hindi) ready
- [ ] Category name matches deity
- [ ] Difficulty level chosen
- [ ] Display order decided

---

**Happy Data Entry! 🎉**

For technical issues, contact your development team.

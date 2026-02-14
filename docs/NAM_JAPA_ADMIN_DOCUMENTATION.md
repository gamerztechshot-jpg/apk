# Nam Japa Admin Section - Complete Documentation

## 📋 Table of Contents

1. [Overview](#overview)
2. [Database Schema](#database-schema)
3. [Frontend Architecture](#frontend-architecture)
4. [Backend Requirements](#backend-requirements)
5. [API Specifications](#api-specifications)
6. [UI Components & Screens](#ui-components--screens)
7. [Integration Guide](#integration-guide)
8. [Step-by-Step Implementation](#step-by-step-implementation)
9. [Security & Authentication](#security--authentication)
10. [Testing & Validation](#testing--validation)

---

## 📖 Overview

The **Nam Japa Admin Section** is a comprehensive content management system for administering mantras and deities within the Hindu Gurukul application. This section allows administrators to:

- ✅ Create, Read, Update, Delete (CRUD) mantras
- ✅ Manage deity information
- ✅ Control content visibility and ordering
- ✅ Support bilingual content (English & Hindi)
- ✅ Organize mantras by category and difficulty
- ✅ Associate mantras with specific deities

### Technology Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Supabase (PostgreSQL)
- **State Management:** Provider
- **Authentication:** Supabase Auth
- **Storage:** Supabase Storage (for images/icons)

---

## 🗄️ Database Schema

### Table 1: `mantra_master_collection`

Stores all mantra data including multilingual content, categorization, and metadata.

| Column Name | Data Type | Constraints | Description |
|------------|-----------|-------------|-------------|
| `id` | `text` | PRIMARY KEY | Unique identifier for each mantra |
| `mantra_en` | `text` | NOT NULL | Mantra text in English |
| `mantra_hi` | `text` | NOT NULL | Mantra text in Hindi (Devanagari) |
| `meaning_en` | `text` | | Meaning/translation in English |
| `meaning_hi` | `text` | | Meaning/translation in Hindi |
| `benefits_en` | `text` | | Benefits description in English |
| `benefits_hi` | `text` | | Benefits description in Hindi |
| `deity_id` | `uuid` | FOREIGN KEY → `deities.id` | Associated deity reference |
| `category` | `varchar` | | Category (e.g., "Ram", "Shiv", "Durga") |
| `difficulty_level` | `varchar` | | "easy", "medium", "difficult" |
| `is_active` | `bool` | DEFAULT true | Visibility toggle (active mantras shown to users) |
| `is_custom` | `bool` | DEFAULT false | Flag for custom/user-submitted mantras |
| `is_favorite` | `bool` | DEFAULT false | Admin-marked favorite/featured status |
| `display_order` | `int4` | DEFAULT 0 | Sort order for display (lower = higher priority) |
| `created_by` | `uuid` | FOREIGN KEY → `users.id` | Admin user who created the entry |
| `created_at` | `timestamptz` | DEFAULT now() | Creation timestamp |
| `updated_at` | `timestamptz` | DEFAULT now() | Last update timestamp |

**Indexes:**
```sql
CREATE INDEX idx_mantra_deity ON mantra_master_collection(deity_id);
CREATE INDEX idx_mantra_category ON mantra_master_collection(category);
CREATE INDEX idx_mantra_active ON mantra_master_collection(is_active);
CREATE INDEX idx_mantra_display_order ON mantra_master_collection(display_order);
```

### Table 2: `deities`

Stores deity information with multilingual support and visual assets.

| Column Name | Data Type | Constraints | Description |
|------------|-----------|-------------|-------------|
| `id` | `uuid` | PRIMARY KEY | Unique identifier for each deity |
| `english_name` | `text` | NOT NULL, UNIQUE | Deity name in English |
| `hindi_name` | `text` | NOT NULL | Deity name in Hindi (Devanagari) |
| `icon` | `text` | | Icon reference (emoji or small image URL) |
| `description_en` | `text` | | Detailed description in English |
| `description_hi` | `text` | | Detailed description in Hindi |
| `colors` | `jsonb` | | Array of theme colors (e.g., `["#FF9933", "#FFFFFF"]`) |
| `image_url` | `text` | | Full deity image URL (Supabase Storage) |
| `is_active` | `bool` | DEFAULT true | Visibility toggle |
| `display_order` | `int4` | DEFAULT 0 | Sort order for display |
| `created_by` | `uuid` | FOREIGN KEY → `users.id` | Admin user who created the entry |
| `created_at` | `timestamptz` | DEFAULT now() | Creation timestamp |
| `updated_at` | `timestamptz` | DEFAULT now() | Last update timestamp |

**Indexes:**
```sql
CREATE INDEX idx_deity_active ON deities(is_active);
CREATE INDEX idx_deity_display_order ON deities(display_order);
```

---

## 🎨 Frontend Architecture

### File Structure

```
lib/
├── features/
│   └── admin/
│       ├── screens/
│       │   ├── admin_dashboard_screen.dart          # Main admin landing
│       │   ├── nam_japa_admin/
│       │   │   ├── mantras/
│       │   │   │   ├── mantra_list_screen.dart      # List all mantras
│       │   │   │   ├── mantra_form_screen.dart      # Create/Edit mantra
│       │   │   │   └── mantra_detail_screen.dart    # View mantra details
│       │   │   └── deities/
│       │   │       ├── deity_list_screen.dart       # List all deities
│       │   │       ├── deity_form_screen.dart       # Create/Edit deity
│       │   │       └── deity_detail_screen.dart     # View deity details
│       ├── widgets/
│       │   ├── admin_app_bar.dart                   # Reusable admin app bar
│       │   ├── data_table_widget.dart               # Reusable data table
│       │   ├── form_field_widgets.dart              # Custom form fields
│       │   └── image_upload_widget.dart             # Image upload component
│       ├── services/
│       │   ├── admin_mantra_service.dart            # Admin CRUD for mantras
│       │   └── admin_deity_service.dart             # Admin CRUD for deities
│       └── models/
│           └── admin_user_model.dart                # Admin user permissions
├── core/
│   └── services/
│       ├── mantra_service.dart                      # ✅ Already exists (READ operations)
│       ├── deity_service.dart                       # ✅ Already exists (READ operations)
│       └── auth_service.dart                        # ✅ Already exists (Authentication)
└── routes.dart                                      # Add admin routes
```

### Key Models (Already Exist)

#### `MantraModel` (`lib/features/ramnam_lekhan/models/mantra_model.dart`)

```dart
class MantraModel {
  final String id;
  final String mantra;              // mantra_en
  final String hindiMantra;         // mantra_hi
  final String meaning;             // meaning_en
  final String hindiMeaning;        // meaning_hi
  final String benefits;            // benefits_en
  final String hindiBenefits;       // benefits_hi
  final String? deityId;
  final String category;
  final DifficultyLevel difficultyLevel;
  final bool isFavorite;
  final bool isActive;
  final bool isCustom;
  final int displayOrder;
  
  // ✅ fromJson() and toJson() already implemented
}

enum DifficultyLevel { easy, medium, difficult }
```

#### `DeityModel` (`lib/features/ramnam_lekhan/models/deity_model.dart`)

```dart
class DeityModel {
  final String id;
  final String englishName;
  final String hindiName;
  final String icon;
  final String description;         // description_en
  final String hindiDescription;    // description_hi
  final List<String> colors;
  final String? imageUrl;
  final bool isActive;
  final bool isCustom;
  final int displayOrder;
  
  // ✅ fromJson() and toJson() already implemented
}
```

---

## 🔧 Backend Requirements

### Supabase Configuration

#### 1. **Row Level Security (RLS) Policies**

**For `mantra_master_collection`:**

```sql
-- ✅ Public READ access (active mantras only)
CREATE POLICY "Public users can view active mantras"
ON mantra_master_collection FOR SELECT
USING (is_active = true);

-- 🔐 Admin FULL access
CREATE POLICY "Admins can do everything with mantras"
ON mantra_master_collection FOR ALL
USING (
  auth.uid() IN (
    SELECT id FROM auth.users 
    WHERE raw_user_meta_data->>'role' = 'admin'
  )
);
```

**For `deities`:**

```sql
-- ✅ Public READ access (active deities only)
CREATE POLICY "Public users can view active deities"
ON deities FOR SELECT
USING (is_active = true);

-- 🔐 Admin FULL access
CREATE POLICY "Admins can do everything with deities"
ON deities FOR ALL
USING (
  auth.uid() IN (
    SELECT id FROM auth.users 
    WHERE raw_user_meta_data->>'role' = 'admin'
  )
);
```

#### 2. **Database Functions**

**Auto-update `updated_at` timestamp:**

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to mantras
CREATE TRIGGER update_mantra_updated_at BEFORE UPDATE ON mantra_master_collection
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Apply to deities
CREATE TRIGGER update_deity_updated_at BEFORE UPDATE ON deities
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

#### 3. **Supabase Storage Buckets**

```sql
-- Create storage bucket for deity images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('deity-images', 'deity-images', true);

-- Storage policy: Public read, Admin write
CREATE POLICY "Public can view deity images"
ON storage.objects FOR SELECT
USING (bucket_id = 'deity-images');

CREATE POLICY "Admins can upload deity images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'deity-images' AND
  auth.uid() IN (
    SELECT id FROM auth.users 
    WHERE raw_user_meta_data->>'role' = 'admin'
  )
);
```

---

## 📡 API Specifications

### Admin Mantra Service (`lib/features/admin/services/admin_mantra_service.dart`)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/ramnam_lekhan/models/mantra_model.dart';
import '../../core/services/auth_service.dart';

class AdminMantraService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  // ==========================================
  // ADMIN CRUD OPERATIONS
  // ==========================================

  /// Get ALL mantras (including inactive) - ADMIN ONLY
  Future<List<MantraModel>> getAllMantrasAdmin() async {
    try {
      final response = await _supabase
          .from('mantra_master_collection')
          .select()
          .order('display_order', ascending: true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MantraModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching all mantras (admin): $e');
      rethrow;
    }
  }

  /// Create new mantra - ADMIN ONLY
  Future<MantraModel> createMantra(MantraModel mantra) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final data = mantra.toJson();
      data['created_by'] = userId;
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('mantra_master_collection')
          .insert(data)
          .select()
          .single();

      print('✅ Mantra created successfully: ${response['id']}');
      return MantraModel.fromJson(response);
    } catch (e) {
      print('❌ Error creating mantra: $e');
      rethrow;
    }
  }

  /// Update existing mantra - ADMIN ONLY
  Future<MantraModel> updateMantra(String id, MantraModel mantra) async {
    try {
      final data = mantra.toJson();
      data.remove('created_by'); // Don't update creator
      data.remove('created_at'); // Don't update creation time

      final response = await _supabase
          .from('mantra_master_collection')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      print('✅ Mantra updated successfully: $id');
      return MantraModel.fromJson(response);
    } catch (e) {
      print('❌ Error updating mantra: $e');
      rethrow;
    }
  }

  /// Delete mantra - ADMIN ONLY
  Future<void> deleteMantra(String id) async {
    try {
      await _supabase
          .from('mantra_master_collection')
          .delete()
          .eq('id', id);

      print('✅ Mantra deleted successfully: $id');
    } catch (e) {
      print('❌ Error deleting mantra: $e');
      rethrow;
    }
  }

  /// Toggle mantra active status - ADMIN ONLY
  Future<void> toggleMantraStatus(String id, bool isActive) async {
    try {
      await _supabase
          .from('mantra_master_collection')
          .update({'is_active': isActive})
          .eq('id', id);

      print('✅ Mantra status toggled: $id → $isActive');
    } catch (e) {
      print('❌ Error toggling mantra status: $e');
      rethrow;
    }
  }

  /// Bulk update display order - ADMIN ONLY
  Future<void> updateDisplayOrders(Map<String, int> orderMap) async {
    try {
      for (var entry in orderMap.entries) {
        await _supabase
            .from('mantra_master_collection')
            .update({'display_order': entry.value})
            .eq('id', entry.key);
      }
      print('✅ Display orders updated successfully');
    } catch (e) {
      print('❌ Error updating display orders: $e');
      rethrow;
    }
  }

  /// Search mantras - ADMIN ONLY
  Future<List<MantraModel>> searchMantras(String query) async {
    try {
      final response = await _supabase
          .from('mantra_master_collection')
          .select()
          .or('mantra_en.ilike.%$query%,mantra_hi.ilike.%$query%,category.ilike.%$query%')
          .order('display_order', ascending: true);

      return (response as List)
          .map((json) => MantraModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error searching mantras: $e');
      return [];
    }
  }

  /// Filter mantras by multiple criteria - ADMIN ONLY
  Future<List<MantraModel>> filterMantras({
    String? category,
    String? deityId,
    String? difficultyLevel,
    bool? isActive,
  }) async {
    try {
      var query = _supabase
          .from('mantra_master_collection')
          .select();

      if (category != null) query = query.eq('category', category);
      if (deityId != null) query = query.eq('deity_id', deityId);
      if (difficultyLevel != null) query = query.eq('difficulty_level', difficultyLevel);
      if (isActive != null) query = query.eq('is_active', isActive);

      final response = await query.order('display_order', ascending: true);

      return (response as List)
          .map((json) => MantraModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error filtering mantras: $e');
      return [];
    }
  }
}
```

### Admin Deity Service (`lib/features/admin/services/admin_deity_service.dart`)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/ramnam_lekhan/models/deity_model.dart';
import '../../core/services/auth_service.dart';
import 'dart:io';

class AdminDeityService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  // ==========================================
  // ADMIN CRUD OPERATIONS
  // ==========================================

  /// Get ALL deities (including inactive) - ADMIN ONLY
  Future<List<DeityModel>> getAllDeitiesAdmin() async {
    try {
      final response = await _supabase
          .from('deities')
          .select()
          .order('display_order', ascending: true)
          .order('english_name', ascending: true);

      return (response as List)
          .map((json) => DeityModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching all deities (admin): $e');
      rethrow;
    }
  }

  /// Create new deity - ADMIN ONLY
  Future<DeityModel> createDeity(DeityModel deity) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final data = deity.toJson();
      data['created_by'] = userId;
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('deities')
          .insert(data)
          .select()
          .single();

      print('✅ Deity created successfully: ${response['id']}');
      return DeityModel.fromJson(response);
    } catch (e) {
      print('❌ Error creating deity: $e');
      rethrow;
    }
  }

  /// Update existing deity - ADMIN ONLY
  Future<DeityModel> updateDeity(String id, DeityModel deity) async {
    try {
      final data = deity.toJson();
      data.remove('created_by');
      data.remove('created_at');

      final response = await _supabase
          .from('deities')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      print('✅ Deity updated successfully: $id');
      return DeityModel.fromJson(response);
    } catch (e) {
      print('❌ Error updating deity: $e');
      rethrow;
    }
  }

  /// Delete deity - ADMIN ONLY
  Future<void> deleteDeity(String id) async {
    try {
      await _supabase
          .from('deities')
          .delete()
          .eq('id', id);

      print('✅ Deity deleted successfully: $id');
    } catch (e) {
      print('❌ Error deleting deity: $e');
      rethrow;
    }
  }

  /// Upload deity image to Supabase Storage - ADMIN ONLY
  Future<String> uploadDeityImage(String deityId, File imageFile) async {
    try {
      final fileName = '$deityId-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'deity-images/$fileName';

      await _supabase.storage
          .from('deity-images')
          .upload(path, imageFile);

      final imageUrl = _supabase.storage
          .from('deity-images')
          .getPublicUrl(path);

      print('✅ Image uploaded: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('❌ Error uploading deity image: $e');
      rethrow;
    }
  }

  /// Toggle deity active status - ADMIN ONLY
  Future<void> toggleDeityStatus(String id, bool isActive) async {
    try {
      await _supabase
          .from('deities')
          .update({'is_active': isActive})
          .eq('id', id);

      print('✅ Deity status toggled: $id → $isActive');
    } catch (e) {
      print('❌ Error toggling deity status: $e');
      rethrow;
    }
  }
}
```

---

## 🎨 UI Components & Screens

### 1. **Mantra List Screen** (`mantra_list_screen.dart`)

**Purpose:** Display all mantras in a searchable, filterable data table.

**Features:**
- ✅ Data table with columns: ID, Mantra (EN), Category, Deity, Difficulty, Active Status, Actions
- ✅ Search bar (search by mantra text or category)
- ✅ Filters: Category dropdown, Deity dropdown, Difficulty dropdown, Active/Inactive toggle
- ✅ Actions: Edit, Delete, Toggle Status
- ✅ "Add New Mantra" button
- ✅ Pagination (50 items per page)
- ✅ Sort by: Display Order, Created Date, Name

**UI Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│  Nam Japa Admin - Mantras                    [+ Add Mantra] │
├─────────────────────────────────────────────────────────────┤
│  🔍 Search: [____________]  Category: [▼]  Deity: [▼]      │
│     Difficulty: [▼]  Status: [Active ▼]                     │
├─────────────────────────────────────────────────────────────┤
│  ID    | Mantra (EN)       | Category | Deity  | Diff | ✓  │
│  ───────────────────────────────────────────────────────────│
│  abc1  | Om Namah Shivaya  | Shiv     | Shiv   | Easy | ✓  │
│  abc2  | Jai Shri Ram      | Ram      | Ram    | Easy | ✓  │
│  ...                                                         │
├─────────────────────────────────────────────────────────────┤
│  Showing 1-50 of 234        < 1 2 3 4 5 >                  │
└─────────────────────────────────────────────────────────────┘
```

**Implementation:**
```dart
class MantraListScreen extends StatefulWidget {
  @override
  _MantraListScreenState createState() => _MantraListScreenState();
}

class _MantraListScreenState extends State<MantraListScreen> {
  final AdminMantraService _mantraService = AdminMantraService();
  List<MantraModel> _mantras = [];
  List<MantraModel> _filteredMantras = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedDeityId;
  String? _selectedDifficulty;
  bool? _filterActive;

  @override
  void initState() {
    super.initState();
    _loadMantras();
  }

  Future<void> _loadMantras() async {
    setState(() => _isLoading = true);
    try {
      final mantras = await _mantraService.getAllMantrasAdmin();
      setState(() {
        _mantras = mantras;
        _applyFilters();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading mantras: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredMantras = _mantras.where((mantra) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        if (!mantra.mantra.toLowerCase().contains(_searchQuery.toLowerCase()) &&
            !mantra.hindiMantra.contains(_searchQuery) &&
            !mantra.category.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      // Apply category filter
      if (_selectedCategory != null && mantra.category != _selectedCategory) {
        return false;
      }
      // Apply deity filter
      if (_selectedDeityId != null && mantra.deityId != _selectedDeityId) {
        return false;
      }
      // Apply difficulty filter
      if (_selectedDifficulty != null && 
          mantra.difficultyLevel.name != _selectedDifficulty) {
        return false;
      }
      // Apply active status filter
      if (_filterActive != null && mantra.isActive != _filterActive) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mantras Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/admin/mantra/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search mantras...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    // Category dropdown
                    // Deity dropdown
                    // Difficulty dropdown
                    // Active status toggle
                  ],
                ),
              ],
            ),
          ),
          // Data Table
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('Mantra (EN)')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Difficulty')),
                        DataColumn(label: Text('Active')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _filteredMantras.map((mantra) {
                        return DataRow(cells: [
                          DataCell(Text(mantra.mantra)),
                          DataCell(Text(mantra.category)),
                          DataCell(Text(mantra.difficultyLevel.displayName)),
                          DataCell(
                            Switch(
                              value: mantra.isActive,
                              onChanged: (value) => _toggleStatus(mantra.id, value),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _editMantra(mantra),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _deleteMantra(mantra.id),
                                ),
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
```

### 2. **Mantra Form Screen** (`mantra_form_screen.dart`)

**Purpose:** Create or edit a mantra with full bilingual support.

**Features:**
- ✅ Form fields: Mantra (EN/HI), Meaning (EN/HI), Benefits (EN/HI)
- ✅ Category input
- ✅ Deity selection dropdown
- ✅ Difficulty level dropdown
- ✅ Display order input
- ✅ Active status toggle
- ✅ Save & Cancel buttons
- ✅ Validation for required fields

**UI Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│  ← Back    Create New Mantra                                │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  English Content                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Mantra (English) *                                   │   │
│  │ [____________________________________]              │   │
│  │                                                       │   │
│  │ Meaning (English)                                    │   │
│  │ [____________________________________]              │   │
│  │                                                       │   │
│  │ Benefits (English)                                   │   │
│  │ [____________________________________]              │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                               │
│  Hindi Content (हिंदी)                                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ मंत्र (हिंदी) *                                       │   │
│  │ [____________________________________]              │   │
│  │                                                       │   │
│  │ अर्थ (हिंदी)                                          │   │
│  │ [____________________________________]              │   │
│  │                                                       │   │
│  │ लाभ (हिंदी)                                           │   │
│  │ [____________________________________]              │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                               │
│  Categorization                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Category: [Ram          ▼]                           │   │
│  │ Deity:    [Lord Ram     ▼]                           │   │
│  │ Difficulty: [Easy       ▼]                           │   │
│  │ Display Order: [0]                                   │   │
│  │ Active: [✓]                                          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                               │
│  [Cancel]                                    [Save Mantra]  │
└─────────────────────────────────────────────────────────────┘
```

### 3. **Deity List Screen** (`deity_list_screen.dart`)

**Purpose:** Display and manage all deities.

**Features:**
- ✅ Card/Grid view with deity images
- ✅ Search bar
- ✅ Actions: Edit, Delete, Toggle Status
- ✅ "Add New Deity" button
- ✅ Visual indicators for active/inactive status

### 4. **Deity Form Screen** (`deity_form_screen.dart`)

**Purpose:** Create or edit deity information.

**Features:**
- ✅ Name fields (EN/HI)
- ✅ Description fields (EN/HI)
- ✅ Icon picker/input
- ✅ Image upload (with preview)
- ✅ Color picker (array of colors)
- ✅ Display order
- ✅ Active status toggle

---

## 🔐 Security & Authentication

### Admin Role Check

**Middleware/Guard:**
```dart
class AdminGuard {
  static bool isAdmin(User? user) {
    if (user == null) return false;
    final metadata = user.userMetadata;
    return metadata?['role'] == 'admin';
  }

  static void requireAdmin(BuildContext context, User? user) {
    if (!isAdmin(user)) {
      Navigator.pushReplacementNamed(context, '/unauthorized');
      throw Exception('Unauthorized: Admin access required');
    }
  }
}
```

**Usage in Routes:**
```dart
case '/admin/mantras':
  AdminGuard.requireAdmin(context, AuthService().currentUser);
  return MaterialPageRoute(builder: (_) => MantraListScreen());
```

---

## 🧪 Testing & Validation

### Form Validation Rules

**Mantra Form:**
- `mantra_en`: Required, min 3 characters
- `mantra_hi`: Required, min 3 characters
- `category`: Required
- `difficulty_level`: Required (easy/medium/difficult)
- `display_order`: Integer, >= 0

**Deity Form:**
- `english_name`: Required, unique, min 2 characters
- `hindi_name`: Required, min 2 characters
- `colors`: Array, at least 1 color
- `display_order`: Integer, >= 0

---

## 📦 Step-by-Step Implementation

### Phase 1: Backend Setup (Supabase)

1. ✅ **Database Tables:** Already exist (`mantra_master_collection`, `deities`)
2. ⚙️ **RLS Policies:** Add admin policies (see Backend Requirements section)
3. ⚙️ **Storage Bucket:** Create `deity-images` bucket
4. ⚙️ **Functions:** Add `update_updated_at_column()` trigger
5. ⚙️ **Admin Users:** Set `role = 'admin'` in user metadata

### Phase 2: Services Layer

1. ✅ Create `lib/features/admin/services/admin_mantra_service.dart`
2. ✅ Create `lib/features/admin/services/admin_deity_service.dart`
3. ✅ Add CRUD methods (create, read, update, delete)
4. ✅ Add helper methods (search, filter, toggle status)

### Phase 3: UI Screens

1. ✅ Create `lib/features/admin/screens/admin_dashboard_screen.dart`
2. ✅ Create mantra management screens:
   - `mantra_list_screen.dart`
   - `mantra_form_screen.dart`
3. ✅ Create deity management screens:
   - `deity_list_screen.dart`
   - `deity_form_screen.dart`

### Phase 4: Routing & Navigation

1. ✅ Add admin routes to `lib/routes.dart`:
```dart
static const String adminDashboard = '/admin/dashboard';
static const String adminMantras = '/admin/mantras';
static const String adminMantraCreate = '/admin/mantra/create';
static const String adminMantraEdit = '/admin/mantra/edit';
static const String adminDeities = '/admin/deities';
static const String adminDeityCreate = '/admin/deity/create';
static const String adminDeityEdit = '/admin/deity/edit';
```

### Phase 5: Authentication & Guards

1. ✅ Implement `AdminGuard` class
2. ✅ Add route protection
3. ✅ Create unauthorized screen

### Phase 6: Testing

1. ✅ Test CRUD operations for mantras
2. ✅ Test CRUD operations for deities
3. ✅ Test search & filter functionality
4. ✅ Test image upload
5. ✅ Test admin role verification
6. ✅ Test RLS policies

---

## 🔄 Integration with Existing Code

### 1. **Mantra Service** (Read-Only → Read-Write)

**Current:** `lib/core/services/mantra_service.dart` has READ operations only.

**Enhancement:** Keep existing service for public users, create separate `AdminMantraService` for admin operations.

### 2. **Deity Service** (Read-Only → Read-Write)

**Current:** `lib/core/services/deity_service.dart` has READ operations only.

**Enhancement:** Keep existing service, create separate `AdminDeityService` for admin operations.

### 3. **Auth Service Integration**

**Usage:**
```dart
final userId = AuthService().currentUser?.id;
final isAdmin = AdminGuard.isAdmin(AuthService().currentUser);
```

### 4. **Language Service Integration**

**Usage:**
```dart
final languageService = Provider.of<LanguageService>(context);
final isHindi = languageService.isHindi;

// Display appropriate field
Text(isHindi ? mantra.hindiMantra : mantra.mantra)
```

---

## 📊 Data Flow Diagram

```
┌──────────────────┐
│  Admin UI        │
│  (Flutter)       │
└────────┬─────────┘
         │
         │ CRUD Operations
         ↓
┌──────────────────┐
│ Admin Services   │
│ - AdminMantraService
│ - AdminDeityService
└────────┬─────────┘
         │
         │ Supabase Client
         ↓
┌──────────────────┐
│  Supabase        │
│  Backend         │
├──────────────────┤
│ • PostgreSQL DB  │
│ • RLS Policies   │
│ • Storage        │
│ • Auth           │
└──────────────────┘
```

---

## 🎯 Key Takeaways

1. **Separation of Concerns:** Public-facing services remain read-only; admin services handle write operations.
2. **Security First:** Use RLS policies and admin guards to protect sensitive operations.
3. **Bilingual Support:** All content forms support both English and Hindi.
4. **Reuse Existing Models:** Leverage `MantraModel` and `DeityModel` already in the codebase.
5. **Supabase Backend:** All data operations go through Supabase (no custom backend needed).

---

## 📞 Support & References

- **Supabase Docs:** https://supabase.com/docs
- **Flutter Provider:** https://pub.dev/packages/provider
- **Existing Services:** `lib/core/services/mantra_service.dart`, `deity_service.dart`
- **Existing Models:** `lib/features/ramnam_lekhan/models/`

---

**Document Version:** 1.0  
**Last Updated:** January 21, 2026  
**Author:** Development Team

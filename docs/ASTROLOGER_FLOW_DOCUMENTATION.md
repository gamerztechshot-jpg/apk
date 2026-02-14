# Astrologer Section - Database Tables & Flow Documentation

## Overview
This document explains the database tables used for the astrologer section and the complete data flow from UI to database.

---

## Database Tables

### 1. Primary Table: `astrologers`
**Purpose**: Stores all astrologer information and profile data.

**Key Columns**:
- `id` (UUID) - Primary key
- `name` (VARCHAR) - Astrologer name
- `name_hi` (VARCHAR) - Astrologer name (Hindi)
- `email` (VARCHAR) - Unique email
- `email_hi` (VARCHAR) - Email (Hindi, optional)
- `phone_number` (VARCHAR) - Contact number
- `phone_number_hi` (VARCHAR) - Contact number (Hindi, optional)
- `qualification` (TEXT) - Educational qualifications
- `qualification_hi` (TEXT) - Educational qualifications (Hindi)
- `experience` (INTEGER) - Experience in months
- `experience_hi` (TEXT) - Experience display text (Hindi, optional)
- `about_you` (TEXT) - Bio/description
- `about_you_hi` (TEXT) - Bio/description (Hindi)
- `address` (TEXT) - Location
- `address_hi` (TEXT) - Location (Hindi)
- `photo_url` (TEXT) - Profile photo URL
- `photo_url_hi` (TEXT) - Profile photo URL (Hindi, optional)
- `per_minute_charge` (DECIMAL) - Per minute consultation charge
- `per_hour_charge` (DECIMAL) - Per hour consultation charge
- `per_month_charge` (DECIMAL) - Monthly subscription charge
- `is_active` (BOOLEAN) - Active status flag
- `priority` (DECIMAL) - Sorting/ranking priority (1-10 scale)
- `rating` (DECIMAL) - Average rating (calculated from reviews)
- `specializations` (TEXT[]) - Array of specializations
- `languages` (TEXT[]) - Array of languages spoken
- `availability_schedule` (JSONB) - Availability schedule in JSON format
- `created_at` (TIMESTAMP) - Creation timestamp
- `updated_at` (TIMESTAMP) - Last update timestamp

**Indexes**:
- `idx_astrologers_is_active` - For filtering active astrologers
- `idx_astrologers_priority` - For priority-based sorting
- `idx_astrologers_experience` - For experience-based sorting
- `idx_astrologers_per_minute_charge` - For price filtering

---

### 2. Related Table: `astrologer_reviews`
**Purpose**: Stores user reviews and ratings for astrologers.

**Key Columns**:
- `id` (UUID) - Primary key
- `astrologer_id` (UUID) - Foreign key to `astrologers.id`
- `user_id` (UUID) - Foreign key to `auth.users.id`
- `rating` (INTEGER) - Rating from 1-5
- `review_text` (TEXT) - Review comment
- `consultation_type` (VARCHAR) - Type: 'video_call', 'phone_call', 'chat', 'in_person'
- `consultation_duration` (INTEGER) - Duration in minutes
- `is_verified` (BOOLEAN) - Verified consultation flag
- `created_at` (TIMESTAMP) - Review timestamp
- `updated_at` (TIMESTAMP) - Last update timestamp

**Constraints**:
- Unique constraint on `(astrologer_id, user_id)` - One review per user per astrologer
- Rating check constraint: `rating >= 1 AND rating <= 5`

**Indexes**:
- `idx_astrologer_reviews_astrologer_id` - For fetching reviews by astrologer
- `idx_astrologer_reviews_user_id` - For fetching user's reviews
- `idx_astrologer_reviews_rating` - For rating-based queries
- `idx_astrologer_reviews_created_at` - For chronological sorting

---

### 3. Related Table: `astrologer_bookings`
**Purpose**: Stores booking/consultation records.

**Key Columns**:
- `id` (UUID) - Primary key
- `astrologer_id` (UUID) - Foreign key to `astrologers.id`
- `user_id` (UUID) - Foreign key to `auth.users.id`
- `booking_type` (VARCHAR) - 'per_minute' or 'per_month'
- `minutes_booked` (INTEGER) - Minutes booked (for per_minute bookings)
- `communication_mode` (VARCHAR) - 'chat' or 'call'
- `total_amount` (DECIMAL) - Total booking amount
- `payment_status` (VARCHAR) - 'pending', 'paid', 'refunded'
- `booking_status` (VARCHAR) - 'pending', 'confirmed', 'completed', 'cancelled', 'no_show'
- `payment_info` (JSONB) - Payment details (Razorpay payment_id, order_id)
- `customer_info` (JSONB) - Customer details (name, email, phone)
- `scheduled_time` (TIMESTAMP) - Scheduled consultation time
- `consultation_notes` (TEXT) - Consultation notes
- `created_at` (TIMESTAMP) - Booking timestamp
- `updated_at` (TIMESTAMP) - Last update timestamp

**Indexes**:
- `idx_astrologer_bookings_astrologer_id` - For fetching astrologer's bookings
- `idx_astrologer_bookings_user_id` - For fetching user's bookings
- `idx_astrologer_bookings_status` - For filtering by status
- `idx_astrologer_bookings_scheduled_time` - For time-based queries

---

### 4. Related Table: `kundli_types`
**Purpose**: Stores available Kundli report types.

**Key Columns**:
- `id` (UUID) - Primary key
- `name` (VARCHAR) - Kundli type name
- `description` (TEXT) - Description
- `is_active` (BOOLEAN) - Active status
- `created_at` (TIMESTAMP) - Creation timestamp

---

### 5. Related Table: `astrologer_availability`
**Purpose**: Stores astrologer availability schedule.

**Key Columns**:
- `id` (UUID) - Primary key
- `astrologer_id` (UUID) - Foreign key to `astrologers.id`
- `day_of_week` (INTEGER) - 0=Sunday, 1=Monday, etc.
- `start_time` (TIME) - Start time
- `end_time` (TIME) - End time
- `is_available` (BOOLEAN) - Availability flag
- `created_at` (TIMESTAMP) - Creation timestamp
- `updated_at` (TIMESTAMP) - Last update timestamp

---

## Database Functions & Views

### Functions:
1. **`get_astrologer_avg_rating(astrologer_uuid UUID)`**
   - Calculates average rating from `astrologer_reviews` table
   - Returns DECIMAL(3,2)

2. **`get_astrologer_reviews_count(astrologer_uuid UUID)`**
   - Counts total reviews for an astrologer
   - Returns INTEGER

### Views:
1. **`astrologers_with_ratings`**
   - Combines `astrologers` table with calculated ratings and review counts
   - Includes `average_rating` and `total_reviews` columns
   - Includes `display_price` calculated field

---

## Complete Data Flow

### Architecture Pattern: Repository → ViewModel → UI

```
UI Layer (Screens/Widgets)
    ↓
ViewModel Layer (State Management)
    ↓
Repository Layer (Data Access)
    ↓
Supabase Client (Database)
    ↓
PostgreSQL Database (Tables)
```

---

## Detailed Flow Breakdown

### 1. **Initialization Flow** (Screen Load)

**File**: `lib/features/astro/views/astrologer_screen.dart`

```
User opens Astrologer Screen
    ↓
initState() calls AstrologerViewModel.initializeData()
    ↓
AstrologerViewModel.initializeData()
    ├─→ Tests database connection (astrologers table)
    ├─→ loadAstrologers() - Fetches all active astrologers
    └─→ loadKundliTypes() - Fetches all active kundli types
    ↓
AstrologerRepository.getAstrologers()
    ↓
Supabase Query:
    SELECT * FROM astrologers
    WHERE is_active = true
    ORDER BY priority ASC NULLS FIRST,
             rating DESC NULLS LAST
    ↓
Response parsed into List<AstrologerModel>
    ↓
ViewModel stores data and notifies listeners
    ↓
UI rebuilds with astrologer data
```

**SQL Query Used**:
```sql
SELECT * 
FROM astrologers 
WHERE is_active = true 
ORDER BY priority ASC NULLS FIRST, 
         rating DESC NULLS LAST
```

---

### 2. **Fetching Astrologers Flow**

**File**: `lib/features/astro/reposistries/astrologer_repository.dart`

**Method**: `getAstrologers({int? limit})`

**Steps**:
1. Build Supabase query on `astrologers` table
2. Filter: `is_active = true`
3. Sort: `priority ASC` (nulls first), then `rating DESC`
4. Apply limit if provided
5. Execute query
6. Map JSON response to `AstrologerModel` objects
7. Return list of astrologers

**Query Example**:
```dart
_supabase
  .from('astrologers')
  .select('*')
  .eq('is_active', true)
  .order('priority', ascending: true, nullsFirst: true)
  .order('rating', ascending: false, nullsFirst: false)
  .limit(limit)
```

---

### 3. **Search Astrologers Flow**

**File**: `lib/features/astro/reposistries/astrologer_repository.dart`

**Method**: `searchAstrologers(String query)`

**Steps**:
1. Build Supabase query on `astrologers` table
2. Filter: `is_active = true`
3. Search: `name ILIKE %query% OR qualification ILIKE %query%`
4. Sort: `priority DESC`
5. Execute query
6. Map to `AstrologerModel` objects

**Query Example**:
```dart
_supabase
  .from('astrologers')
  .select()
  .eq('is_active', true)
  .or('name.ilike.%$query%,qualification.ilike.%$query%')
  .order('priority', ascending: false)
```

---

### 4. **Get Single Astrologer Flow**

**File**: `lib/features/astro/reposistries/astrologer_repository.dart`

**Method**: `getAstrologerById(String id)`

**Steps**:
1. Query `astrologers` table by ID
2. Filter: `is_active = true`
3. Get single record
4. Map to `AstrologerModel`

**Query Example**:
```dart
_supabase
  .from('astrologers')
  .select()
  .eq('id', id)
  .eq('is_active', true)
  .single()
```

---

### 5. **Top Astrologers Flow** (For Home Display)

**File**: `lib/features/astro/viewmodels/astrologer_viewmodel.dart`

**Getter**: `topAstrologers`

**Steps**:
1. Filter astrologers where `priority >= 1 AND priority <= 3`
2. Sort by `priority` ascending
3. Take first 3 astrologers
4. Return filtered list

**Logic**:
```dart
_astrologers
  .where((a) => a.priority != null && a.priority! >= 1 && a.priority! <= 3)
  .toList()
  ..sort((a, b) => a.priority!.compareTo(b.priority!))
  .take(3)
```

---

### 6. **Booking Flow**

**File**: `lib/features/astro/views/astrologer_detail_screen.dart`

**Steps**:
1. User selects booking type (per_minute or per_month)
2. If per_minute: User enters minutes and selects communication mode
3. Calculate total amount based on charges
4. Initiate payment via Razorpay
5. On payment success:
   - Save booking to `astrologer_bookings` table
   - Store payment info (payment_id, order_id)
   - Store customer info (name, email, phone)
   - Set booking_status = 'confirmed'
   - Set payment_status = 'paid'
6. Show success message

**Database Insert**:
```dart
_supabase.from('astrologer_bookings').insert({
  'astrologer_id': astrologerId,
  'user_id': userId,
  'booking_type': bookingType, // 'per_minute' or 'per_month'
  'minutes_booked': minutesBooked,
  'communication_mode': communicationMode, // 'chat' or 'call'
  'total_amount': totalAmount,
  'payment_status': 'paid',
  'booking_status': 'confirmed',
  'payment_info': {
    'razorpay_payment_id': paymentId,
    'order_id': orderId
  },
  'customer_info': {
    'name': customerName,
    'email': customerEmail,
    'phone': customerPhone
  }
})
```

---

### 7. **Your Astrologers Flow** (Booked Astrologers)

**File**: `lib/features/astro/views/your_astrologers_screen.dart`

**Steps**:
1. Get current user ID
2. Query `astrologer_bookings` table with join to `astrologers`
3. Filter: `user_id = current_user_id AND booking_status = 'confirmed'`
4. Sort by astrologer priority
5. Display booked astrologers with contact options

**Query Example**:
```dart
_supabase
  .from('astrologer_bookings')
  .select('''
    *,
    astrologers:astrologer_id (
      id, name, photo_url, qualification,
      rating, experience, address, phone_number, priority
    )
  ''')
  .eq('user_id', user.id)
  .eq('booking_status', 'confirmed')
  .order('astrologers.priority', ascending: true)
```

---

### 8. **Kundli Types Flow**

**File**: `lib/features/astro/reposistries/astrologer_repository.dart`

**Method**: `getKundliTypes()`

**Steps**:
1. Query `kundli_types` table
2. Filter: `is_active = true`
3. Sort: `created_at DESC`
4. Map to `KundliTypeModel` objects

**Query Example**:
```dart
_supabase
  .from('kundli_types')
  .select()
  .eq('is_active', true)
  .order('created_at', ascending: false)
```

---

## Caching Mechanism

**File**: `lib/features/astro/viewmodels/astrologer_viewmodel.dart`

**Cache Strategy**:
- Cache duration: **10 minutes**
- Cache validation: Checks if data was fetched within last 10 minutes
- Force refresh: Can bypass cache with `forceRefresh: true`

**Cache Methods**:
- `_isAstrologersCacheValid()` - Validates astrologers cache
- `_isKundliTypesCacheValid()` - Validates kundli types cache
- `clearCache()` - Clears all cached data
- `clearAstrologersCache()` - Clears astrologers cache only
- `clearKundliTypesCache()` - Clears kundli types cache only

---

## Row Level Security (RLS) Policies

### `astrologers` Table:
- **SELECT**: Anyone can view active astrologers (`is_active = true`)
- **ALL**: Only admins can manage (insert/update/delete)

### `astrologer_reviews` Table:
- **SELECT**: Anyone can view reviews
- **INSERT**: Users can insert their own reviews
- **UPDATE**: Users can update their own reviews
- **DELETE**: Users can delete their own reviews

### `astrologer_bookings` Table:
- **SELECT**: Users can view their own bookings
- **INSERT**: Users can insert their own bookings
- **UPDATE**: Users can update their own bookings

### `astrologer_availability` Table:
- **SELECT**: Anyone can view availability
- **ALL**: Only admins can manage availability

---

## Key Files & Their Roles

### Repository Layer
- **File**: `lib/features/astro/reposistries/astrologer_repository.dart`
- **Role**: Direct database access, query building, data mapping
- **Methods**:
  - `getAstrologers()` - Fetch all active astrologers
  - `getAstrologerById()` - Fetch single astrologer
  - `searchAstrologers()` - Search by name/qualification
  - `getKundliTypes()` - Fetch kundli types
  - `bookAstrologer()` - Create booking record
  - `downloadKundliReport()` - Record kundli download

### ViewModel Layer
- **File**: `lib/features/astro/viewmodels/astrologer_viewmodel.dart`
- **Role**: State management, caching, business logic
- **Methods**:
  - `initializeData()` - Initialize with cache support
  - `loadAstrologers()` - Load with caching
  - `loadKundliTypes()` - Load kundli types
  - `searchAstrologers()` - Search functionality
  - `bookAstrologer()` - Booking logic
  - `refresh()` - Force refresh data

### Model Layer
- **File**: `lib/features/astro/models/astrologer_model.dart`
- **Role**: Data structure, JSON parsing, display helpers
- **Key Methods**:
  - `fromJson()` - Parse database JSON
  - `getDisplayPrice()` - Format price display
  - `getRatingDisplay()` - Format rating display
  - `getExperienceDisplay()` - Format experience
  - `getQualificationDisplay()` - Format qualification

### UI Layer
- **Files**:
  - `lib/features/astro/views/astrologer_screen.dart` - Main screen
  - `lib/features/astro/views/view_all_astrologers_screen.dart` - All astrologers list
  - `lib/features/astro/views/astrologer_detail_screen.dart` - Detail & booking
  - `lib/features/astro/views/your_astrologers_screen.dart` - User's booked astrologers
  - `lib/features/astro/views/widgets/astrologer_card.dart` - Card widget
  - `lib/features/astro/views/widgets/astrologer_list_section.dart` - List section

---

## Summary

**Main Table**: `astrologers` - Stores all astrologer profile data

**Complete Flow**:
1. UI calls ViewModel method
2. ViewModel checks cache (10 min expiry)
3. If cache invalid, ViewModel calls Repository
4. Repository builds Supabase query
5. Query executes on `astrologers` table
6. Response mapped to `AstrologerModel`
7. ViewModel stores data and notifies listeners
8. UI rebuilds with new data

**Key Features**:
- ✅ Caching for performance (10 min cache)
- ✅ Priority-based sorting
- ✅ Rating-based sorting
- ✅ Search functionality
- ✅ Active status filtering
- ✅ Booking system integration
- ✅ Review system integration
- ✅ RLS security policies

# Admin Leaderboard & Sadhna Profile System - Complete Documentation

## 📋 Table of Contents

1. [Overview](#overview)
2. [Database Schema & RPC Functions](#database-schema--rpc-functions)
3. [Frontend Architecture](#frontend-architecture)
4. [Backend Requirements](#backend-requirements)
5. [API Specifications](#api-specifications)
6. [UI Components & Screens](#ui-components--screens)
7. [Integration Guide](#integration-guide)
8. [Step-by-Step Implementation](#step-by-step-implementation)
9. [Security & Authentication](#security--authentication)
10. [Data Analytics & Insights](#data-analytics--insights)

---

## 📖 Overview

The **Admin Leaderboard & Sadhna Profile System** is a comprehensive admin dashboard that allows administrators to:

- ✅ **View ALL users' leaderboard rankings** across all time periods (Daily, Weekly, Monthly, Yearly, All-Time)
- ✅ **View ALL users' Sadhna profiles** with complete statistics
- ✅ **Search and filter users** by name, email, japa count, streak, etc.
- ✅ **Analyze user engagement** metrics and trends
- ✅ **Export user data** for reporting
- ✅ **View detailed user statistics** including:
  - Total Japa Count
  - Current Streak
  - Longest Streak
  - Days Active
  - Leaderboard Rankings
  - Certificate Achievements
  - Activity History

### Key Differences from User View

| Feature | User View | Admin View |
|---------|-----------|------------|
| **Scope** | Current user only | ALL users |
| **Leaderboard** | Shows top users + current user rank | Shows ALL users with full rankings |
| **Profile** | Own sadhna profile | Any user's sadhna profile |
| **Search** | N/A | Search by name, email, user ID |
| **Filters** | Time period only | Multiple filters (streak, japa count, date range) |
| **Export** | N/A | Export to CSV/Excel |
| **Analytics** | Personal stats | Platform-wide analytics |

---

## 🗄️ Database Schema & RPC Functions

### Existing Supabase RPC Functions

The system uses the following Supabase RPC functions (already implemented):

#### 1. **Leaderboard Functions**

```sql
-- Get daily leaderboard
get_daily_leaderboard(p_date DATE)

-- Get weekly leaderboard  
get_weekly_leaderboard(p_date DATE)

-- Get monthly leaderboard
get_monthly_leaderboard(p_date DATE)

-- Get yearly leaderboard
get_yearly_leaderboard(p_date DATE)

-- Get all-time leaderboard
get_alltime_leaderboard()

-- Get leaderboard participant count
get_leaderboard_participant_count(p_leaderboard_type TEXT, p_date DATE)

-- Get user's rank in leaderboard
get_user_leaderboard_rank(p_leaderboard_type TEXT, p_date DATE)
```

**Response Format:**
```json
[
  {
    "rank": 1,
    "user_id": "uuid",
    "username": "User Name",
    "japa_count": 1080,
    "is_current_user": false
  }
]
```

#### 2. **User Statistics Function**

```sql
-- Get comprehensive user japa statistics
get_user_japa_statistics(p_user_id TEXT)
```

**Response Format:**
```json
{
  "total_japa_count": 10800,
  "total_active_days": 100,
  "today_japa_count": 108,
  "current_streak": 7,
  "longest_streak": 30,
  "first_japa_date": "2024-01-01",
  "last_japa_date": "2024-12-31"
}
```

### Required New Admin RPC Functions

#### 1. **Get All Users Leaderboard** (Admin Only)

```sql
CREATE OR REPLACE FUNCTION get_all_users_leaderboard_admin(
  p_leaderboard_type TEXT DEFAULT 'daily',
  p_date DATE DEFAULT CURRENT_DATE,
  p_limit INTEGER DEFAULT 100,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  rank BIGINT,
  user_id TEXT,
  username TEXT,
  email TEXT,
  japa_count INTEGER,
  created_at TIMESTAMPTZ,
  last_active TIMESTAMPTZ
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if user is admin
  IF NOT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = auth.uid() 
    AND raw_user_meta_data->>'role' = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  RETURN QUERY
  WITH ranked_users AS (
    SELECT 
      ROW_NUMBER() OVER (ORDER BY japa_count DESC) as rnk,
      user_id,
      username,
      email,
      japa_count,
      created_at,
      last_active
    FROM (
      -- Query based on leaderboard type
      SELECT 
        u.id as user_id,
        COALESCE(u.raw_user_meta_data->>'name', u.email) as username,
        u.email,
        COUNT(j.id) as japa_count,
        u.created_at::TIMESTAMPTZ as created_at,
        MAX(j.created_at) as last_active
      FROM auth.users u
      LEFT JOIN user_japa_logs j ON j.user_id = u.id::TEXT
      WHERE 
        CASE p_leaderboard_type
          WHEN 'daily' THEN DATE(j.created_at) = p_date
          WHEN 'weekly' THEN DATE_TRUNC('week', j.created_at) = DATE_TRUNC('week', p_date::TIMESTAMP)
          WHEN 'monthly' THEN DATE_TRUNC('month', j.created_at) = DATE_TRUNC('month', p_date::TIMESTAMP)
          WHEN 'yearly' THEN DATE_TRUNC('year', j.created_at) = DATE_TRUNC('year', p_date::TIMESTAMP)
          WHEN 'alltime' THEN TRUE
          ELSE DATE(j.created_at) = p_date
        END
      GROUP BY u.id, u.email, u.raw_user_meta_data, u.created_at
    ) user_stats
  )
  SELECT 
    rnk::BIGINT,
    user_id::TEXT,
    username::TEXT,
    email::TEXT,
    japa_count::INTEGER,
    created_at,
    last_active
  FROM ranked_users
  ORDER BY rnk
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;
```

#### 2. **Get All Users Statistics** (Admin Only)

```sql
CREATE OR REPLACE FUNCTION get_all_users_statistics_admin(
  p_limit INTEGER DEFAULT 100,
  p_offset INTEGER DEFAULT 0,
  p_search TEXT DEFAULT NULL,
  p_min_japa_count INTEGER DEFAULT NULL,
  p_min_streak INTEGER DEFAULT NULL
)
RETURNS TABLE (
  user_id TEXT,
  username TEXT,
  email TEXT,
  total_japa_count INTEGER,
  total_active_days INTEGER,
  current_streak INTEGER,
  longest_streak INTEGER,
  first_japa_date DATE,
  last_japa_date DATE,
  created_at TIMESTAMPTZ,
  last_login TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if user is admin
  IF NOT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = auth.uid() 
    AND raw_user_meta_data->>'role' = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  RETURN QUERY
  SELECT 
    u.id::TEXT as user_id,
    COALESCE(u.raw_user_meta_data->>'name', u.email) as username,
    u.email::TEXT,
    COALESCE(COUNT(j.id), 0)::INTEGER as total_japa_count,
    COUNT(DISTINCT DATE(j.created_at))::INTEGER as total_active_days,
    -- Calculate current streak (simplified - actual implementation may vary)
    COALESCE(MAX(s.current_streak), 0)::INTEGER as current_streak,
    COALESCE(MAX(s.longest_streak), 0)::INTEGER as longest_streak,
    MIN(DATE(j.created_at)) as first_japa_date,
    MAX(DATE(j.created_at)) as last_japa_date,
    u.created_at::TIMESTAMPTZ,
    u.last_sign_in_at::TIMESTAMPTZ as last_login
  FROM auth.users u
  LEFT JOIN user_japa_logs j ON j.user_id = u.id::TEXT
  LEFT JOIN user_streaks s ON s.user_id = u.id::TEXT
  WHERE 
    (p_search IS NULL OR 
     u.email ILIKE '%' || p_search || '%' OR
     u.raw_user_meta_data->>'name' ILIKE '%' || p_search || '%')
    AND (p_min_japa_count IS NULL OR COUNT(j.id) >= p_min_japa_count)
    AND (p_min_streak IS NULL OR COALESCE(MAX(s.current_streak), 0) >= p_min_streak)
  GROUP BY u.id, u.email, u.raw_user_meta_data, u.created_at, u.last_sign_in_at
  HAVING 
    (p_min_japa_count IS NULL OR COUNT(j.id) >= p_min_japa_count)
    AND (p_min_streak IS NULL OR COALESCE(MAX(s.current_streak), 0) >= p_min_streak)
  ORDER BY total_japa_count DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;
```

#### 3. **Get User Detailed Profile** (Admin Only)

```sql
CREATE OR REPLACE FUNCTION get_user_detailed_profile_admin(p_user_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSONB;
BEGIN
  -- Check if user is admin
  IF NOT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = auth.uid() 
    AND raw_user_meta_data->>'role' = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  SELECT jsonb_build_object(
    'user_id', u.id,
    'username', COALESCE(u.raw_user_meta_data->>'name', u.email),
    'email', u.email,
    'created_at', u.created_at,
    'last_login', u.last_sign_in_at,
    'total_japa_count', COALESCE(COUNT(j.id), 0),
    'total_active_days', COUNT(DISTINCT DATE(j.created_at)),
    'current_streak', COALESCE(MAX(s.current_streak), 0),
    'longest_streak', COALESCE(MAX(s.longest_streak), 0),
    'first_japa_date', MIN(DATE(j.created_at)),
    'last_japa_date', MAX(DATE(j.created_at)),
    'daily_rank', (SELECT rank FROM get_user_leaderboard_rank('daily', CURRENT_DATE) WHERE user_id = p_user_id),
    'weekly_rank', (SELECT rank FROM get_user_leaderboard_rank('weekly', CURRENT_DATE) WHERE user_id = p_user_id),
    'monthly_rank', (SELECT rank FROM get_user_leaderboard_rank('monthly', CURRENT_DATE) WHERE user_id = p_user_id),
    'yearly_rank', (SELECT rank FROM get_user_leaderboard_rank('yearly', CURRENT_DATE) WHERE user_id = p_user_id),
    'alltime_rank', (SELECT rank FROM get_user_leaderboard_rank('alltime', CURRENT_DATE) WHERE user_id = p_user_id),
    'japa_by_mantra', (
      SELECT jsonb_agg(jsonb_build_object(
        'mantra_id', mantra_id,
        'mantra_name', mantra_name,
        'count', count
      ))
      FROM (
        SELECT 
          j.mantra_id,
          m.mantra_en as mantra_name,
          COUNT(*) as count
        FROM user_japa_logs j
        LEFT JOIN mantra_master_collection m ON m.id = j.mantra_id
        WHERE j.user_id = p_user_id
        GROUP BY j.mantra_id, m.mantra_en
        ORDER BY count DESC
        LIMIT 10
      ) mantra_stats
    )
  ) INTO result
  FROM auth.users u
  LEFT JOIN user_japa_logs j ON j.user_id = u.id::TEXT
  LEFT JOIN user_streaks s ON s.user_id = u.id::TEXT
  WHERE u.id::TEXT = p_user_id
  GROUP BY u.id, u.email, u.raw_user_meta_data, u.created_at, u.last_sign_in_at;

  RETURN result;
END;
$$;
```

#### 4. **Get Platform Analytics** (Admin Only)

```sql
CREATE OR REPLACE FUNCTION get_platform_analytics_admin(
  p_start_date DATE DEFAULT NULL,
  p_end_date DATE DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSONB;
  start_date DATE := COALESCE(p_start_date, CURRENT_DATE - INTERVAL '30 days');
  end_date DATE := COALESCE(p_end_date, CURRENT_DATE);
BEGIN
  -- Check if user is admin
  IF NOT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = auth.uid() 
    AND raw_user_meta_data->>'role' = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  SELECT jsonb_build_object(
    'total_users', (SELECT COUNT(*) FROM auth.users),
    'active_users', (SELECT COUNT(DISTINCT user_id) FROM user_japa_logs WHERE DATE(created_at) BETWEEN start_date AND end_date),
    'total_japa_count', (SELECT COALESCE(SUM(count), 0) FROM user_japa_logs WHERE DATE(created_at) BETWEEN start_date AND end_date),
    'average_japa_per_user', (
      SELECT COALESCE(AVG(daily_count), 0)
      FROM (
        SELECT user_id, COUNT(*) as daily_count
        FROM user_japa_logs
        WHERE DATE(created_at) BETWEEN start_date AND end_date
        GROUP BY user_id, DATE(created_at)
      ) daily_stats
    ),
    'top_users', (
      SELECT jsonb_agg(jsonb_build_object(
        'user_id', user_id,
        'username', username,
        'japa_count', japa_count
      ))
      FROM (
        SELECT 
          j.user_id,
          COALESCE(u.raw_user_meta_data->>'name', u.email) as username,
          COUNT(*) as japa_count
        FROM user_japa_logs j
        JOIN auth.users u ON u.id::TEXT = j.user_id
        WHERE DATE(j.created_at) BETWEEN start_date AND end_date
        GROUP BY j.user_id, u.raw_user_meta_data, u.email
        ORDER BY japa_count DESC
        LIMIT 10
      ) top_users
    ),
    'daily_activity', (
      SELECT jsonb_agg(jsonb_build_object(
        'date', date,
        'japa_count', japa_count,
        'active_users', active_users
      ))
      FROM (
        SELECT 
          DATE(created_at) as date,
          COUNT(*) as japa_count,
          COUNT(DISTINCT user_id) as active_users
        FROM user_japa_logs
        WHERE DATE(created_at) BETWEEN start_date AND end_date
        GROUP BY DATE(created_at)
        ORDER BY date
      ) daily_activity
    )
  ) INTO result;

  RETURN result;
END;
$$;
```

### Database Tables (Assumed Structure)

Based on the existing code, these tables should exist:

#### `user_japa_logs`
```sql
CREATE TABLE IF NOT EXISTS user_japa_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL,
  mantra_id TEXT,
  japa_count INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_user_japa_logs_user_id ON user_japa_logs(user_id);
CREATE INDEX idx_user_japa_logs_created_at ON user_japa_logs(created_at);
CREATE INDEX idx_user_japa_logs_mantra_id ON user_japa_logs(mantra_id);
```

#### `user_streaks`
```sql
CREATE TABLE IF NOT EXISTS user_streaks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL UNIQUE,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_activity_date DATE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_user_streaks_user_id ON user_streaks(user_id);
```

---

## 🎨 Frontend Architecture

### File Structure

```
lib/
├── features/
│   └── admin/
│       ├── screens/
│       │   ├── admin_dashboard_screen.dart
│       │   └── leaderboard_sadhna_admin/
│       │       ├── admin_leaderboard_screen.dart        # All users leaderboard
│       │       ├── admin_sadhna_profiles_screen.dart     # All users profiles list
│       │       ├── admin_user_detail_screen.dart        # Individual user detail
│       │       └── admin_analytics_screen.dart          # Platform analytics
│       ├── widgets/
│       │   ├── admin_user_table_widget.dart             # Reusable user data table
│       │   ├── admin_statistics_card.dart               # Stats display card
│       │   ├── admin_leaderboard_table.dart             # Leaderboard table
│       │   └── admin_export_button.dart                 # Export functionality
│       └── services/
│           ├── admin_leaderboard_service.dart           # Admin leaderboard operations
│           └── admin_sadhna_service.dart                # Admin sadhna profile operations
```

### Key Models

#### `AdminUserLeaderboardEntry`
```dart
class AdminUserLeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String email;
  final int japaCount;
  final DateTime createdAt;
  final DateTime? lastActive;

  AdminUserLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.email,
    required this.japaCount,
    required this.createdAt,
    this.lastActive,
  });

  factory AdminUserLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return AdminUserLeaderboardEntry(
      rank: json['rank'] as int,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      japaCount: json['japa_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastActive: json['last_active'] != null 
          ? DateTime.parse(json['last_active'] as String)
          : null,
    );
  }
}
```

#### `AdminUserStatistics`
```dart
class AdminUserStatistics {
  final String userId;
  final String username;
  final String email;
  final int totalJapaCount;
  final int totalActiveDays;
  final int currentStreak;
  final int longestStreak;
  final DateTime? firstJapaDate;
  final DateTime? lastJapaDate;
  final DateTime createdAt;
  final DateTime? lastLogin;

  AdminUserStatistics({
    required this.userId,
    required this.username,
    required this.email,
    required this.totalJapaCount,
    required this.totalActiveDays,
    required this.currentStreak,
    required this.longestStreak,
    this.firstJapaDate,
    this.lastJapaDate,
    required this.createdAt,
    this.lastLogin,
  });

  factory AdminUserStatistics.fromJson(Map<String, dynamic> json) {
    return AdminUserStatistics(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      totalJapaCount: json['total_japa_count'] as int,
      totalActiveDays: json['total_active_days'] as int,
      currentStreak: json['current_streak'] as int,
      longestStreak: json['longest_streak'] as int,
      firstJapaDate: json['first_japa_date'] != null
          ? DateTime.parse(json['first_japa_date'] as String)
          : null,
      lastJapaDate: json['last_japa_date'] != null
          ? DateTime.parse(json['last_japa_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'] as String)
          : null,
    );
  }
}
```

#### `AdminUserDetailedProfile`
```dart
class AdminUserDetailedProfile {
  final String userId;
  final String username;
  final String email;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final int totalJapaCount;
  final int totalActiveDays;
  final int currentStreak;
  final int longestStreak;
  final DateTime? firstJapaDate;
  final DateTime? lastJapaDate;
  final Map<String, int>? ranks; // {'daily': 1, 'weekly': 5, ...}
  final List<MantraStats>? japaByMantra;

  AdminUserDetailedProfile({
    required this.userId,
    required this.username,
    required this.email,
    required this.createdAt,
    this.lastLogin,
    required this.totalJapaCount,
    required this.totalActiveDays,
    required this.currentStreak,
    required this.longestStreak,
    this.firstJapaDate,
    this.lastJapaDate,
    this.ranks,
    this.japaByMantra,
  });

  factory AdminUserDetailedProfile.fromJson(Map<String, dynamic> json) {
    return AdminUserDetailedProfile(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'] as String)
          : null,
      totalJapaCount: json['total_japa_count'] as int,
      totalActiveDays: json['total_active_days'] as int,
      currentStreak: json['current_streak'] as int,
      longestStreak: json['longest_streak'] as int,
      firstJapaDate: json['first_japa_date'] != null
          ? DateTime.parse(json['first_japa_date'] as String)
          : null,
      lastJapaDate: json['last_japa_date'] != null
          ? DateTime.parse(json['last_japa_date'] as String)
          : null,
      ranks: json['ranks'] != null 
          ? Map<String, int>.from(json['ranks'] as Map)
          : null,
      japaByMantra: json['japa_by_mantra'] != null
          ? (json['japa_by_mantra'] as List)
              .map((e) => MantraStats.fromJson(e))
              .toList()
          : null,
    );
  }
}

class MantraStats {
  final String mantraId;
  final String mantraName;
  final int count;

  MantraStats({
    required this.mantraId,
    required this.mantraName,
    required this.count,
  });

  factory MantraStats.fromJson(Map<String, dynamic> json) {
    return MantraStats(
      mantraId: json['mantra_id'] as String,
      mantraName: json['mantra_name'] as String,
      count: json['count'] as int,
    );
  }
}
```

---

## 🔧 Backend Requirements

### Supabase Configuration

#### Row Level Security (RLS) Policies

**For Admin RPC Functions:**
All admin RPC functions use `SECURITY DEFINER` and check admin role internally. No additional RLS policies needed for RPC functions.

**For Direct Table Access (if needed):**
```sql
-- Admin can view all user japa logs
CREATE POLICY "Admins can view all japa logs"
ON user_japa_logs FOR SELECT
USING (
  auth.uid() IN (
    SELECT id FROM auth.users 
    WHERE raw_user_meta_data->>'role' = 'admin'
  )
);

-- Admin can view all user streaks
CREATE POLICY "Admins can view all user streaks"
ON user_streaks FOR SELECT
USING (
  auth.uid() IN (
    SELECT id FROM auth.users 
    WHERE raw_user_meta_data->>'role' = 'admin'
  )
);
```

---

## 📡 API Specifications

### Admin Leaderboard Service (`lib/features/admin/services/admin_leaderboard_service.dart`)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/admin_leaderboard_model.dart';
import '../../../core/services/auth_service.dart';

class AdminLeaderboardService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  /// Get all users leaderboard (Admin Only)
  Future<List<AdminUserLeaderboardEntry>> getAllUsersLeaderboard({
    String period = 'daily',
    DateTime? date,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();
      final dateString = targetDate.toIso8601String().split('T')[0];

      final response = await _supabase.rpc(
        'get_all_users_leaderboard_admin',
        params: {
          'p_leaderboard_type': period,
          'p_date': dateString,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      return (response as List)
          .map((json) => AdminUserLeaderboardEntry.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching admin leaderboard: $e');
      rethrow;
    }
  }

  /// Get total count of users in leaderboard
  Future<int> getLeaderboardUserCount({
    String period = 'daily',
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();
      final dateString = targetDate.toIso8601String().split('T')[0];

      final response = await _supabase.rpc(
        'get_leaderboard_participant_count',
        params: {
          'p_leaderboard_type': period,
          'p_date': dateString,
        },
      );

      return response as int? ?? 0;
    } catch (e) {
      print('❌ Error fetching leaderboard count: $e');
      return 0;
    }
  }

  /// Search users in leaderboard
  Future<List<AdminUserLeaderboardEntry>> searchLeaderboardUsers({
    required String query,
    String period = 'daily',
    DateTime? date,
    int limit = 50,
  }) async {
    try {
      final allUsers = await getAllUsersLeaderboard(
        period: period,
        date: date,
        limit: 1000, // Get more for search
      );

      return allUsers
          .where((user) =>
              user.username.toLowerCase().contains(query.toLowerCase()) ||
              user.email.toLowerCase().contains(query.toLowerCase()))
          .take(limit)
          .toList();
    } catch (e) {
      print('❌ Error searching leaderboard: $e');
      return [];
    }
  }
}
```

### Admin Sadhna Service (`lib/features/admin/services/admin_sadhna_service.dart`)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/admin_sadhna_model.dart';
import '../../../core/services/auth_service.dart';

class AdminSadhnaService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  /// Get all users statistics (Admin Only)
  Future<List<AdminUserStatistics>> getAllUsersStatistics({
    int limit = 100,
    int offset = 0,
    String? search,
    int? minJapaCount,
    int? minStreak,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_all_users_statistics_admin',
        params: {
          'p_limit': limit,
          'p_offset': offset,
          'p_search': search,
          'p_min_japa_count': minJapaCount,
          'p_min_streak': minStreak,
        },
      );

      return (response as List)
          .map((json) => AdminUserStatistics.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching all users statistics: $e');
      rethrow;
    }
  }

  /// Get detailed user profile (Admin Only)
  Future<AdminUserDetailedProfile> getUserDetailedProfile(String userId) async {
    try {
      final response = await _supabase.rpc(
        'get_user_detailed_profile_admin',
        params: {'p_user_id': userId},
      );

      return AdminUserDetailedProfile.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('❌ Error fetching user detailed profile: $e');
      rethrow;
    }
  }

  /// Get platform analytics (Admin Only)
  Future<Map<String, dynamic>> getPlatformAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_platform_analytics_admin',
        params: {
          'p_start_date': startDate?.toIso8601String().split('T')[0],
          'p_end_date': endDate?.toIso8601String().split('T')[0],
        },
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error fetching platform analytics: $e');
      rethrow;
    }
  }

  /// Export users data to CSV format
  Future<String> exportUsersToCSV({
    String? search,
    int? minJapaCount,
    int? minStreak,
  }) async {
    try {
      final users = await getAllUsersStatistics(
        limit: 10000, // Get all users
        search: search,
        minJapaCount: minJapaCount,
        minStreak: minStreak,
      );

      final csv = StringBuffer();
      // Header
      csv.writeln('User ID,Username,Email,Total Japa,Active Days,Current Streak,Longest Streak,First Japa,Last Japa,Created At,Last Login');
      
      // Data rows
      for (final user in users) {
        csv.writeln([
          user.userId,
          user.username,
          user.email,
          user.totalJapaCount,
          user.totalActiveDays,
          user.currentStreak,
          user.longestStreak,
          user.firstJapaDate?.toIso8601String() ?? '',
          user.lastJapaDate?.toIso8601String() ?? '',
          user.createdAt.toIso8601String(),
          user.lastLogin?.toIso8601String() ?? '',
        ].join(','));
      }

      return csv.toString();
    } catch (e) {
      print('❌ Error exporting users to CSV: $e');
      rethrow;
    }
  }
}
```

---

## 🎨 UI Components & Screens

### 1. **Admin Leaderboard Screen** (`admin_leaderboard_screen.dart`)

**Purpose:** Display all users' leaderboard rankings with search, filter, and pagination.

**Features:**
- ✅ Data table with columns: Rank, Username, Email, Japa Count, Last Active, Actions
- ✅ Period selector: Daily, Weekly, Monthly, Yearly, All-Time
- ✅ Date picker for historical data
- ✅ Search bar (by username/email)
- ✅ Pagination (100 users per page)
- ✅ Export to CSV button
- ✅ Click user row → View detailed profile

**UI Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│  ← Back    Admin Leaderboard                                │
├─────────────────────────────────────────────────────────────┤
│  Period: [Daily ▼]  Date: [2024-12-31 📅]  [Export CSV]    │
│  🔍 Search: [________________]                             │
├─────────────────────────────────────────────────────────────┤
│  Rank | Username      | Email              | Japa | Active │
│  ───────────────────────────────────────────────────────────│
│  1    | John Doe      | john@example.com    | 1080 | Today  │
│  2    | Jane Smith    | jane@example.com    | 950  | Today  │
│  3    | Bob Johnson   | bob@example.com    | 850  | Today  │
│  ...                                                         │
├─────────────────────────────────────────────────────────────┤
│  Showing 1-100 of 1,234        < 1 2 3 4 5 >              │
└─────────────────────────────────────────────────────────────┘
```

### 2. **Admin Sadhna Profiles Screen** (`admin_sadhna_profiles_screen.dart`)

**Purpose:** Display all users' sadhna statistics in a searchable, filterable table.

**Features:**
- ✅ Data table with columns: Username, Email, Total Japa, Active Days, Current Streak, Longest Streak, Actions
- ✅ Search bar (by username/email)
- ✅ Filters: Min Japa Count, Min Streak
- ✅ Pagination
- ✅ Export to CSV
- ✅ Click user row → View detailed profile

**UI Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│  ← Back    All Users Sadhna Profiles                         │
├─────────────────────────────────────────────────────────────┤
│  🔍 Search: [________________]  [Export CSV]                │
│  Filters: Min Japa: [___]  Min Streak: [___]  [Apply]       │
├─────────────────────────────────────────────────────────────┤
│  Username    | Email              | Total | Days | Streak   │
│  ───────────────────────────────────────────────────────────│
│  John Doe    | john@example.com   | 10800 | 100  | 7/30     │
│  Jane Smith  | jane@example.com   | 9500  | 95   | 5/25     │
│  ...                                                         │
├─────────────────────────────────────────────────────────────┤
│  Showing 1-100 of 1,234        < 1 2 3 4 5 >              │
└─────────────────────────────────────────────────────────────┘
```

### 3. **Admin User Detail Screen** (`admin_user_detail_screen.dart`)

**Purpose:** Display comprehensive details for a single user.

**Features:**
- ✅ User information card (name, email, created date, last login)
- ✅ Statistics cards (Total Japa, Active Days, Streaks)
- ✅ Leaderboard rankings (Daily, Weekly, Monthly, Yearly, All-Time)
- ✅ Japa by Mantra breakdown (pie chart or list)
- ✅ Activity timeline/graph
- ✅ Export user data button

**UI Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│  ← Back    User Profile: John Doe                           │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 👤 John Doe                                           │   │
│  │ 📧 john@example.com                                  │   │
│  │ 📅 Joined: Jan 1, 2024  |  Last Login: Dec 31, 2024 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                               │
│  Statistics                                                   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐         │
│  │ Total    │ │ Active   │ │ Current │ │ Longest │         │
│  │ Japa     │ │ Days     │ │ Streak  │ │ Streak  │         │
│  │ 10,800   │ │ 100      │ │ 7       │ │ 30      │         │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘         │
│                                                               │
│  Leaderboard Rankings                                         │
│  Daily: #1  |  Weekly: #5  |  Monthly: #10  |  All-Time: #15│
│                                                               │
│  Japa by Mantra                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Om Namah Shivaya: 5,400 (50%)                        │   │
│  │ Jai Shri Ram: 3,600 (33%)                            │   │
│  │ Om Ganeshaya Namah: 1,800 (17%)                       │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                               │
│  [Export User Data]                                           │
└─────────────────────────────────────────────────────────────┘
```

### 4. **Admin Analytics Screen** (`admin_analytics_screen.dart`)

**Purpose:** Display platform-wide analytics and insights.

**Features:**
- ✅ Key metrics cards (Total Users, Active Users, Total Japa, Average Japa)
- ✅ Top users list
- ✅ Daily activity chart (line/bar chart)
- ✅ Date range selector
- ✅ Export analytics report

---

## 🔐 Security & Authentication

### Admin Role Check

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

---

## 📦 Step-by-Step Implementation

### Phase 1: Database Setup

1. ✅ Create RPC functions in Supabase:
   - `get_all_users_leaderboard_admin`
   - `get_all_users_statistics_admin`
   - `get_user_detailed_profile_admin`
   - `get_platform_analytics_admin`

2. ✅ Add RLS policies for admin access (if direct table access needed)

3. ✅ Verify admin users have `role = 'admin'` in user metadata

### Phase 2: Models & Services

1. ✅ Create admin models:
   - `AdminUserLeaderboardEntry`
   - `AdminUserStatistics`
   - `AdminUserDetailedProfile`

2. ✅ Create admin services:
   - `AdminLeaderboardService`
   - `AdminSadhnaService`

### Phase 3: UI Screens

1. ✅ Create `AdminLeaderboardScreen`
2. ✅ Create `AdminSadhnaProfilesScreen`
3. ✅ Create `AdminUserDetailScreen`
4. ✅ Create `AdminAnalyticsScreen`

### Phase 4: Routing

1. ✅ Add admin routes to `routes.dart`:
```dart
static const String adminLeaderboard = '/admin/leaderboard';
static const String adminSadhnaProfiles = '/admin/sadhna-profiles';
static const String adminUserDetail = '/admin/user-detail';
static const String adminAnalytics = '/admin/analytics';
```

### Phase 5: Testing

1. ✅ Test admin authentication
2. ✅ Test leaderboard data retrieval
3. ✅ Test user statistics retrieval
4. ✅ Test search and filters
5. ✅ Test export functionality
6. ✅ Test pagination

---

## 📊 Data Analytics & Insights

### Key Metrics to Display

1. **User Engagement:**
   - Total registered users
   - Active users (last 7/30 days)
   - New users (this week/month)

2. **Japa Activity:**
   - Total japa count (all time / period)
   - Average japa per user
   - Daily/weekly/monthly trends

3. **Streak Statistics:**
   - Users with active streaks
   - Average streak length
   - Longest streaks

4. **Leaderboard Insights:**
   - Top performers
   - Most active time periods
   - User retention rates

---

## 🔄 Integration with Existing Code

### 1. **Reuse Existing Services**

- ✅ `LeaderboardService` - Keep for user-facing leaderboard
- ✅ `StreakService` - Keep for user-facing streaks
- ✅ `AuthService` - Use for admin authentication

### 2. **Separate Admin Services**

- ✅ Create new `AdminLeaderboardService` (doesn't modify existing)
- ✅ Create new `AdminSadhnaService` (doesn't modify existing)

### 3. **Routing Integration**

Add admin routes alongside existing routes in `routes.dart`.

---

## 🎯 Key Takeaways

1. **Separation of Concerns:** Admin views are separate from user views
2. **Security First:** All admin functions check for admin role
3. **Scalability:** Pagination and efficient queries for large datasets
4. **Export Capability:** CSV export for reporting and analysis
5. **Comprehensive Analytics:** Platform-wide insights for decision making

---

## 📞 Support & References

- **Supabase RPC Functions:** https://supabase.com/docs/guides/database/functions
- **Existing Leaderboard Service:** `lib/core/services/leaderboard_service.dart`
- **Existing Streak Service:** `lib/core/services/streak_service.dart`
- **Admin Documentation:** `docs/NAM_JAPA_ADMIN_DOCUMENTATION.md`

---

**Document Version:** 1.0  
**Last Updated:** January 21, 2026  
**Author:** Development Team

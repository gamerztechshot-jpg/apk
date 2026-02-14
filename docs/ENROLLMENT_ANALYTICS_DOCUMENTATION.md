# Course & Webinar Enrollment Analytics Documentation

## Overview
This documentation provides comprehensive details about course and webinar enrollment data structures, storage mechanisms, and analytics requirements for the admin analytics section.

---

## Database Tables Structure

### 1. Course Enrollments Table (`course_enrollments`)

#### Table Schema
```sql
CREATE TABLE course_enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,              -- Student/User ID (FK to users/auth table)
    course_id TEXT NOT NULL,            -- Course ID (FK to courses table)
    
    -- JSONB Fields
    enrollment_info JSONB,              -- Course metadata at enrollment time
    payment_info JSONB NOT NULL,        -- Payment transaction details
    customer_info JSONB,                -- Customer details at enrollment
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Field Details

**enrollment_info (JSONB)**
```json
{
    "title": "Course Title",
    "price": 999,
    "teacher_id": "teacher-uuid"
}
```

**payment_info (JSONB)**
```json
{
    "razorpay_payment_id": "pay_xxxxxxxxxxxxx",
    "order_id": "order_xxxxxxxxxxxxx",
    "amount": 999,
    "status": "success"  // Possible values: "success", "failed", "pending"
}
```

**customer_info (JSONB)**
```json
{
    "name": "Student Name",
    "email": "student@example.com",
    "phone": "+919876543210"
}
```

---

### 2. Webinar Enrollments Table (`webinar_enrollments`)

#### Table Schema
```sql
CREATE TABLE webinar_enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,              -- Student/User ID (FK to users/auth table)
    webinar_id TEXT NOT NULL,           -- Webinar ID (FK to webinars table)
    
    -- JSONB Fields
    enrollment_info JSONB,              -- Webinar metadata at enrollment time
    payment_info JSONB NOT NULL,        -- Payment transaction details
    customer_info JSONB,                -- Customer details at enrollment
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Field Details

**enrollment_info (JSONB)**
```json
{
    "title": "Webinar Title",
    "price": 499,
    "teacher_id": "teacher-uuid"
}
```

**payment_info (JSONB)**
```json
{
    "razorpay_payment_id": "pay_xxxxxxxxxxxxx",
    "order_id": "order_xxxxxxxxxxxxx",
    "amount": 499,
    "status": "success"
}
```

**customer_info (JSONB)**
```json
{
    "name": "Student Name",
    "email": "student@example.com",
    "phone": "+919876543210"
}
```

---

### 3. Courses Table (`courses`)

#### Key Fields for Analytics
- `course_id` (Primary Key)
- `teacher_id` (Foreign Key to teachers/users)
- `title`
- `price` (Display price)
- `actual_price` (Payment price)
- `category`
- `status` (Values: 'pending', 'approved', 'rejected')
- `active` (Boolean)
- `fake_enrolled_count` (Display count)
- `ratings` (Average rating)
- `created_at`

---

### 4. Webinars Table (`webinars`)

#### Key Fields for Analytics
- `webinar_id` (Primary Key)
- `teacher_id` (Foreign Key to teachers/users)
- `title`
- `price` (Display price)
- `actual_price` (Payment price)
- `category`
- `start_time` (DateTime)
- `end_time` (DateTime)
- `webinar_state` (Values: 'scheduled', 'live', 'completed', 'cancelled')
- `status` (Values: 'pending', 'approved', 'rejected')
- `active` (Boolean)
- `fake_enrolled_count` (Display count)
- `ratings` (Average rating)

---

### 5. Teachers/Users Table (`pat` table)

#### Teacher Model Structure
Based on `pat` table with `basic_info` JSONB field:
- `id` (Primary Key)
- `user_id` (FK to auth/users)
- `basic_info` (JSONB containing):
  - `name`
  - `photo_url`
  - `qualification`
  - `about_you`

---

## Data Models (Flutter/Dart)

### CourseEnrollment Model
```dart
class CourseEnrollment {
  final String id;                    // Enrollment record ID
  final String orderId;               // Payment order ID
  final String courseId;              // Course ID
  final String courseTitle;           // Course title at enrollment
  final double amountPaid;            // Amount paid (from payment_info.amount)
  final String paymentId;             // Razorpay payment ID
  final String paymentStatus;         // Payment status
  final DateTime enrolledAt;          // Enrollment timestamp (created_at)
}
```

### WebinarEnrollment Model
```dart
class WebinarEnrollment {
  final String id;                    // Enrollment record ID
  final String userId;                // Student/User ID
  final String webinarId;             // Webinar ID
  final String webinarTitle;          // Webinar title at enrollment
  final double amountPaid;            // Amount paid
  final String paymentId;             // Razorpay payment ID
  final String paymentStatus;         // Payment status
  final DateTime enrolledAt;          // Enrollment timestamp
}
```

---

## Analytics Queries for Admin Dashboard

### 1. Total Course Enrollments Count
```sql
SELECT COUNT(*) as total_enrollments
FROM course_enrollments
WHERE payment_info->>'status' = 'success';
```

### 2. Total Webinar Enrollments Count
```sql
SELECT COUNT(*) as total_enrollments
FROM webinar_enrollments
WHERE payment_info->>'status' = 'success';
```

### 3. Total Revenue (Courses + Webinars)
```sql
-- Course Revenue
SELECT COALESCE(SUM((payment_info->>'amount')::numeric), 0) as course_revenue
FROM course_enrollments
WHERE payment_info->>'status' = 'success';

-- Webinar Revenue
SELECT COALESCE(SUM((payment_info->>'amount')::numeric), 0) as webinar_revenue
FROM webinar_enrollments
WHERE payment_info->>'status' = 'success';

-- Total Revenue
SELECT 
    COALESCE(SUM((payment_info->>'amount')::numeric), 0) as total_revenue
FROM (
    SELECT payment_info FROM course_enrollments WHERE payment_info->>'status' = 'success'
    UNION ALL
    SELECT payment_info FROM webinar_enrollments WHERE payment_info->>'status' = 'success'
) AS all_payments;
```

### 4. Revenue by Course
```sql
SELECT 
    ce.course_id,
    c.title as course_title,
    c.teacher_id,
    COUNT(ce.id) as enrollment_count,
    SUM((ce.payment_info->>'amount')::numeric) as total_revenue
FROM course_enrollments ce
JOIN courses c ON ce.course_id = c.course_id
WHERE ce.payment_info->>'status' = 'success'
GROUP BY ce.course_id, c.title, c.teacher_id
ORDER BY total_revenue DESC;
```

### 5. Revenue by Webinar
```sql
SELECT 
    we.webinar_id,
    w.title as webinar_title,
    w.teacher_id,
    COUNT(we.id) as enrollment_count,
    SUM((we.payment_info->>'amount')::numeric) as total_revenue
FROM webinar_enrollments we
JOIN webinars w ON we.webinar_id = w.webinar_id
WHERE we.payment_info->>'status' = 'success'
GROUP BY we.webinar_id, w.title, w.teacher_id
ORDER BY total_revenue DESC;
```

### 6. Revenue by Teacher
```sql
-- Course Revenue by Teacher
SELECT 
    c.teacher_id,
    COUNT(DISTINCT ce.course_id) as course_count,
    COUNT(ce.id) as total_enrollments,
    SUM((ce.payment_info->>'amount')::numeric) as course_revenue
FROM course_enrollments ce
JOIN courses c ON ce.course_id = c.course_id
WHERE ce.payment_info->>'status' = 'success'
GROUP BY c.teacher_id;

-- Webinar Revenue by Teacher
SELECT 
    w.teacher_id,
    COUNT(DISTINCT we.webinar_id) as webinar_count,
    COUNT(we.id) as total_enrollments,
    SUM((we.payment_info->>'amount')::numeric) as webinar_revenue
FROM webinar_enrollments we
JOIN webinars w ON we.webinar_id = w.webinar_id
WHERE we.payment_info->>'status' = 'success'
GROUP BY w.teacher_id;

-- Combined Revenue by Teacher
SELECT 
    COALESCE(c_stats.teacher_id, w_stats.teacher_id) as teacher_id,
    COALESCE(c_stats.course_count, 0) as course_count,
    COALESCE(w_stats.webinar_count, 0) as webinar_count,
    COALESCE(c_stats.total_course_enrollments, 0) + COALESCE(w_stats.total_webinar_enrollments, 0) as total_enrollments,
    COALESCE(c_stats.course_revenue, 0) + COALESCE(w_stats.webinar_revenue, 0) as total_revenue
FROM (
    SELECT 
        c.teacher_id,
        COUNT(DISTINCT ce.course_id) as course_count,
        COUNT(ce.id) as total_course_enrollments,
        SUM((ce.payment_info->>'amount')::numeric) as course_revenue
    FROM course_enrollments ce
    JOIN courses c ON ce.course_id = c.course_id
    WHERE ce.payment_info->>'status' = 'success'
    GROUP BY c.teacher_id
) c_stats
FULL OUTER JOIN (
    SELECT 
        w.teacher_id,
        COUNT(DISTINCT we.webinar_id) as webinar_count,
        COUNT(we.id) as total_webinar_enrollments,
        SUM((we.payment_info->>'amount')::numeric) as webinar_revenue
    FROM webinar_enrollments we
    JOIN webinars w ON we.webinar_id = w.webinar_id
    WHERE we.payment_info->>'status' = 'success'
    GROUP BY w.teacher_id
) w_stats ON c_stats.teacher_id = w_stats.teacher_id
ORDER BY total_revenue DESC;
```

### 7. Student Details (Enrolled Students)
```sql
-- Students enrolled in courses
SELECT DISTINCT
    ce.user_id,
    ce.customer_info->>'name' as student_name,
    ce.customer_info->>'email' as student_email,
    ce.customer_info->>'phone' as student_phone,
    COUNT(DISTINCT ce.course_id) as enrolled_courses_count,
    SUM((ce.payment_info->>'amount')::numeric) as total_course_payments
FROM course_enrollments ce
WHERE ce.payment_info->>'status' = 'success'
GROUP BY ce.user_id, ce.customer_info->>'name', ce.customer_info->>'email', ce.customer_info->>'phone';

-- Students enrolled in webinars
SELECT DISTINCT
    we.user_id,
    we.customer_info->>'name' as student_name,
    we.customer_info->>'email' as student_email,
    we.customer_info->>'phone' as student_phone,
    COUNT(DISTINCT we.webinar_id) as enrolled_webinars_count,
    SUM((we.payment_info->>'amount')::numeric) as total_webinar_payments
FROM webinar_enrollments we
WHERE we.payment_info->>'status' = 'success'
GROUP BY we.user_id, we.customer_info->>'name', we.customer_info->>'email', we.customer_info->>'phone';

-- Combined Student Enrollment Summary
SELECT 
    COALESCE(c_students.user_id, w_students.user_id) as user_id,
    COALESCE(c_students.student_name, w_students.student_name) as student_name,
    COALESCE(c_students.student_email, w_students.student_email) as student_email,
    COALESCE(c_students.student_phone, w_students.student_phone) as student_phone,
    COALESCE(c_students.enrolled_courses_count, 0) as enrolled_courses_count,
    COALESCE(w_students.enrolled_webinars_count, 0) as enrolled_webinars_count,
    COALESCE(c_students.total_course_payments, 0) + COALESCE(w_students.total_webinar_payments, 0) as total_spent
FROM (
    SELECT DISTINCT
        ce.user_id,
        ce.customer_info->>'name' as student_name,
        ce.customer_info->>'email' as student_email,
        ce.customer_info->>'phone' as student_phone,
        COUNT(DISTINCT ce.course_id) as enrolled_courses_count,
        SUM((ce.payment_info->>'amount')::numeric) as total_course_payments
    FROM course_enrollments ce
    WHERE ce.payment_info->>'status' = 'success'
    GROUP BY ce.user_id, ce.customer_info->>'name', ce.customer_info->>'email', ce.customer_info->>'phone'
) c_students
FULL OUTER JOIN (
    SELECT DISTINCT
        we.user_id,
        we.customer_info->>'name' as student_name,
        we.customer_info->>'email' as student_email,
        we.customer_info->>'phone' as student_phone,
        COUNT(DISTINCT we.webinar_id) as enrolled_webinars_count,
        SUM((we.payment_info->>'amount')::numeric) as total_webinar_payments
    FROM webinar_enrollments we
    WHERE we.payment_info->>'status' = 'success'
    GROUP BY we.user_id, we.customer_info->>'name', we.customer_info->>'email', we.customer_info->>'phone'
) w_students ON c_students.user_id = w_students.user_id
ORDER BY total_spent DESC;
```

### 8. Top Performing Courses
```sql
SELECT 
    c.course_id,
    c.title,
    c.teacher_id,
    c.category,
    c.price,
    COUNT(ce.id) as enrollment_count,
    SUM((ce.payment_info->>'amount')::numeric) as revenue,
    AVG(c.ratings) as average_rating
FROM courses c
LEFT JOIN course_enrollments ce ON c.course_id = ce.course_id AND ce.payment_info->>'status' = 'success'
WHERE c.status = 'approved' AND c.active = true
GROUP BY c.course_id, c.title, c.teacher_id, c.category, c.price
ORDER BY revenue DESC NULLS LAST
LIMIT 10;
```

### 9. Top Performing Webinars
```sql
SELECT 
    w.webinar_id,
    w.title,
    w.teacher_id,
    w.category,
    w.price,
    w.start_time,
    w.end_time,
    w.webinar_state,
    COUNT(we.id) as enrollment_count,
    SUM((we.payment_info->>'amount')::numeric) as revenue,
    AVG(w.ratings) as average_rating
FROM webinars w
LEFT JOIN webinar_enrollments we ON w.webinar_id = we.webinar_id AND we.payment_info->>'status' = 'success'
WHERE w.status = 'approved' AND w.active = true
GROUP BY w.webinar_id, w.title, w.teacher_id, w.category, w.price, w.start_time, w.end_time, w.webinar_state
ORDER BY revenue DESC NULLS LAST
LIMIT 10;
```

### 10. Revenue by Time Period (Daily/Monthly/Yearly)
```sql
-- Daily Revenue
SELECT 
    DATE(created_at) as date,
    'course' as type,
    COUNT(*) as enrollments,
    SUM((payment_info->>'amount')::numeric) as revenue
FROM course_enrollments
WHERE payment_info->>'status' = 'success'
GROUP BY DATE(created_at)
UNION ALL
SELECT 
    DATE(created_at) as date,
    'webinar' as type,
    COUNT(*) as enrollments,
    SUM((payment_info->>'amount')::numeric) as revenue
FROM webinar_enrollments
WHERE payment_info->>'status' = 'success'
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Monthly Revenue
SELECT 
    DATE_TRUNC('month', created_at) as month,
    'course' as type,
    COUNT(*) as enrollments,
    SUM((payment_info->>'amount')::numeric) as revenue
FROM course_enrollments
WHERE payment_info->>'status' = 'success'
GROUP BY DATE_TRUNC('month', created_at)
UNION ALL
SELECT 
    DATE_TRUNC('month', created_at) as month,
    'webinar' as type,
    COUNT(*) as enrollments,
    SUM((payment_info->>'amount')::numeric) as revenue
FROM webinar_enrollments
WHERE payment_info->>'status' = 'success'
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month DESC;
```

---

## Key Metrics for Admin Dashboard

### Summary Metrics
1. **Total Courses** - Count of all approved and active courses
2. **Total Webinars** - Count of all approved and active webinars
3. **Total Course Enrollments** - Count of successful course enrollments
4. **Total Webinar Enrollments** - Count of successful webinar enrollments
5. **Total Revenue (Courses)** - Sum of all successful course payments
6. **Total Revenue (Webinars)** - Sum of all successful webinar payments
7. **Total Revenue (Combined)** - Combined revenue from courses and webinars
8. **Total Unique Students** - Count of distinct users enrolled in courses/webinars
9. **Total Teachers** - Count of distinct teachers with courses/webinars
10. **Average Course Price** - Average price of courses
11. **Average Webinar Price** - Average price of webinars
12. **Average Revenue per Student** - Total revenue / Total unique students
13. **Average Revenue per Teacher** - Total revenue / Total teachers

### Detailed Analytics Views

#### Course Analytics
- Course list with enrollment counts and revenue
- Course performance ranking
- Revenue by course category
- Course enrollment trends over time

#### Webinar Analytics
- Webinar list with enrollment counts and revenue
- Webinar performance ranking
- Revenue by webinar category
- Upcoming vs completed webinars revenue

#### Teacher Analytics
- Teacher performance dashboard
- Revenue by teacher
- Courses/webinars count by teacher
- Top performing teachers

#### Student Analytics
- Student enrollment list
- Student spending analysis
- Most active students (by enrollment count)
- Students enrolled in both courses and webinars

#### Financial Analytics
- Revenue trends (daily, weekly, monthly, yearly)
- Revenue breakdown by category
- Payment status analysis (success vs failed)
- Revenue forecast based on trends

---

## Data Access Patterns

### Using Supabase (Current Implementation)

```dart
// Example: Fetch course enrollments
final response = await _supabase
    .from('course_enrollments')
    .select()
    .eq('payment_info->>status', 'success')
    .order('created_at', ascending: false);

// Example: Fetch revenue by course
final response = await _supabase
    .from('course_enrollments')
    .select('course_id, payment_info')
    .eq('payment_info->>status', 'success');

// Example: Fetch enrollment with course details (requires join or separate query)
final enrollments = await _supabase
    .from('course_enrollments')
    .select('*')
    .eq('payment_info->>status', 'success');

final courseIds = enrollments.map((e) => e['course_id']).toSet().toList();
final courses = await _supabase
    .from('courses')
    .select()
    .in_('course_id', courseIds);
```

### Important Notes
1. **JSONB Field Access**: Use `->>` for text extraction, `->` for JSON object
2. **Payment Status Filter**: Always filter by `payment_info->>'status' = 'success'` for revenue calculations
3. **Date Filtering**: Use `created_at` field for enrollment dates
4. **Amount Extraction**: Cast JSONB string to numeric: `(payment_info->>'amount')::numeric`
5. **Teacher Information**: Join with `pat` table using `teacher_id` or fetch from `courses`/`webinars` tables
6. **Student Information**: Extract from `customer_info` JSONB field or join with user profile tables

---

## Recommendations for Admin Analytics Implementation

1. **Create Database Views**: Consider creating materialized views for complex queries
2. **Index Optimization**: Add indexes on frequently queried fields:
   - `course_enrollments(user_id, course_id)`
   - `webinar_enrollments(user_id, webinar_id)`
   - `course_enrollments(created_at)` for time-based queries
   - `course_enrollments((payment_info->>'status'))` for payment status filtering
3. **Caching Strategy**: Cache summary metrics and refresh periodically
4. **Real-time Updates**: Use Supabase real-time subscriptions for live dashboard updates
5. **Export Functionality**: Allow exporting analytics data to CSV/Excel
6. **Date Range Filtering**: Implement date range filters for all analytics views
7. **Pagination**: Implement pagination for large datasets

---

## File References

- **Enrollment Models**: `lib/features/teacher/model/enrollment.dart`
- **Course Model**: `lib/features/teacher/model/course.dart`
- **Webinar Model**: `lib/features/teacher/model/webinar.dart`
- **Enrollment Service**: `lib/features/teacher/service/enrollment_service.dart`
- **Teacher Service**: `lib/features/teacher/service/teacher_service.dart`
- **Teacher Model**: `lib/features/teacher/model/teacher_model.dart`
- **User Profile Model**: `lib/core/models/user_profile_model.dart`

---

## Version History
- **v1.0** - Initial documentation created based on codebase analysis
- Date: 2025-01-29


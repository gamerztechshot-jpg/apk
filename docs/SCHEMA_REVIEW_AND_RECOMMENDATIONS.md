# Database Schema Review & Recommendations

## 📊 Current Schema Analysis

### ✅ **What's Good:**
1. **UUID Primary Keys** - Good for distributed systems
2. **JSONB Columns** - Perfect for flexible data storage (`content_access`, `chat_history`, `chat_question`, `plan_details`)
3. **Credit Cost Columns** - Already present in `main_problems` and `sub_problems`
4. **Timestamps** - `created_at` present in all tables
5. **Boolean Flags** - `is_active`, `is_paid`, `is_credit_deducted` for state management

---

## ⚠️ **Critical Issues & Recommendations**

### 1. **`user_ai_usage` Table - Missing Critical Column**

**Issue**: Missing `accessed_problems` JSONB column to track which problems user has accessed.

**Impact**: Cannot prevent duplicate credit deduction if user accesses same problem twice.

**Recommendation**:
```sql
ALTER TABLE user_ai_usage 
ADD COLUMN accessed_problems JSONB DEFAULT '[]'::jsonb;

-- Add comment
COMMENT ON COLUMN user_ai_usage.accessed_problems IS 
'Array of problem IDs (main_problems.id or sub_problems.id) that user has accessed. Format: ["uuid-1", "uuid-2"]';
```

**Usage**: 
- When user accesses a problem → Add problem ID to this array
- Before deducting credits → Check if problem ID already exists
- Prevents duplicate credit deduction

---

### 2. **`user_ai_usage` Table - Redundant Single Fields**

**Issue**: The table has single fields (`ai_question`, `ai_response`, `ai_intent_hash`) but also has JSONB arrays (`chat_history`, `chat_question`).

**Current Fields**:
- `ai_question` (text) - Single question
- `ai_response` (text) - Single response
- `ai_intent_hash` (text) - Single hash
- `ai_response_status` (text) - Single status
- `is_credit_deducted` (boolean) - Single flag

**Problem**: These fields can only store ONE question/response, but users will have multiple chat messages.

**Recommendation**: 
**Option A (Recommended)**: Keep JSONB arrays only, remove single fields
- Use `chat_history` JSONB for all chat messages
- Use `chat_question` JSONB for all questions
- Remove: `ai_question`, `ai_response`, `ai_intent_hash`, `ai_response_status`
- Keep: `is_credit_deducted` (but track per message in JSONB instead)

**Option B**: Keep both, but clarify usage
- Single fields = Last question/response (for quick access)
- JSONB arrays = Full chat history
- Use single fields for "latest" and arrays for "history"

**My Recommendation**: **Option A** - Use JSONB arrays only for flexibility.

---

### 3. **Missing `updated_at` Timestamps**

**Issue**: No `updated_at` column in any table.

**Impact**: Cannot track when records were last modified (important for debugging, analytics).

**Recommendation**:
See migration script in `sql/mantra_generator_schema_migration.sql`

---

### 4. **Missing Indexes for Performance**

**Issue**: No indexes on frequently queried columns.

**Impact**: Slow queries, especially as data grows.

**Recommendation**:
See migration script in `sql/mantra_generator_schema_migration.sql`

---

### 5. **Missing Foreign Key Constraints**

**Issue**: No foreign key constraints to ensure data integrity.

**Impact**: Orphaned records, data inconsistency.

**Recommendation**:
See migration script in `sql/mantra_generator_schema_migration.sql`

---

### 6. **Missing Check Constraints**

**Issue**: No validation for enum-like fields.

**Impact**: Invalid data can be inserted.

**Recommendation**:
See migration script in `sql/mantra_generator_schema_migration.sql`

---

### 7. **Missing Default Value for `user_ai_usage.free_credits_left`**

**Issue**: Default is 0, but new users should get 11 free credits.

**Impact**: Need to manually set 11 credits for each new user.

**Recommendation**:
**Option B**: Use database trigger (Recommended)
See migration script in `sql/mantra_generator_schema_migration.sql`

---

### 8. **JSONB Structure Recommendations**

**Issue**: Need to define structure for JSONB columns.

**Recommendation**: Document expected structure:

#### `chatbot_packages.content_access`:
```json
["uuid-1", "uuid-2", "uuid-3"]
```
- Array of problem IDs (main_problems.id or sub_problems.id)
- Empty array `[]` = no access
- Can contain both main and sub-problem IDs

#### `user_ai_usage.accessed_problems`:
```json
["uuid-1", "uuid-2"]
```
- Array of problem IDs user has accessed
- Prevents duplicate credit deduction

#### `user_ai_usage.chat_history`:
```json
[
  {
    "id": "msg-1",
    "text": "User question here",
    "isUser": true,
    "timestamp": "2026-01-27T10:00:00Z",
    "problemId": "uuid-1"
  },
  {
    "id": "msg-2",
    "text": "AI response here",
    "isUser": false,
    "timestamp": "2026-01-27T10:00:01Z",
    "creditsDeducted": 1
  }
]
```

#### `user_ai_usage.chat_question`:
```json
[
  {
    "question": "User question",
    "problemId": "uuid-1",
    "timestamp": "2026-01-27T10:00:00Z",
    "creditsDeducted": 1
  }
]
```

#### `user_ai_usage.plan_details`:
```json
{
  "packageId": "uuid",
  "packageName": "Starter Pack",
  "packageType": "starter",
  "aiQuestionLimit": 50,
  "contentAccess": ["uuid-1", "uuid-2"],
  "purchasedAt": "2026-01-27T10:00:00Z"
}
```

#### `user_payments.plan_details`:
```json
{
  "packageId": "uuid",
  "packageName": "Starter Pack",
  "packageType": "starter",
  "amount": 999.00,
  "finalAmount": 899.00,
  "aiQuestionLimit": 50,
  "contentAccess": ["uuid-1", "uuid-2"]
}
```

#### `user_payments.user_info`:
```json
{
  "name": "User Name",
  "email": "user@example.com",
  "phone": "+1234567890"
}
```

#### `user_payments.payment_response`:
```json
{
  "razorpay_order_id": "order_xxx",
  "razorpay_payment_id": "pay_xxx",
  "razorpay_signature": "signature_xxx",
  "status": "success"
}
```

---

## 📝 **Complete Migration Script**

**See**: `sql/mantra_generator_schema_migration.sql`

The migration script includes:
1. Add `accessed_problems` JSONB column
2. Add `updated_at` columns with triggers
3. Create indexes for performance
4. Add foreign key constraints
5. Add check constraints
6. Create trigger to initialize 11 free credits

---

## 🎯 **Priority Summary**

### **CRITICAL (Must Add):**
1. ✅ `accessed_problems` JSONB column in `user_ai_usage`
2. ✅ Indexes on `user_id` in `user_ai_usage` and `user_payments`
3. ✅ GIN indexes on JSONB columns

### **IMPORTANT (Should Add):**
4. ✅ `updated_at` columns with triggers
5. ✅ Foreign key constraints
6. ✅ Check constraints for data validation
7. ✅ Trigger to initialize 11 free credits

### **OPTIONAL (Nice to Have):**
8. ⚠️ Consider removing single fields (`ai_question`, `ai_response`) if using JSONB arrays only

---

## 📋 **Final Schema Checklist**

- [x] `credit_cost` columns exist in `main_problems` and `sub_problems`
- [ ] `accessed_problems` JSONB column added to `user_ai_usage`
- [ ] `updated_at` columns added to all tables
- [ ] Indexes created for performance
- [ ] Foreign key constraints added
- [ ] Check constraints added
- [ ] Trigger for 11 free credits initialization
- [ ] JSONB structure documented

---

**Next Steps:**
1. Review these recommendations
2. Run the migration script (`sql/mantra_generator_schema_migration.sql`)
3. Verify all changes
4. Start coding! 🚀

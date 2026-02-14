# Plan of Action: Sub-Problem Access Flow with Credit Confirmation Dialog

## 📋 Current State Analysis

### What's Working:
1. ✅ Problem list shows main problems
2. ✅ Sub-problems are loaded and displayed
3. ✅ Access control service checks credits
4. ✅ Credits are deducted when accessing
5. ✅ Problems are marked as accessed
6. ✅ Duplicate deduction prevention exists

### What Needs to Change:
1. ❌ No confirmation dialog before deducting credits
2. ❌ Credits are deducted immediately without user confirmation
3. ❌ No display of remaining credits before access
4. ❌ Need to store both main problem ID + sub-problem ID when accessing sub-problem
5. ❌ Need to check if already accessed BEFORE showing dialog

---

## 🎯 Requirements Breakdown

### User Flow:
1. User clicks on **problem list** → Shows main problems ✅ (Already working)
2. User clicks on **main problem** → Expands to show sub-problems ✅ (Already working)
3. User clicks on **sub-problem**:
   - ✅ Check if already accessed → If yes, go directly to content (no dialog)
   - ✅ Check credits availability
   - ✅ Show confirmation dialog with:
     - Remaining credits count
     - Credit cost for this sub-problem
     - Confirmation message
   - ✅ After user confirms:
     - Deduct credits
     - Store both main problem ID + sub-problem ID in `accessed_problems`
     - Mark as accessed forever
     - Navigate to content screen
   - ✅ If user cancels → Do nothing

---

## 🔧 Implementation Plan

### Step 1: Update `accessed_problems` Storage Strategy

**Current:** Stores only problem ID (either main or sub)
**New:** Store both main problem ID and sub-problem ID when accessing sub-problem

**Options:**
- **Option A:** Store sub-problem ID only (simpler, sub-problem ID is unique)
- **Option B:** Store both IDs as "mainId:subId" (combined string)
- **Option C:** Store both IDs separately in array

**Recommendation:** **Option A** (Store sub-problem ID only)
- Sub-problem ID is already unique
- Sub-problem has `mainProblemId` relationship
- Simpler to check and maintain
- Already prevents duplicate access

**If user wants both stored:** Use **Option B** (combined format)

---

### Step 2: Create Credit Confirmation Dialog

**File:** `lib/features/mantra_generator/widgets/credit_confirmation_dialog.dart`

**Dialog Content:**
- Title: "Access Sub-Problem"
- Icon: Wallet icon
- Message: 
  - "This sub-problem costs: X credits"
  - "Your remaining credits: Y credits"
  - "After access, you will have: Z credits remaining"
  - "Do you want to proceed?"
- Buttons:
  - Cancel (TextButton)
  - Confirm (ElevatedButton - Orange)

---

### Step 3: Update `_handleProblemTap` Method

**File:** `lib/features/mantra_generator/views/screens/problem_list_screen.dart`

**New Flow:**
```dart
Future<void> _handleProblemTap(...) async {
  1. Check if user is logged in
  2. Get current credits from CreditViewModel
  3. Get credit cost for sub-problem
  4. Check if already accessed:
     - If YES → Navigate directly to content (skip dialog)
     - If NO → Continue
  5. Check if user has enough credits:
     - If NO → Show "Insufficient Credits" dialog
     - If YES → Show confirmation dialog
  6. On confirmation:
     - Deduct credits
     - Add to accessed_problems (store sub-problem ID)
     - Navigate to content screen
  7. On cancel:
     - Do nothing (close dialog)
}
```

---

### Step 4: Update Access Control Service

**File:** `lib/features/mantra_generator/services/access_control_service.dart`

**Changes:**
- `checkProblemAccess()` - Already checks if accessed ✅
- `grantAccess()` - Already prevents duplicate deduction ✅
- Add method: `getCreditCostForProblem()` - Returns credit cost

---

### Step 5: Update Repository to Store Both IDs (If Required)

**File:** `lib/features/mantra_generator/repositories/user_ai_usage_repository.dart`

**If storing both IDs:**
- Update `addAccessedProblem()` to accept both main and sub IDs
- Store format: "mainId:subId" or store both separately

**If storing sub-problem ID only (Recommended):**
- No changes needed (current implementation works)

---

### Step 6: Update CreditViewModel Integration

**File:** `lib/features/mantra_generator/views/screens/problem_list_screen.dart`

**Changes:**
- Get current credits from `CreditViewModel` before showing dialog
- Refresh credits after deduction
- Show loading state during credit deduction

---

## 📝 Code Structure

### New Files to Create:
1. `lib/features/mantra_generator/widgets/credit_confirmation_dialog.dart`

### Files to Modify:
1. `lib/features/mantra_generator/views/screens/problem_list_screen.dart`
   - Update `_handleProblemTap()` method
   - Add dialog integration
   - Add credit check before dialog

2. `lib/features/mantra_generator/services/access_control_service.dart`
   - Add `getCreditCostForProblem()` method (if needed)

3. `lib/features/mantra_generator/repositories/user_ai_usage_repository.dart`
   - Update `addAccessedProblem()` if storing both IDs

---

## ❓ Questions & Doubts

### 1. Storage Format for Accessed Problems
**Question:** Do you want to store both main problem ID AND sub-problem ID, or just sub-problem ID?

**Current:** Only sub-problem ID is stored
**Recommendation:** Store sub-problem ID only (it's unique and prevents duplicates)

**If you want both:** We can store as "mainId:subId" format

---

### 2. Main Problem Access
**Question:** When user clicks on main problem (not sub-problem), should we:
- Show dialog and deduct credits?
- Or only show sub-problems without deducting?

**Current:** Main problem click also deducts credits
**Recommendation:** Only deduct when accessing sub-problem (as per your requirement)

---

### 3. Dialog Language
**Question:** Should dialog support Hindi/English based on language setting?

**Recommendation:** Yes, use `LanguageService` for localization

---

### 4. Credit Display Format
**Question:** How should credits be displayed?
- "11 credits remaining"
- "11 credits left"
- "You have 11 credits"

**Recommendation:** "You have X credits remaining. This will cost Y credits."

---

### 5. Already Accessed Behavior
**Question:** When user clicks on already-accessed sub-problem:
- Show message: "Already accessed"?
- Or silently navigate to content?

**Recommendation:** Silently navigate (better UX)

---

### 6. Error Handling
**Question:** What if credit deduction fails after user confirms?
- Show error dialog?
- Rollback?
- Retry?

**Recommendation:** Show error dialog with retry option

---

## 🚀 Implementation Steps (Order)

1. **Create Credit Confirmation Dialog Widget**
2. **Update `_handleProblemTap` to check if already accessed first**
3. **Add credit check and dialog before deduction**
4. **Update credit deduction flow**
5. **Add both IDs storage (if required)**
6. **Test the complete flow**
7. **Add error handling**

---

## ✅ Success Criteria

- [ ] Dialog shows before credit deduction
- [ ] Dialog displays remaining credits
- [ ] Dialog displays credit cost
- [ ] User can cancel without deduction
- [ ] Credits are deducted only after confirmation
- [ ] Both main + sub-problem IDs stored (if required)
- [ ] Already accessed problems skip dialog
- [ ] Content shows after successful access
- [ ] No duplicate credit deduction
- [ ] Error handling for failed deduction

---

## 📌 Notes

- Focus on **pre-built content** first (as requested)
- AI chat feature will be added later
- Ensure `ProblemContentScreen` works correctly for pre-built content
- Test with different credit scenarios (0 credits, exact credits, more credits)

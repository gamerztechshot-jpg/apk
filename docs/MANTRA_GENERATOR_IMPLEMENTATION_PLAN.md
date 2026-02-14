# Mantra Generator - Implementation Plan (Updated)

## 📋 My Understanding

### System Overview
- **Backend**: Supabase (PostgreSQL database)
- **Frontend**: Flutter with Provider state management
- **Payment**: Razorpay (already integrated)
- **Architecture**: MVVM + Repositories + Services pattern
- **AI Integration**: Supabase Edge Function (NOT direct OpenAI calls from Flutter)
- **OpenAI API Key**: Stored in Supabase Secret Variables
- **Default Free Credits**: 11 credits (deducted after access)
- **Navigation**: Home FAB with chatbot icon → Opens Mantra Generator
- **Theme**: Orange (#FF6B35) matching existing app design
- **Language**: Hindi/English support using existing `LanguageService`

### Folder Structure (5 Folders)
```
lib/features/mantra_generator/
├── models/          # Data models (MainProblem, SubProblem, Package, etc.)
├── repositories/   # Data access layer (Supabase queries)
├── services/       # Business logic services (Credit, Access Control, etc.)
├── viewmodels/     # State management & business logic (Provider ChangeNotifier)
└── views/          # UI screens & widgets
```

### Key Components Needed
1. **Backend**: Supabase Edge Function for mantra generation
2. **Database Tables**: Already exist (main_problems, sub_problems, chatbot_packages, user_payments, user_ai_usage)
3. **Models**: Problem, Sub-problem, Package, User AI Usage, Chat Message
4. **Repositories**: Data fetching from Supabase
5. **Services**: Credit management, Access control, AI chat service
6. **ViewModels**: State management for screens
7. **Views**: Problem list, AI chat, Package purchase, Credit display

---

## 🎯 Implementation Phases

### **PHASE 1: Backend Setup & Database Verification** ⏱️ Priority: HIGH
**Goal**: Set up Supabase Edge Function and verify database structure

#### Tasks:
1. **Create Supabase Edge Function for Mantra Generation**
   - Function name: `generate-mantra`
   - Endpoint: `https://[project-ref].supabase.co/functions/v1/generate-mantra`
   - Accepts: `{ text: string, problemId?: string, userId?: string, chatHistory?: array }`
   - Calls OpenAI API (gpt-4.1-mini or gpt-3.5-turbo)
   - Returns: `{ mantra: string }`
   - Uses Supabase Secret Variable: `OPENAI_API_KEY`
   - Includes rate limiting and input validation
   - Max input length: 300 characters

2. **Verify Database Tables**
   - ✅ `main_problems` table exists
   - ✅ `sub_problems` table exists
   - ✅ `chatbot_packages` table exists
   - ✅ `user_payments` table exists
   - ✅ `user_ai_usage` table exists
   - ⚠️ Check if `credit_cost` column exists in `main_problems` and `sub_problems`
   - ⚠️ Verify `content_access` is JSONB in `chatbot_packages`
   - ⚠️ Verify `chat_history` and `chat_question` are JSONB in `user_ai_usage`

3. **SQL Migration Script** (if needed)
   - Add `credit_cost INTEGER DEFAULT 0` to `main_problems` if missing
   - Add `credit_cost INTEGER DEFAULT 0` to `sub_problems` if missing
   - Verify JSONB columns for `content_access`, `chat_history`, `chat_question`

**Deliverables**:
- ✅ Supabase Edge Function deployed and tested
- ✅ Database structure verified
- ✅ API endpoint tested with Postman/curl
- ✅ Migration scripts created (if needed)

---

### **PHASE 2: Folder Structure & Models** ⏱️ Priority: HIGH
**Goal**: Create folder structure and data models

#### Tasks:
1. **Create Folder Structure**
   ```
   lib/features/mantra_generator/
   ├── models/
   ├── repositories/
   ├── services/
   ├── viewmodels/
   └── views/
   ```

2. **Create Models** (`lib/features/mantra_generator/models/`)
   - `main_problem_model.dart` - Main problem with credit_cost, linked content IDs
   - `sub_problem_model.dart` - Sub-problem with main_problem_id, credit_cost
   - `chatbot_package_model.dart` - Package with ai_question_limit, content_access JSONB
   - `user_ai_usage_model.dart` - User credits, chat_history, plan_details
   - `chat_message_model.dart` - Chat message (user/AI, text, timestamp)
   - `access_status_model.dart` - Access check result (hasAccess, reason, creditsRequired)

3. **Model Features**
   - All models with `fromJson()` and `toJson()`
   - Helper methods for credit cost display
   - Helper methods for linked content count
   - Validation methods

**Deliverables**:
- ✅ Folder structure created
- ✅ All models created with fromJson/toJson
- ✅ Helper methods implemented

---

### **PHASE 3: Repositories Layer** ⏱️ Priority: HIGH
**Goal**: Create data access layer for Supabase queries

#### Tasks:
1. **Create Repositories** (`lib/features/mantra_generator/repositories/`)
   - `problem_repository.dart`
     - `getMainProblems()` - Fetch all active main problems
     - `getSubProblems(mainProblemId)` - Fetch sub-problems for a main problem
     - `getProblemById(id)` - Get single problem
     - `searchProblems(query)` - Search problems by title
   
   - `package_repository.dart`
     - `getActivePackages()` - Fetch all active packages
     - `getPackageById(id)` - Get package by ID
     - `getUserActivePackage(userId)` - Get user's active package (from user_payments)
   
   - `user_ai_usage_repository.dart`
     - `getUserAIUsage(userId)` - Get user's credit status and usage
     - `createUserAIUsage(userId)` - Initialize user AI usage (11 free credits)
     - `updateCredits(userId, freeCredits, topupCredits, consumed)` - Update credits
     - `recordAIUsage(userId, question, response, creditsDeducted)` - Record AI question
     - `updateChatHistory(userId, chatHistory)` - Update chat history JSONB
     - `updateAccessedProblems(userId, problemIds)` - Update accessed problems JSONB
   
   - `payment_repository.dart`
     - `createPaymentRecord(userId, packageId, paymentData)` - Create payment record
     - `getUserPayments(userId)` - Get user's payment history

2. **Repository Features**
   - Use Supabase client directly
   - Error handling and logging
   - Return typed models (not raw JSON)
   - Handle JSONB fields correctly

**Deliverables**:
- ✅ All repositories created
- ✅ Supabase queries implemented
- ✅ Error handling added

---

### **PHASE 4: Services Layer** ⏱️ Priority: HIGH
**Goal**: Create business logic services

#### Tasks:
1. **Create Services** (`lib/features/mantra_generator/services/`)
   - `credit_service.dart`
     - `getUserCredits(userId)` - Get current credit status
     - `deductCredits(userId, amount)` - Deduct credits (free first, then topup)
     - `checkCreditsAvailable(userId, required)` - Check if credits available
     - `initializeUserCredits(userId)` - Give 11 free credits to new user
   
   - `access_control_service.dart`
     - `checkProblemAccess(userId, problemId)` - Check package + credit access
     - `checkPackageAccess(userId, problemId)` - Check if problem in content_access
     - `grantAccess(userId, problemId, creditCost)` - Deduct credits and grant access
     - `isProblemAccessible(userId, problemId)` - Check if user can access problem
   
   - `mantra_ai_service.dart`
     - `generateMantra(text, problemId, userId, chatHistory)` - Call Edge Function
     - `buildChatContext(chatHistory)` - Build context for AI
     - Handle API errors and retries
   
   - `chat_service.dart`
     - `saveChatMessage(userId, message, isUser)` - Save to chat_history JSONB
     - `getChatHistory(userId)` - Get chat history
     - `clearChatHistory(userId)` - Clear chat history
     - `updateAccessedProblems(userId, problemId)` - Add to accessed problems JSONB

2. **Service Features**
   - Business logic separated from repositories
   - Credit deduction logic (free credits first)
   - Access control logic (package + credits)
   - Error handling and validation

**Deliverables**:
- ✅ All services created
- ✅ Credit deduction logic working
- ✅ Access control logic working
- ✅ AI service integrated

---

### **PHASE 5: ViewModels Layer** ⏱️ Priority: HIGH
**Goal**: Create state management with Provider

#### Tasks:
1. **Create ViewModels** (`lib/features/mantra_generator/viewmodels/`)
   - `problem_list_viewmodel.dart`
     - State: List<MainProblem>, List<SubProblem>, loading, error
     - Methods: loadProblems(), loadSubProblems(), searchProblems()
     - Uses: ProblemRepository
   
   - `chat_viewmodel.dart`
     - State: List<ChatMessage>, currentProblem, credits, loading, error
     - Methods: sendMessage(), clearChat(), loadChatHistory()
     - Uses: MantraAIService, ChatService, CreditService
   
   - `package_viewmodel.dart`
     - State: List<ChatbotPackage>, userActivePackage, loading, error
     - Methods: loadPackages(), purchasePackage(), getUserPackage()
     - Uses: PackageRepository, PaymentRepository
   
   - `credit_viewmodel.dart`
     - State: freeCredits, topupCredits, totalCredits, creditsConsumed
     - Methods: loadCredits(), refreshCredits()
     - Uses: CreditService, UserAIUsageRepository

2. **ViewModel Features**
   - Extend ChangeNotifier
   - Loading and error states
   - Cache management
   - Notify listeners on state changes

**Deliverables**:
- ✅ All viewmodels created
- ✅ State management working
- ✅ Provider integration ready

---

### **PHASE 6: Problem Browsing UI** ⏱️ Priority: MEDIUM
**Goal**: Create UI for browsing problems

#### Tasks:
1. **Create Views** (`lib/features/mantra_generator/views/`)
   - `problem_list_screen.dart`
     - Display main problems in expandable cards
     - Show credit cost badges (💳 X credits) for paid problems
     - Show linked content count
     - Expand to show sub-problems
     - Search/filter functionality
     - Uses: ProblemListViewModel
   
   - `widgets/problem_card.dart`
     - Card widget for main problem
     - Credit cost badge (orange color)
     - Lock icon for paid problems
     - Expandable sub-problems list
   
   - `widgets/sub_problem_card.dart`
     - Card widget for sub-problem
     - Credit cost badge
     - Click to access (with credit check)

2. **UI Features**
   - Orange theme (#FF6B35)
   - Credit cost badges
   - Loading states
   - Empty states
   - Error handling

**Deliverables**:
- ✅ Problem list screen
- ✅ Problem cards with credit badges
- ✅ Sub-problem expansion
- ✅ Search functionality

---

### **PHASE 7: AI Chat Interface** ⏱️ Priority: HIGH
**Goal**: Create chat interface for AI mantra generation

#### Tasks:
1. **Create Chat Views** (`lib/features/mantra_generator/views/`)
   - `chat_screen.dart`
     - Chat message list (user/AI messages)
     - Message input field
     - Send button
     - Credit display in app bar
     - Loading indicator
     - Uses: ChatViewModel
   
   - `widgets/chat_message_bubble.dart`
     - User message (right-aligned, blue)
     - AI message (left-aligned, grey)
     - Timestamp
     - Copy/share buttons
   
   - `widgets/credit_display_widget.dart`
     - Show free credits, package credits, total
     - Progress bar for usage
     - Low credit warning

2. **Chat Features**
   - Send message → Call AI service → Deduct credits → Display response
   - Maintain chat history (JSONB)
   - Clear chat option
   - Copy mantra to clipboard
   - Share mantra
   - Credit deduction per question (1 credit default)

**Deliverables**:
- ✅ Chat screen implemented
- ✅ Chat message bubbles
- ✅ AI integration working
- ✅ Credit deduction on each question

---

### **PHASE 8: Package Purchase Flow** ⏱️ Priority: MEDIUM
**Goal**: Implement package selection and purchase

#### Tasks:
1. **Create Package Views** (`lib/features/mantra_generator/views/`)
   - `package_list_screen.dart`
     - Display available packages (starter, premium, ultimate)
     - Show features, pricing, AI question limit
     - Show accessible problems count
     - Highlight recommended package
     - Uses: PackageViewModel
   
   - `package_purchase_screen.dart`
     - Package details
     - Payment integration (Razorpay)
     - Success/error handling
     - Uses: PackageViewModel, existing PaymentService

2. **Purchase Flow**
   - Select package → Initialize Razorpay → Complete payment
   - Create payment record in `user_payments`
   - Update `topup_credits` in `user_ai_usage`
   - Update `plan_details` JSONB
   - Refresh credit display

**Deliverables**:
- ✅ Package list screen
- ✅ Payment integration working
- ✅ Credits updated after purchase
- ✅ Access updated after purchase

---

### **PHASE 9: Content Linking & Navigation** ⏱️ Priority: LOW
**Goal**: Display linked content and navigate to detail screens

#### Tasks:
1. **Content Preview Widgets** (`lib/features/mantra_generator/views/widgets/`)
   - `linked_content_preview.dart` - Show linked content cards
   - Audio preview → Navigate to `AudioPlayerScreen`
   - Ebook preview → Navigate to `PdfViewerScreen`
   - Mantra display → Show mantra text
   - Store item preview → Navigate to `ProductDetailScreen`
   - Puja preview → Navigate to `PujaDetailScreen`
   - Astrologer card → Navigate to `AstrologerDetailScreen`

2. **Navigation Integration**
   - Use existing services: `AudioEbookService`, `PujaService`, `StoreService`, `AstrologerRepository`
   - Navigate to existing detail screens
   - Pass content IDs correctly

**Deliverables**:
- ✅ Content previews displayed
- ✅ Navigation to detail screens working

---

### **PHASE 10: Home FAB Integration** ⏱️ Priority: HIGH
**Goal**: Add chatbot FAB to home screen

#### Tasks:
1. **Home Screen Integration**
   - Add FloatingActionButton with chatbot icon
   - On click → Navigate to Mantra Generator main screen
   - Position: Bottom right (or as per design)

2. **Main Screen (Entry Point)**
   - `mantra_generator_screen.dart`
     - Tab 1: Problems List
     - Tab 2: My Chat History
     - Tab 3: Packages
     - Credit display in app bar
     - Uses: Multiple ViewModels

**Deliverables**:
- ✅ FAB added to home screen
- ✅ Navigation working
- ✅ Main screen with tabs

---

### **PHASE 11: Access Tracking & JSONB Storage** ⏱️ Priority: MEDIUM
**Goal**: Track accessed problems and chat history in JSONB

#### Tasks:
1. **Access Tracking**
   - When user accesses a problem → Add to `accessed_problems` JSONB in `user_ai_usage`
   - Check if already accessed (prevent duplicate credit deduction)
   - Display "Already Accessed" badge

2. **Chat History Storage**
   - Store chat messages in `chat_history` JSONB
   - Store chat questions in `chat_question` JSONB
   - Load chat history on screen open
   - Maintain context for AI

**Deliverables**:
- ✅ Access tracking working
- ✅ Chat history persisted
- ✅ Duplicate access prevention

---

### **PHASE 12: Testing & Polish** ⏱️ Priority: MEDIUM
**Goal**: Test all features and polish UI/UX

#### Tasks:
1. **Functionality Testing**
   - Test credit deduction (free credits first)
   - Test access control (package + credits)
   - Test package purchase flow
   - Test AI chat with credit deduction
   - Test edge cases (zero credits, no package, etc.)
   - Test JSONB storage and retrieval

2. **UI/UX Polish**
   - Consistent styling with app theme (Orange)
   - Loading states
   - Error messages
   - Empty states
   - Animations
   - Hindi/English support

3. **Performance Optimization**
   - Cache problems/packages
   - Lazy load sub-problems
   - Optimize API calls
   - Optimize JSONB queries

**Deliverables**:
- ✅ All features tested
- ✅ UI polished
- ✅ Performance optimized
- ✅ Hindi/English support

---

## 📁 Detailed Folder Structure

```
lib/features/mantra_generator/
├── models/
│   ├── main_problem_model.dart
│   ├── sub_problem_model.dart
│   ├── chatbot_package_model.dart
│   ├── user_ai_usage_model.dart
│   ├── chat_message_model.dart
│   └── access_status_model.dart
│
├── repositories/
│   ├── problem_repository.dart
│   ├── package_repository.dart
│   ├── user_ai_usage_repository.dart
│   └── payment_repository.dart
│
├── services/
│   ├── credit_service.dart
│   ├── access_control_service.dart
│   ├── mantra_ai_service.dart
│   └── chat_service.dart
│
├── viewmodels/
│   ├── problem_list_viewmodel.dart
│   ├── chat_viewmodel.dart
│   ├── package_viewmodel.dart
│   └── credit_viewmodel.dart
│
└── views/
    ├── mantra_generator_screen.dart (Main entry with tabs)
    ├── problem_list_screen.dart
    ├── chat_screen.dart
    ├── package_list_screen.dart
    ├── package_purchase_screen.dart
    └── widgets/
        ├── problem_card.dart
        ├── sub_problem_card.dart
        ├── chat_message_bubble.dart
        ├── credit_display_widget.dart
        ├── linked_content_preview.dart
        └── package_card.dart
```

---

## ✅ **Answers Confirmed:**

1. **Credit Deduction**: User clicks problem → Check credits → Deduct credits → Grant access
2. **AI Question Credits**: Default 1 credit per question
3. **Problem Access**: Deduct `credit_cost` when accessing problem, then 1 credit per AI question
4. **Package Access**: Array of problem IDs = accessible, empty array = no access
5. **Accessed Problems**: Store in `user_ai_usage.accessed_problems` JSONB array
6. **AI Question Limit**: Use `ai_question_limit` from `chatbot_packages` table (Option 1)
7. **Chat History**: Store in `chat_history` and `chat_question` JSONB arrays
8. **Home FAB**: Yes, FloatingActionButton with chatbot icon
9. **Main Screen**: Single screen with tabs (Problems, Chat, Packages), credit display always visible
10. **Credit Cost Column**: Already exists in schema ✅
11. **Initial Credits**: Yes, 11 free credits via trigger/function

---

## 🚀 Recommended Starting Point

**Start with Phase 1** - Backend setup:
1. Review schema recommendations (see `docs/SCHEMA_REVIEW_AND_RECOMMENDATIONS.md`)
2. Run migration script (`sql/mantra_generator_schema_migration.sql`)
3. Create Supabase Edge Function
4. Verify database tables

Then proceed with **Phase 2** - Folder structure and models.

---

## 📝 Notes

- **Architecture**: MVVM + Repositories + Services (5 folders)
- **Security**: OpenAI API key in Supabase Secret Variables
- **Credits**: Default 11 free credits (via trigger), deducted after access
- **Credit Flow**: Access problem (deduct `credit_cost`) → Chat (deduct 1 credit per question)
- **AI Question Limit**: Track using `ai_question_limit` from `chatbot_packages` table
- **Caching**: Use existing `CacheService` pattern
- **State Management**: Provider ChangeNotifier in ViewModels
- **Styling**: Orange theme (#FF6B35), match existing app design
- **Language**: Hindi/English using `LanguageService`
- **Navigation**: Home FAB → Mantra Generator (single screen with tabs)
- **Schema**: See `docs/SCHEMA_REVIEW_AND_RECOMMENDATIONS.md` for improvements

---

## 🎯 Success Criteria

- ✅ Users can browse problems and see credit costs
- ✅ Users can chat with AI and get mantra recommendations
- ✅ Credits are deducted correctly (free first, then topup)
- ✅ Problem access deducts `credit_cost`, then 1 credit per AI question
- ✅ Package purchase updates credits and access
- ✅ Access control works (package + credits)
- ✅ Accessed problems tracked in JSONB (`accessed_problems`)
- ✅ Chat history persisted in JSONB (`chat_history`, `chat_question`)
- ✅ AI question limit tracked using `ai_question_limit` from package
- ✅ All linked content displays and navigates correctly
- ✅ UI matches app design language (Orange theme)
- ✅ Hindi/English support working
- ✅ Home FAB opens Mantra Generator
- ✅ Single screen with tabs (Problems, Chat, Packages)
- ✅ Credit display always visible

---

## 📋 **Schema Improvements Required**

**See `docs/SCHEMA_REVIEW_AND_RECOMMENDATIONS.md` for complete details:**

### Critical Additions:
1. ✅ Add `accessed_problems` JSONB column to `user_ai_usage`
2. ✅ Add indexes for performance (especially `user_id` columns)
3. ✅ Add `updated_at` columns with auto-update triggers
4. ✅ Add foreign key constraints
5. ✅ Add check constraints for data validation
6. ✅ Add trigger to initialize 11 free credits for new users

**Run the migration script (`sql/mantra_generator_schema_migration.sql`) before starting implementation!**

---

**Ready to start implementation!** 🚀

**Next Steps:**
1. Review schema recommendations
2. Run migration script
3. Start Phase 1: Backend Setup

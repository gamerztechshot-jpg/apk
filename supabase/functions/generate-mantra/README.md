# Generate Mantra Edge Function

This Supabase Edge Function generates personalized mantras using OpenAI API and integrates with chat functionality, credit management, and chat history storage.

## Setup

1. **Set required environment variables in Supabase Secrets:**
   ```bash
   supabase secrets set OPENAI_API_KEY=your-openai-api-key-here
   ```
   
   Note: `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are automatically available in Edge Functions.

2. **Deploy the function:**
   ```bash
   supabase functions deploy generate-mantra
   ```

## API Endpoint

After deployment, the function will be available at:
```
https://fwhblztexcyxjrfhrrsb.supabase.co/functions/v1/generate-mantra
```

## Request Format

```json
{
  "text": "I am feeling stressed about my exams",
  "language": "en",
  "userId": "user-uuid-here",
  "problemId": "optional-problem-uuid",
  "chatHistory": [
    {
      "role": "user",
      "content": "Previous question"
    },
    {
      "role": "assistant",
      "content": "Previous response"
    }
  ]
}
```

### Request Parameters

- `text` (required): The user's question or problem description (max 300 characters)
- `language` (optional): Language preference - "hi" or "en" (default: "hi")
- `userId` (optional): User UUID for credit deduction and chat history storage
- `problemId` (optional): Problem UUID for associating chat with specific problems
- `chatHistory` (optional): Array of previous chat messages for context

## Response Format

```json
{
  "reply": "Om Shantih Shantih Shantih, Buddhi Prakasham Dhairya",
  "mantra": "Om Shantih Shantih Shantih, Buddhi Prakasham Dhairya"
}
```

## Features

### Credit Management
- **Non-package users**: Deducts 1 credit from `free_credits_left` or `topup_credits`
- **Package users**: Reduces `aiQuestionLimit` in `plan_details`
- Automatically initializes user credits (11 free credits) if user doesn't exist

### Chat History Storage
- Stores question in `ai_question` column
- Stores response in `ai_response` column
- Updates `chat_history` JSONB array with user and AI messages
- Updates `chat_question` JSONB array for drawer display (includes question, problemId, timestamp, creditsDeducted)

### Error Responses

- `400`: Invalid input (missing text, text too long)
- `403`: Insufficient credits or AI question limit reached
- `500`: Server error (OpenAI API error, missing API key, database error)

## Database Schema

The function interacts with the `user_ai_usage` table:
- `user_id`: User UUID
- `free_credits_left`: Free credits remaining
- `topup_credits`: Purchased credits
- `credits_consumed`: Total credits used
- `ai_question`: Last question asked
- `ai_response`: Last AI response
- `chat_history`: JSONB array of chat messages
- `chat_question`: JSONB array of questions for drawer display
- `plan_details`: JSONB object containing package information (including `aiQuestionLimit`)

## Testing

Test locally:
```bash
supabase functions serve generate-mantra
```

Test with curl:
```bash
curl -X POST \
  https://fwhblztexcyxjrfhrrsb.supabase.co/functions/v1/generate-mantra \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "I am stressed",
    "userId": "user-uuid-here"
  }'
```

## Notes

- The function gracefully handles cases where `userId` is not provided (backward compatibility)
- Credit deduction and storage only occur if `userId` is provided
- Chat history is maintained per user and can be filtered by `problemId`
- The drawer feature uses `chat_question` array to display previous questions

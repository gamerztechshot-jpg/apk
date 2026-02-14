// Type definitions

export interface RequestBody {
  text: string;
  language?: "hi" | "en";
  userId?: string;
  problemId?: string;
  sessionId?: string;
  chatHistory?: Array<{
    role: "user" | "assistant";
    content: string;
  }>;
}

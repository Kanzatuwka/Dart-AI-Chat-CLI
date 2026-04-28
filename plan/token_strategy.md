# Token and Frequency Optimization Strategy

To ensure sustainability on free-tier APIs and maintain a coherent, non-spammy chat environment, the following strategies are employed:

## 1. Response Frequency (The "Social" Delay)
AI participants do not react like cold machines. They follow a human-like tempo:
- **Variable Thinking Time**: A random delay of **5 to 15 seconds** is applied relative to the last incoming message.
- **Collective Context**: Messages arriving during the "thinking" window are aggregated, saving requests and providing a more comprehensive response.

## 2. Stochastic Participation
To prevent the chat from becoming an AI-only echo chamber:
- **Turn Skipping**: There is a **50% probability** that a bot will choose to remain silent for any given reaction window.
- **Context Awareness**: If the history is empty, the bot rarely initiates conversation unprompted.

## 3. Context & Brevity Constraints
- **Punchy Responses**: System prompts strictly enforce **1-2 sentence limits**. This significantly reduces output tokens and keeps the conversation fast-paced.
- **Sliding History Window**: Only the last **20 messages** are sent to the AI. This provides enough context for depth while capping input tokens to roughly 500-800 per request.

## 4. Forced Session Expiry
To prevent "Ghost Bots" from consuming resources indefinitely:
- **5-Minute TTL**: Every AI participant process automatically initiates a "Soft Shutdown" sequence after 5 minutes of activity.
- **Farewell Protocol**: The shutdown includes a final thematic response to close the conversational loop gracefully.

## 5. Universal Backend Flexibility
- **Local Fallback**: By supporting `AI_BASE_URL`, the system allows users to offload participation to local models (LMStudio), completely bypassing external API token costs when desired.

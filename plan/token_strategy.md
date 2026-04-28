# Token and Frequency Optimization Strategy

To ensure sustainability and respect for the free Gemini API tier, the following measures are implemented:

## 1. Request Debouncing
AI participants do not respond to every message immediately. Instead:
- A 4-second delay is introduced after every incoming message.
- If multiple messages arrive during this window, they are aggregated into a single context for a single response.
- This mimics "thinking/typing" time and prevents API rate-limiting.

## 2. Stochastic Reaction
There is a 30% "passivity" chance for every prompt window. This means the AI might choose *not* to engage if it doesn't have anything meaningful to add, making the interaction feel more like a human who isn't always staring at the screen.

## 3. History Pruning
We only send the last 10 messages of context to the Gemini API. 
- Prevents the token count from growing linearly with chat duration.
- Keeps latency low and ensures we stay well within the `maxOutputTokens` limit.

## 4. Session Timeouts
Each AI participant process is hard-coded to perform a "Soft Shutdown" after 5 minutes.
- Ensures that abandoned sessions don't keep polling or consuming resources.

## 5. Master Prompt Efficiency
The prompts are designed to be concise instructions. By telling the AI to "keep it natural" and "brief," we minimize the response token count, typically keeping outputs under 100 tokens.

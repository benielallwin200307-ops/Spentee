const path = require('path');
const express = require('express');
const cors = require('cors');

// Explicitly load .env from the backend directory regardless of cwd
require('dotenv').config({ path: path.join(__dirname, '.env') });

const app = express();
const PORT = process.env.PORT || 3000;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const MODEL_NAME = process.env.GEMINI_MODEL || 'gemini-3.8-flash';

app.use(cors());
app.use(express.json());

const isConfigured = Boolean(
  GEMINI_API_KEY &&
  GEMINI_API_KEY.trim().length > 10 &&
  !GEMINI_API_KEY.includes('your_') &&
  !GEMINI_API_KEY.includes('here')
);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'Spentee AI Secure Proxy',
    configured: isConfigured,
    model: MODEL_NAME,
    timestamp: new Date().toISOString(),
  });
});

// Chat endpoint
app.post('/api/chat', async (req, res) => {
  try {
    const { message, summary, history } = req.body;

    if (!message || typeof message !== 'string' || !message.trim()) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'The "message" field is required and cannot be empty.',
      });
    }

    if (!isConfigured) {
      return res.status(503).json({
        error: 'Backend Unconfigured',
        message:
          'Spentee AI secure backend is running, but GEMINI_API_KEY is not configured in backend/.env. Please configure your key to enable general AI conversations.',
        setupRequired: true,
      });
    }

    // Build system instructions with strict relevance and constraint adherence
    const systemInstruction = `You are Spentee AI, a genuine, conversational, witty, and trustworthy AI assistant and personal finance companion.
Your core rules:
1. Direct and Relevant Answers: Always answer the user's specific question directly, accurately, and immediately.
2. Adhere to Constraints: If the user specifies a length or format constraint (e.g. "Explain in one sentence", "in 3 bullets", "short summary"), you MUST strictly comply with that exact constraint.
3. No Unsolicited Habit Lectures: When asked a conceptual, educational, or general question (e.g. "What is compound interest?", "What is an index fund?", "How does an SIP work?"), explain the concept directly. Do NOT pivot into unrequested personal financial habit reviews, unsolicited budgeting tips, or lectures about spending habits.
4. Financial Literacy & Clarity: Cover financial literacy, tech, education, career, travel, and everyday topics with clear, structured markdown formatting.
5. Risk & Uncertainty: Clearly communicate uncertainty on investment topics and NEVER guarantee returns.
6. Context Sensitivity: Only reference the user's personal financial figures if the user explicitly asks for advice regarding their own spending, budgets, or savings.`;

    // Construct request contents, ensuring turns alternate cleanly
    const contents = [];

    // Filter history to ensure it strictly alternates and doesn't repeat the current message
    if (Array.isArray(history) && history.length > 0) {
      const pastTurns = history.filter(
        (t) => t && t.text && typeof t.text === 'string' && t.text.trim().length > 0
      );

      // Take up to last 6 turns, dropping the last one if it is an identical duplicate of the current message
      const slice = pastTurns.slice(-6);
      if (
        slice.length > 0 &&
        slice[slice.length - 1].role === 'user' &&
        slice[slice.length - 1].text.trim().toLowerCase() === message.trim().toLowerCase()
      ) {
        slice.pop();
      }

      let lastRole = null;
      for (const turn of slice) {
        const role = turn.role === 'user' ? 'user' : 'model';
        // Avoid consecutive duplicate roles to maintain valid multi-turn contract
        if (role !== lastRole) {
          contents.push({
            role: role,
            parts: [{ text: turn.text.trim() }],
          });
          lastRole = role;
        }
      }

      // Gemini multi-turn requires starting with 'user'
      while (contents.length > 0 && contents[0].role !== 'user') {
        contents.shift();
      }
      // Gemini multi-turn requires ending with 'model' before we append the current 'user' turn
      while (contents.length > 0 && contents[contents.length - 1].role === 'user') {
        contents.pop();
      }
    }

    // Build the prompt for the current turn
    let userPrompt = message.trim();
    // Only prepend financial context if user has consented AND the query explicitly asks for personal advice/analysis
    if (summary && summary.consent === true && summary.include_in_prompt === true) {
      userPrompt = `[User Financial Context: Month: ${summary.month || 'Current'}, Monthly Spend: ₹${summary.monthly_spend_total || '0'}, Monthly Income: ₹${summary.monthly_income_total || '0'}, Top Outflows: ${JSON.stringify(summary.top_expense_categories_share || {})}]\n\nUser Question: ${userPrompt}`;
    }

    contents.push({
      role: 'user',
      parts: [{ text: userPrompt }],
    });

    const candidateModels = [
      MODEL_NAME,
      'gemini-3.5-flash',
      'gemini-3.7-flash',
      'gemini-3.1-flash-lite',
    ].filter((v, i, a) => Boolean(v) && a.indexOf(v) === i);

    let succeededReply = null;
    let succeededModel = null;
    let lastErrorStatus = 500;
    let lastErrorMessage = 'Failed to generate response.';

    for (const activeModel of candidateModels) {
      const endpointUrl = `https://generativelanguage.googleapis.com/v1beta/models/${activeModel}:generateContent?key=${GEMINI_API_KEY}`;
      const abortController = new AbortController();
      const timeoutHandle = setTimeout(() => abortController.abort(), 20000);

      try {
        const apiResponse = await fetch(endpointUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            systemInstruction: { parts: [{ text: systemInstruction }] },
            contents: contents,
            generationConfig: {
              temperature: 0.7,
              maxOutputTokens: 800,
              topP: 0.95,
            },
          }),
          signal: abortController.signal,
        });

        if (apiResponse.ok) {
          const data = await apiResponse.json();
          const candidate = data.candidates?.[0];
          succeededReply =
            candidate?.content?.parts?.[0]?.text ||
            'I processed your query, but could not produce a response at this time. Please try asking again.';
          succeededModel = activeModel;
          break;
        }

        const errorText = await apiResponse.text();
        let errorJson = {};
        try {
          errorJson = JSON.parse(errorText);
        } catch (_) {}

        lastErrorStatus = apiResponse.status;
        lastErrorMessage =
          errorJson?.error?.message || `Upstream AI provider error (${apiResponse.status})`;
        console.warn(`Model ${activeModel} returned ${apiResponse.status}: ${lastErrorMessage}`);

        // If rate limit (429), fail fast to inform user
        if (apiResponse.status === 429) {
          return res.status(429).json({
            error: 'Rate Limit Exceeded',
            message:
              'Spentee AI backend reached its AI provider rate limit. Please retry in a moment.',
          });
        }
        // If 503 (high demand) or 404 (unavailable), continue to next candidate model
      } catch (callErr) {
        if (callErr.name === 'AbortError') {
          console.warn(`Model ${activeModel} timed out after 20s`);
          lastErrorStatus = 504;
          lastErrorMessage = 'The AI model took too long to respond.';
        } else {
          console.warn(`Model ${activeModel} network error:`, callErr.message);
        }
      } finally {
        clearTimeout(timeoutHandle);
      }
    }

    if (succeededReply != null) {
      return res.json({
        reply: succeededReply.trim(),
        model: succeededModel,
        status: 'ok',
      });
    }

    if (lastErrorStatus === 504) {
      return res.status(504).json({
        error: 'Gateway Timeout',
        message: 'The AI model took too long to respond. Please retry your question.',
      });
    }

    return res.status(502).json({
      error: 'AI Provider Error',
      message: `Upstream AI provider error (${lastErrorStatus}): ${lastErrorMessage}`,
    });
  } catch (err) {
    if (err.name === 'AbortError') {
      console.error('Gemini API Request timed out after 20s');
      return res.status(504).json({
        error: 'Gateway Timeout',
        message: 'The AI model took too long to respond. Please retry your question.',
      });
    }
    console.error('Server error in /api/chat:', err);
    return res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to process AI chat query. Please try again.',
    });
  }
});

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`Spentee AI Secure Proxy running on http://0.0.0.0:${PORT} (http://localhost:${PORT})`);
  console.log(
    `API Key Status: ${
      GEMINI_API_KEY && GEMINI_API_KEY.length > 10 ? 'Configured ✅' : 'Missing ⚠️'
    }`
  );
  console.log(`Configured Model: ${MODEL_NAME}`);
});

process.on('SIGINT', () => {
  server.close(() => process.exit(0));
});
process.on('SIGTERM', () => {
  server.close(() => process.exit(0));
});

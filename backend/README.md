# Spentee AI — Secure Backend Service

This backend service acts as a secure, trusted proxy between the Spentee Flutter mobile application and AI providers (such as Google Gemini).

## Security & Architecture Highlights
- **Zero Client-Side Secrets**: Your AI provider API keys (`GEMINI_API_KEY`) stay strictly on the server and are never packaged inside the Flutter APK or source code.
- **Privacy Enforcement**: Private, unaggregated financial transaction records are never sent over the wire. Only high-level, anonymized summary metrics are transmitted when the user explicitly grants data analysis consent.
- **Financial Safety**: All calculations (spending, income, budgets, category aggregates) are computed deterministically on the device; the AI model is never relied upon for raw arithmetic.

## Quick Start

1. Install dependencies:
   ```bash
   npm install
   ```

2. Copy `.env.example` to `.env` and add your Gemini API Key:
   ```bash
   cp .env.example .env
   ```
   *(Obtain a key at https://aistudio.google.com/app/apikey)*

3. Start the server:
   ```bash
   npm start
   ```
   The server will run on `http://localhost:3000`.

## API Endpoints

- **`GET /health`**: Health check and configuration status.
- **`POST /api/chat`**: General conversational AI queries with privacy summary support.

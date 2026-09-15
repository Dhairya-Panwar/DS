# 📚 Secure Enterprise RAG Assistant

An end-to-end **Retrieval-Augmented Generation (RAG)** application that lets users upload a PDF and ask questions grounded strictly in that document. Built with **Google Gemini**, **ChromaDB**, and **Streamlit**, with explicit anti-hallucination guardrails and transparent source citation.

Live document Q&A with zero hallucination tolerance — if the answer isn't in the document, the assistant says so instead of making it up.

---

## Overview

This project implements a full RAG pipeline from scratch:

1. A user uploads a PDF through the sidebar.
2. The document is parsed, chunked, and embedded into a vector database.
3. A user question is embedded and matched against the most relevant chunks.
4. Those chunks are injected into a strictly guardrailed prompt sent to an LLM.
5. The model answers **only** from the retrieved context, citing the exact chunk it used — or explicitly refuses if the answer isn't present.

The goal was to build something closer to a production RAG pattern than a toy demo: explicit guardrails, deterministic output, and visible source attribution.

---

## Features

- **Semantic Search** — Uses Google's `gemini-embedding-001` model to embed document chunks and queries into a shared vector space for similarity search.
- **Anti-Hallucination Guardrails** — A strict system prompt instructs the model to answer only from retrieved context, combined with `temperature=0.0` for deterministic, non-creative output. If the answer isn't in the document, the model is required to say so instead of guessing.
- **Source Citation** — Every answer cites the specific chunk number it drew from (e.g. `[Chunk 2]`), and the full retrieved chunks are viewable in an expandable panel for auditability.
- **Ephemeral Vector Database** — Each session spins up a fresh in-memory ChromaDB instance via `EphemeralClient()`, so uploaded documents are indexed on the fly with no persistent storage or data leakage between sessions.
- **Graceful Failure Handling** — API calls are wrapped in error handling so a failed generation request degrades to a clear message instead of crashing the app.

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI / App Framework | [Streamlit](https://streamlit.io/) |
| LLM | Google Gemini (`gemini-3.6-flash`) |
| Embeddings | Google Gemini (`gemini-embedding-001`) |
| Vector Database | [ChromaDB](https://www.trychroma.com/) (ephemeral, in-memory) |
| Text Chunking | LangChain's `RecursiveCharacterTextSplitter` |
| PDF Parsing | `pypdf` |
| Config / Secrets | `python-dotenv` |

---

## How It Works (Architecture)

```
PDF Upload
    │
    ▼
pypdf → extract raw text
    │
    ▼
RecursiveCharacterTextSplitter → chunk_size=500, overlap=100
    │
    ▼
Gemini Embeddings (gemini-embedding-001) → vector representations
    │
    ▼
ChromaDB (ephemeral, in-memory) → indexed chunks
    │
    ▼
User Question ──► Embedded ──► Top-3 similar chunks retrieved
    │
    ▼
Guardrailed Prompt (system instruction + context + question)
    │
    ▼
Gemini 3.6 Flash (temperature=0.0) → grounded answer + chunk citation
    │
    ▼
Streamlit Chat UI → answer + expandable source chunks
```

---

## Guardrail Design

The system prompt enforces three explicit rules on the model:

1. **Context-only answering** — no outside knowledge, no assumptions.
2. **Explicit refusal** — if the answer isn't in the retrieved context, the model must respond: *"I cannot answer this based on the provided documents."*
3. **Inline citation** — every claim must reference the chunk it came from, e.g. `[Chunk 1]`.

This was validated with three test cases:

| Test | Example Question | Expected Behavior |
|---|---|---|
| In-scope | A question directly answered in the uploaded PDF | Correct answer with a `[Chunk X]` citation |
| Out-of-scope | "Who won the World Cup in 2022?" | Explicit refusal — no hallucination |
| Ambiguous | "What is the policy?" | Synthesizes across the top 3 retrieved chunks |

---

## Project Structure

```
Enterprise_RAG_App/
│
├── app.py              # Main Streamlit application
├── requirements.txt    # Python dependencies
├── .env                # API keys (not committed)
├── .gitignore          # Excludes venv, .env, and local DB files
└── README.md           # This file
```

---

## How to Run Locally

**1. Clone the repository**
```bash
git clone https://github.com/YOUR_USERNAME/Enterprise_RAG_App.git
cd Enterprise_RAG_App
```

**2. Create and activate a virtual environment**
```bash
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate
```

**3. Install dependencies**
```bash
pip install -r requirements.txt
```

**4. Add your API key**

Create a `.env` file in the project root:
```
GEMINI_API_KEY=your_actual_api_key_here
```

**5. Run the app**
```bash
streamlit run app.py
```

The app will open at `http://localhost:8501`.

---

## Usage

1. Upload a PDF (e.g. an employee handbook, research paper, or policy document) from the sidebar.
2. Wait for the "Indexed N chunks successfully!" confirmation.
3. Ask a question in the chat box.
4. Review the answer, and expand **"View Retrieved Sources"** to see exactly which chunks were used to generate it.

---

## Design Decisions & Trade-offs

- **Ephemeral over persistent storage**: Chosen to keep the app stateless and avoid leaking document content across sessions or users — a deliberate security-conscious choice for an "enterprise" tool handling potentially sensitive documents.
- **Temperature 0.0**: Prioritizes factual consistency over creative phrasing, which is the right trade-off for a document Q&A tool where hallucination is a bigger risk than repetitive wording.
- **Top-3 retrieval**: A balance between giving the model enough context to synthesize an answer and keeping the prompt small enough to stay fast and cheap.

---

## Possible Future Improvements

- Support multiple PDFs indexed into a single session.
- Add a persistent vector store option for returning users.
- Stream LLM responses token-by-token for a more responsive feel.
- Add automated evaluation of guardrail adherence across a test question set.

---

## Author
 
Built by Rahul as part of the **BE Practical** Training, focused on practical, production-style RAG patterns rather than notebook-only prototypes.
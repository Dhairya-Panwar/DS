import os
import streamlit as st
import chromadb

from chromadb.api.types import Documents, EmbeddingFunction, Embeddings
from pypdf import PdfReader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from dotenv import load_dotenv

# Official Google GenAI SDK
from google import genai
from google.genai import types


# ==============================================================================
# LOAD ENVIRONMENT VARIABLES
# ==============================================================================

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")


# ==============================================================================
# INITIALIZE GEMINI CLIENT
# ==============================================================================

if not GEMINI_API_KEY:
    st.error("🚨 GEMINI_API_KEY missing. Please add it to your .env file.")
    st.stop()

client = genai.Client(api_key=GEMINI_API_KEY)


# ==============================================================================
# CUSTOM EMBEDDING FUNCTION
# ==============================================================================

class GeminiEmbeddingFunction(EmbeddingFunction):
    """
    Custom ChromaDB embedding function using Google Gemini embeddings.
    """

    def __call__(self, input: Documents) -> Embeddings:

        response = client.models.embed_content(
        model="gemini-embedding-001",
        contents=input)

        return [emb.values for emb in response.embeddings]


# ==============================================================================
# STREAMLIT PAGE CONFIGURATION
# ==============================================================================

st.set_page_config(
    page_title="Enterprise RAG Assistant",
    page_icon="📚",
    layout="wide"
)

st.title("📚 Secure Enterprise Document RAG")

st.markdown(
    "Upload a PDF document and ask questions. "
    "The AI will cite its sources."
)


# ==============================================================================
# INITIALIZE SESSION STATE
# ==============================================================================

if "messages" not in st.session_state:
    st.session_state.messages = []

if "collection" not in st.session_state:
    st.session_state.collection = None


# ==============================================================================
# SIDEBAR: DOCUMENT INGESTION
# ==============================================================================

with st.sidebar:

    st.header("📄 Document Ingestion")

    uploaded_file = st.file_uploader(
        "Upload a PDF",
        type="pdf"
    )

    if (
        uploaded_file is not None
        and st.session_state.collection is None
    ):

        with st.spinner("Parsing and chunking document..."):

            # ------------------------------------------------------------------
            # 1. READ PDF
            # ------------------------------------------------------------------

            reader = PdfReader(uploaded_file)

            raw_text = ""

            for page in reader.pages:
                text = page.extract_text()

                if text:
                    raw_text += text + "\n"


            # ------------------------------------------------------------------
            # 2. CHUNK TEXT
            # ------------------------------------------------------------------

            splitter = RecursiveCharacterTextSplitter(
                chunk_size=500,
                chunk_overlap=100
            )

            chunks = splitter.split_text(raw_text)


            # ------------------------------------------------------------------
            # 3. INITIALIZE EPHEMERAL CHROMADB
            # ------------------------------------------------------------------
            chroma_client = chromadb.EphemeralClient()
            collection = chroma_client.get_or_create_collection(
            name="temp_doc_db",
            embedding_function=GeminiEmbeddingFunction()
            )


            # ------------------------------------------------------------------
            # 4. INGEST DOCUMENT
            # ------------------------------------------------------------------

            ids = [
                f"chunk_{i}"
                for i in range(len(chunks))
            ]

            metadatas = [
                {
                    "source": uploaded_file.name,
                    "chunk": i
                }
                for i in range(len(chunks))
            ]

            collection.add(
                documents=chunks,
                ids=ids,
                metadatas=metadatas
            )


            # ------------------------------------------------------------------
            # 5. SAVE COLLECTION IN SESSION STATE
            # ------------------------------------------------------------------

            st.session_state.collection = collection

            st.success(
                f"✅ Indexed {len(chunks)} chunks successfully!"
            )


# ==============================================================================
# DISPLAY CHAT HISTORY
# ==============================================================================

for msg in st.session_state.messages:

    with st.chat_message(msg["role"]):

        st.markdown(msg["content"])

        if "sources" in msg:

            with st.expander("View Retrieved Sources"):

                for source in msg["sources"]:
                    st.info(source)


# ==============================================================================
# STUDENT LAB WORKSPACE: RETRIEVAL, GUARDRAILS & GENERATION
# ==============================================================================

prompt = st.chat_input("Ask a question about your document")

if prompt:

    if st.session_state.collection is None:
        st.warning("Please upload a PDF first.")
        st.stop()

    st.session_state.messages.append({"role": "user", "content": prompt})

    with st.chat_message("user"):
        st.markdown(prompt)

    with st.chat_message("assistant"):

        with st.spinner("Thinking..."):

            # ------------------------------------------------------------------
            # TODO 1: Retrieve Context from the Vector Database
            # ------------------------------------------------------------------

            results = st.session_state.collection.query(
                query_texts=[prompt],
                n_results=3
            )

            retrieved_chunks = results["documents"][0]

            context_text = ""
            source_list = []

            for i, chunk in enumerate(retrieved_chunks):
                context_text += f"[Chunk {i + 1}]: {chunk}\n\n"
                source_list.append(f"Chunk {i + 1}: {chunk}")

            # ------------------------------------------------------------------
            # TODO 2: Build the Guardrailed Prompt Template
            # ------------------------------------------------------------------

            system_instruction = (
                "You are a strict Enterprise Q&A Assistant. "
                "Answer the user's question ONLY using the context provided below. "
                "Do not use any outside knowledge or make assumptions. "
                "If the answer is not contained in the context, explicitly state: "
                "'I cannot answer this based on the provided documents.' Do NOT hallucinate. "
                "When you use information from the context, cite the chunk number inline, "
                "for example [Chunk 1]."
            )

            user_payload = f"Context:\n{context_text}\nQuestion: {prompt}"

            # ------------------------------------------------------------------
            # TODO 3: Execute the LLM Generation
            # ------------------------------------------------------------------

            try:

                response = client.models.generate_content(
            model="gemini-3.6-flash",
            contents=user_payload,
            config=types.GenerateContentConfig(
            system_instruction=system_instruction,
            temperature=0.0
            )
        )

                final_answer = response.text

            except Exception as error:
                final_answer = f"An error occurred while generating the answer: {error}"

            st.markdown(final_answer)

            with st.expander("View Retrieved Sources"):
                for source in source_list:
                    st.info(source)

            st.session_state.messages.append({
                "role": "assistant",
                "content": final_answer,
                "sources": source_list
            })
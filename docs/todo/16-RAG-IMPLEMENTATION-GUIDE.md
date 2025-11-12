# RAG Implementation Guide - Complete Task Guide
## AI Agent Instructions for RAG-Enhanced FKS Platform

**Date**: 2025-01-XX  
**Status**: Ready for Implementation  
**Purpose**: Step-by-step guide for AI agents to implement RAG (Retrieval-Augmented Generation) across FKS services  
**Estimated Effort**: 200-300 hours over 6-8 weeks  
**Prerequisites**: Understanding of FKS architecture, LangChain, vector databases

---

## 🎯 Project Overview

**Objective**: Integrate RAG (Retrieval-Augmented Generation) into FKS platform to enable intelligent documentation analysis, signal refinement, and knowledge-driven decision making while maintaining service boundaries and manual-first principles.

**Key Deliverables**:
1. RAG system in fks_analyze for documentation analysis (300+ docs)
2. Advanced RAG in fks_ai for signal refinement (HyDE, RAPTOR, self-correction)
3. Semantic routing in fks_api for intelligent query distribution
4. Evaluation framework (RAGAS/deepeval) for RAG quality
5. HFT-inspired network structure and schema improvements

**Success Criteria**:
- 25-40% improvement in code review efficiency
- 15-30% signal accuracy improvement via RAG refinement
- Natural language queries for 300+ documentation files
- RAGAS faithfulness scores >0.9
- Zero-downtime RAG deployments

---

## 📋 Phase 1: RAG Foundation in fks_analyze (Weeks 1-2)

### Task 1.1: Set Up RAG Infrastructure

**Objective**: Install and configure RAG components in fks_analyze with Gemini API and Ollama hybrid support

**Actions for AI Agent**:

1. **Update fks_analyze dependencies**:
   ```bash
   cd repo/analyze
   # Update requirements.txt
   ```
   
   **Add to `repo/analyze/requirements.txt`**:
   ```
   # RAG Core
   langchain>=0.3.0
   langchain-community>=0.3.0
   langchain-core>=0.3.0
   langchain-text-splitters>=0.3.0
   
   # Vector Store
   chromadb>=0.4.0
   pgvector>=0.2.0  # For PostgreSQL vector storage
   
   # Embeddings - Gemini API (Free Tier)
   langchain-google-genai>=1.0.0
   google-generativeai>=0.3.0
   
   # Embeddings - Local (Ollama)
   sentence-transformers>=2.2.0
   ollama>=0.1.0
   langchain-ollama>=0.1.0
   
   # Document Loaders
   langchain-community[web-base]>=0.3.0
   pypdf>=3.17.0
   python-docx>=1.1.0
   markdown>=3.5.0
   
   # Evaluation
   ragas>=0.1.0
   deepeval>=0.15.0
   
   # Advanced RAG
   langgraph>=0.2.0
   langchain-experimental>=0.3.0
   ```

2. **Create RAG configuration**:
   ```
   File: repo/analyze/src/rag/config.py
   Content:
   import os
   from typing import Optional, Dict
   from datetime import datetime
   from pydantic import BaseModel
   
   class RAGConfig(BaseModel):
       """RAG configuration with Gemini API and Ollama hybrid support"""
       
       # Vector Store
       vector_store_type: str = os.getenv("RAG_VECTOR_STORE", "chroma")  # chroma or pgvector
       chroma_persist_dir: str = os.getenv("RAG_CHROMA_DIR", "./chroma_db")
       pgvector_connection: Optional[str] = os.getenv("RAG_PGVECTOR_CONNECTION")
       
       # Embeddings - Gemini API (Free Tier: 1,500-10,000 grounded prompts/day)
       gemini_api_key: Optional[str] = os.getenv("GOOGLE_AI_API_KEY")
       gemini_embedding_model: str = os.getenv("GEMINI_EMBEDDING_MODEL", "models/embedding-001")
       gemini_llm_model: str = os.getenv("GEMINI_LLM_MODEL", "gemini-2.5-flash")
       gemini_free_tier_limit: int = int(os.getenv("GEMINI_FREE_TIER_LIMIT", "1500"))  # Daily limit
       
       # Embeddings - Local (Ollama)
       embedding_model: str = os.getenv("RAG_EMBEDDING_MODEL", "sentence-transformers/all-MiniLM-L6-v2")
       embedding_provider: str = os.getenv("RAG_EMBEDDING_PROVIDER", "hybrid")  # gemini, ollama, local, or hybrid
       ollama_endpoint: str = os.getenv("OLLAMA_HOST", "http://fks_ai:11434")
       ollama_model: str = os.getenv("OLLAMA_MODEL", "qwen2.5")
       
       # Hybrid Routing
       use_hybrid: bool = os.getenv("RAG_USE_HYBRID", "true").lower() == "true"
       hybrid_threshold: int = int(os.getenv("RAG_HYBRID_THRESHOLD", "500"))  # Use Gemini for queries >500 chars
       gemini_usage_tracker: Dict[str, int] = {}  # Track daily usage
       
       # Chunking
       chunk_size: int = int(os.getenv("RAG_CHUNK_SIZE", "1000"))
       chunk_overlap: int = int(os.getenv("RAG_CHUNK_OVERLAP", "200"))
       
       # Retrieval
       top_k: int = int(os.getenv("RAG_TOP_K", "5"))
       similarity_threshold: float = float(os.getenv("RAG_SIMILARITY_THRESHOLD", "0.7"))
       
       # Generation
       llm_temperature: float = float(os.getenv("RAG_LLM_TEMPERATURE", "0.7"))
       max_tokens: int = int(os.getenv("RAG_MAX_TOKENS", "1000"))
       
       # Advanced RAG
       use_hyde: bool = os.getenv("RAG_USE_HYDE", "true").lower() == "true"
       use_raptor: bool = os.getenv("RAG_USE_RAPTOR", "false").lower() == "true"
       use_reranking: bool = os.getenv("RAG_USE_RERANKING", "false").lower() == "true"
       
       # Evaluation
       evaluation_enabled: bool = os.getenv("RAG_EVALUATION_ENABLED", "true").lower() == "true"
       ragas_threshold: float = float(os.getenv("RAGAS_THRESHOLD", "0.9"))
       
       def should_use_gemini(self, query: str) -> bool:
           """Determine if Gemini should be used based on query complexity and usage limits"""
           if not self.use_hybrid:
               return self.embedding_provider == "gemini"
           
           # Check daily usage limit
           today = datetime.now().strftime("%Y-%m-%d")
           daily_usage = self.gemini_usage_tracker.get(today, 0)
           if daily_usage >= self.gemini_free_tier_limit:
               return False  # Use Ollama if limit reached
           
           # Use Gemini for complex queries
           if len(query) > self.hybrid_threshold:
               return True
           
           # Use Ollama for simple queries
           return False
   ```

3. **Create vector store manager**:
   ```
   File: repo/analyze/src/rag/vector_store.py
   Content:
   from typing import List, Optional
   import chromadb
   from chromadb.config import Settings
   from langchain.vectorstores import Chroma
   from langchain.embeddings import HuggingFaceEmbeddings
   from langchain_community.embeddings import OllamaEmbeddings
   from loguru import logger
   from .config import RAGConfig
   
   class VectorStoreManager:
       """Manage vector store for RAG"""
       
       def __init__(self, config: RAGConfig):
           self.config = config
           self.vector_store = None
           self.embeddings = self._create_embeddings()
           self._initialize_vector_store()
       
       def _create_embeddings(self):
           """Create embeddings model with Gemini API and Ollama hybrid support"""
           if self.config.embedding_provider == "gemini":
               if not self.config.gemini_api_key:
                   logger.warning("Gemini API key not set, falling back to Ollama")
                   return self._create_ollama_embeddings()
               
               logger.info("Using Gemini API embeddings")
               from langchain_google_genai import GoogleGenerativeAIEmbeddings
               return GoogleGenerativeAIEmbeddings(
                   model=self.config.gemini_embedding_model,
                   google_api_key=self.config.gemini_api_key
               )
           elif self.config.embedding_provider == "ollama":
               return self._create_ollama_embeddings()
           elif self.config.embedding_provider == "hybrid":
               # Hybrid: Use Gemini for complex, Ollama for simple
               logger.info("Using hybrid embeddings (Gemini + Ollama)")
               return self._create_ollama_embeddings()  # Default to Ollama, switch dynamically
           else:
               logger.info(f"Using local embeddings: {self.config.embedding_model}")
               return HuggingFaceEmbeddings(
                   model_name=self.config.embedding_model
               )
       
       def _create_ollama_embeddings(self):
           """Create Ollama embeddings"""
           logger.info(f"Using Ollama embeddings: {self.config.ollama_endpoint}")
           from langchain_ollama import OllamaEmbeddings
           return OllamaEmbeddings(
               model=self.config.ollama_model,
               base_url=self.config.ollama_endpoint
           )
       
       def get_llm(self, query: str = ""):
           """Get LLM (Gemini or Ollama) based on query and usage"""
           if self.config.should_use_gemini(query):
               if not self.config.gemini_api_key:
                   return self._get_ollama_llm()
               
               # Track Gemini usage
               today = datetime.now().strftime("%Y-%m-%d")
               self.config.gemini_usage_tracker[today] = self.config.gemini_usage_tracker.get(today, 0) + 1
               
               logger.info(f"Using Gemini LLM: {self.config.gemini_llm_model}")
               from langchain_google_genai import ChatGoogleGenerativeAI
               return ChatGoogleGenerativeAI(
                   model=self.config.gemini_llm_model,
                   google_api_key=self.config.gemini_api_key,
                   temperature=self.config.llm_temperature
               )
           else:
               return self._get_ollama_llm()
       
       def _get_ollama_llm(self):
           """Get Ollama LLM"""
           logger.info(f"Using Ollama LLM: {self.config.ollama_model}")
           from langchain_ollama import ChatOllama
           return ChatOllama(
               model=self.config.ollama_model,
               base_url=self.config.ollama_endpoint,
               temperature=self.config.llm_temperature
           )
       
       def _initialize_vector_store(self):
           """Initialize vector store"""
           if self.config.vector_store_type == "chroma":
               self.vector_store = Chroma(
                   persist_directory=self.config.chroma_persist_dir,
                   embedding_function=self.embeddings,
                   client_settings=Settings(
                       anonymized_telemetry=False,
                       allow_reset=True
                   )
               )
               logger.info(f"Chroma vector store initialized: {self.config.chroma_persist_dir}")
           else:
               raise ValueError(f"Unsupported vector store: {self.config.vector_store_type}")
       
       def add_documents(self, documents: List[str], metadatas: Optional[List[dict]] = None):
           """Add documents to vector store"""
           if metadatas is None:
               metadatas = [{}] * len(documents)
           
           self.vector_store.add_texts(
               texts=documents,
               metadatas=metadatas
           )
           logger.info(f"Added {len(documents)} documents to vector store")
       
       def search(self, query: str, k: Optional[int] = None) -> List[dict]:
           """Search vector store"""
           k = k or self.config.top_k
           
           results = self.vector_store.similarity_search_with_score(
               query,
               k=k
           )
           
           # Filter by similarity threshold
           filtered_results = [
               {
                   "content": doc.page_content,
                   "metadata": doc.metadata,
                   "score": score
               }
               for doc, score in results
               if score >= self.config.similarity_threshold
           ]
           
           return filtered_results
       
       def delete_collection(self):
           """Delete vector store collection"""
           self.vector_store.delete_collection()
           logger.info("Vector store collection deleted")
   ```

**Deliverable**: RAG infrastructure set up in fks_analyze

**Success Criteria**: Vector store initialized, embeddings working, configuration loaded

---

### Task 1.2: Document Ingestion Pipeline

**Objective**: Ingest 300+ documentation files from FKS repos into vector store

**Actions for AI Agent**:

1. **Create document loader**:
   ```
   File: repo/analyze/src/rag/loaders.py
   Content:
   from pathlib import Path
   from typing import List, Dict, Any
   from langchain_community.document_loaders import (
       TextLoader,
       PyPDFLoader,
       Docx2txtLoader,
       MarkdownLoader,
       DirectoryLoader
   )
   from langchain.text_splitter import RecursiveCharacterTextSplitter
   from loguru import logger
   from .config import RAGConfig
   
   class FKSDocumentLoader:
       """Load FKS documentation files"""
       
       def __init__(self, config: RAGConfig):
           self.config = config
           self.text_splitter = RecursiveCharacterTextSplitter(
               chunk_size=config.chunk_size,
               chunk_overlap=config.chunk_overlap,
               length_function=len,
               separators=["\n\n", "\n", " ", ""]
           )
       
       def load_documents(self, root_dir: str = "/home/jordan/Documents/code/fks") -> List[Dict[str, Any]]:
           """Load all documentation files from FKS repos"""
           documents = []
           
           # Define documentation paths
           doc_paths = [
               f"{root_dir}/repo/main/docs/**/*.md",
               f"{root_dir}/repo/main/docs/**/*.txt",
               f"{root_dir}/repo/*/README.md",
               f"{root_dir}/repo/*/docs/**/*.md",
               f"{root_dir}/todo/**/*.md",
               f"{root_dir}/repo/*/API_DOCUMENTATION.md",
               f"{root_dir}/repo/*/docs/**/*.rst",
           ]
           
           for pattern in doc_paths:
               try:
                   # Load markdown files
                   loader = DirectoryLoader(
                       str(Path(pattern).parent),
                       glob=Path(pattern).name,
                       loader_cls=MarkdownLoader,
                       show_progress=True
                   )
                   docs = loader.load()
                   
                   for doc in docs:
                       # Split into chunks
                       chunks = self.text_splitter.split_text(doc.page_content)
                       
                       for i, chunk in enumerate(chunks):
                           documents.append({
                               "content": chunk,
                               "metadata": {
                                   **doc.metadata,
                                   "chunk_index": i,
                                   "total_chunks": len(chunks),
                                   "source_file": doc.metadata.get("source", ""),
                                   "repo": self._extract_repo(doc.metadata.get("source", "")),
                                   "service": self._extract_service(doc.metadata.get("source", ""))
                               }
                           })
               except Exception as e:
                   logger.warning(f"Failed to load documents from {pattern}: {e}")
           
           logger.info(f"Loaded {len(documents)} document chunks from FKS repos")
           return documents
       
       def _extract_repo(self, file_path: str) -> str:
           """Extract repo name from file path"""
           parts = Path(file_path).parts
           if "repo" in parts:
               repo_index = parts.index("repo")
               if repo_index + 1 < len(parts):
                   return parts[repo_index + 1]
           return "unknown"
       
       def _extract_service(self, file_path: str) -> str:
           """Extract service name from file path"""
           repo = self._extract_repo(file_path)
           # Map repo names to service names
           service_map = {
               "main": "fks_main",
               "data": "fks_data",
               "ai": "fks_ai",
               "web": "fks_web",
               "api": "fks_api",
               "app": "fks_app",
               "execution": "fks_execution",
               "portfolio": "fks_portfolio",
               "analyze": "fks_analyze",
               "monitor": "fks_monitor",
           }
           return service_map.get(repo, repo)
       
       def load_code_files(self, root_dir: str = "/home/jordan/Documents/code/fks") -> List[Dict[str, Any]]:
           """Load Python code files for code analysis"""
           documents = []
           
           # Load Python files
           python_pattern = f"{root_dir}/repo/*/src/**/*.py"
           loader = DirectoryLoader(
               str(Path(python_pattern).parent.parent),
               glob="**/*.py",
               loader_cls=TextLoader,
               show_progress=True
           )
           
           docs = loader.load()
           for doc in docs:
               # Split code into functions/classes
               chunks = self._split_code(doc.page_content)
               
               for i, chunk in enumerate(chunks):
                   documents.append({
                       "content": chunk,
                       "metadata": {
                           **doc.metadata,
                           "chunk_index": i,
                           "type": "code",
                           "language": "python",
                           "repo": self._extract_repo(doc.metadata.get("source", "")),
                           "service": self._extract_service(doc.metadata.get("source", ""))
                       }
                   })
           
           logger.info(f"Loaded {len(documents)} code chunks from FKS repos")
           return documents
       
       def _split_code(self, code: str) -> List[str]:
           """Split code into functions and classes"""
           # Simple splitting by function/class definitions
           chunks = []
           current_chunk = []
           lines = code.split("\n")
           
           for line in lines:
               if line.strip().startswith(("def ", "class ", "@")):
                   if current_chunk:
                       chunks.append("\n".join(current_chunk))
                   current_chunk = [line]
               else:
                   current_chunk.append(line)
           
           if current_chunk:
               chunks.append("\n".join(current_chunk))
           
           return chunks if chunks else [code]
   ```

2. **Create ingestion service**:
   ```
   File: repo/analyze/src/rag/ingestion.py
   Content:
   from typing import List, Dict, Any
   from loguru import logger
   from .vector_store import VectorStoreManager
   from .loaders import FKSDocumentLoader
   from .config import RAGConfig
   
   class RAGIngestionService:
       """Service for ingesting documents into RAG system"""
       
       def __init__(self, config: RAGConfig):
           self.config = config
           self.vector_store = VectorStoreManager(config)
           self.loader = FKSDocumentLoader(config)
       
       def ingest_documents(self, include_code: bool = False):
           """Ingest all FKS documentation"""
           logger.info("Starting document ingestion...")
           
           # Load documentation
           documents = self.loader.load_documents()
           
           if include_code:
               # Load code files
               code_documents = self.loader.load_code_files()
               documents.extend(code_documents)
           
           # Add to vector store
           texts = [doc["content"] for doc in documents]
           metadatas = [doc["metadata"] for doc in documents]
           
           self.vector_store.add_documents(texts, metadatas)
           
           logger.info(f"Ingested {len(documents)} document chunks into vector store")
           return len(documents)
       
       def ingest_service_docs(self, service_name: str):
           """Ingest documentation for a specific service"""
           logger.info(f"Ingesting documentation for {service_name}...")
           
           documents = self.loader.load_documents()
           
           # Filter by service
           service_docs = [
               doc for doc in documents
               if doc["metadata"].get("service") == service_name
           ]
           
           if service_docs:
               texts = [doc["content"] for doc in service_docs]
               metadatas = [doc["metadata"] for doc in service_docs]
               self.vector_store.add_documents(texts, metadatas)
               logger.info(f"Ingested {len(service_docs)} chunks for {service_name}")
           else:
               logger.warning(f"No documents found for {service_name}")
           
           return len(service_docs)
   ```

3. **Create ingestion CLI**:
   ```
   File: repo/analyze/src/rag/cli.py
   Content:
   import click
   from .ingestion import RAGIngestionService
   from .config import RAGConfig
   
   @click.group()
   def cli():
       """RAG CLI for fks_analyze"""
       pass
   
   @cli.command()
   @click.option("--include-code", is_flag=True, help="Include code files")
   def ingest(include_code):
       """Ingest FKS documentation"""
       config = RAGConfig()
       service = RAGIngestionService(config)
       count = service.ingest_documents(include_code=include_code)
       click.echo(f"Ingested {count} document chunks")
   
   @cli.command()
   @click.argument("service_name")
   def ingest_service(service_name):
       """Ingest documentation for a specific service"""
       config = RAGConfig()
       service = RAGIngestionService(config)
       count = service.ingest_service_docs(service_name)
       click.echo(f"Ingested {count} chunks for {service_name}")
   
   if __name__ == "__main__":
       cli()
   ```

**Deliverable**: Document ingestion pipeline implemented

**Success Criteria**: 300+ docs ingested, vector store populated, metadata preserved

---

### Task 1.3: Basic RAG Query System

**Objective**: Implement basic RAG query system for natural language questions

**Actions for AI Agent**:

1. **Create RAG query service**:
   ```
   File: repo/analyze/src/rag/query.py
   Content:
   from typing import List, Dict, Any, Optional
   from langchain.chains import RetrievalQA
   from langchain_community.llms import Ollama
   from langchain.prompts import PromptTemplate
   from loguru import logger
   from .vector_store import VectorStoreManager
   from .config import RAGConfig
   
   class RAGQueryService:
       """Service for querying RAG system"""
       
       def __init__(self, config: RAGConfig):
           self.config = config
           self.vector_store = VectorStoreManager(config)
           self.llm = Ollama(
               model=config.llm_model,
               base_url=config.ollama_endpoint,
               temperature=config.llm_temperature
           )
           self.qa_chain = self._create_qa_chain()
       
       def _create_qa_chain(self):
           """Create QA chain with custom prompt"""
           prompt_template = """Use the following pieces of context from FKS documentation to answer the question.
   If you don't know the answer, just say that you don't know, don't try to make up an answer.
   
   Context:
   {context}
   
   Question: {question}
   
   Answer:"""
           
           prompt = PromptTemplate(
               template=prompt_template,
               input_variables=["context", "question"]
           )
           
           qa_chain = RetrievalQA.from_chain_type(
               llm=self.llm,
               chain_type="stuff",
               retriever=self.vector_store.vector_store.as_retriever(
                   search_kwargs={"k": self.config.top_k}
               ),
               chain_type_kwargs={"prompt": prompt},
               return_source_documents=True
           )
           
           return qa_chain
       
       def query(self, question: str, service_filter: Optional[str] = None) -> Dict[str, Any]:
           """Query RAG system"""
           try:
               # Search vector store
               results = self.vector_store.search(question, k=self.config.top_k)
               
               # Filter by service if specified
               if service_filter:
                   results = [
                       r for r in results
                       if r["metadata"].get("service") == service_filter
                   ]
               
               # Generate answer using LLM
               response = self.qa_chain.invoke({"query": question})
               
               return {
                   "question": question,
                   "answer": response["result"],
                   "sources": [
                       {
                           "content": doc.page_content[:200] + "...",
                           "metadata": doc.metadata,
                           "score": None
                       }
                       for doc in response.get("source_documents", [])
                   ],
                   "retrieved_docs": results
               }
           except Exception as e:
               logger.error(f"RAG query error: {e}")
               return {
                   "question": question,
                   "answer": f"Error: {str(e)}",
                   "sources": [],
                   "retrieved_docs": []
               }
       
       def suggest_optimizations(self, service_name: str) -> List[str]:
           """Suggest optimizations for a service"""
           question = f"What are potential optimizations for {service_name}?"
           response = self.query(question, service_filter=service_name)
           
           # Parse response into suggestions
           suggestions = []
           if response["answer"]:
               # Simple parsing (can be improved)
               lines = response["answer"].split("\n")
               for line in lines:
                   if line.strip().startswith(("-", "*", "1.", "2.")):
                       suggestions.append(line.strip())
           
           return suggestions
   ```

2. **Create API endpoint**:
   ```
   File: repo/analyze/src/api/rag_routes.py
   Content:
   from fastapi import APIRouter, HTTPException, Query
   from typing import Optional
   from pydantic import BaseModel
   from ..rag.query import RAGQueryService
   from ..rag.config import RAGConfig
   from loguru import logger
   
   router = APIRouter(prefix="/api/rag", tags=["rag"])
   
   config = RAGConfig()
   rag_service = RAGQueryService(config)
   
   class QueryRequest(BaseModel):
       question: str
       service_filter: Optional[str] = None
   
   @router.post("/query")
   async def query_rag(request: QueryRequest):
       """Query RAG system"""
       try:
           response = rag_service.query(
               request.question,
               service_filter=request.service_filter
           )
           return response
       except Exception as e:
           logger.error(f"RAG query error: {e}")
           raise HTTPException(status_code=500, detail=str(e))
   
   @router.get("/suggest-optimizations")
   async def suggest_optimizations(
       service_name: str = Query(..., description="Service name")
   ):
       """Get optimization suggestions for a service"""
       try:
           suggestions = rag_service.suggest_optimizations(service_name)
           return {
               "service": service_name,
               "suggestions": suggestions
           }
       except Exception as e:
           logger.error(f"Optimization suggestion error: {e}")
           raise HTTPException(status_code=500, detail=str(e))
   ```

**Deliverable**: Basic RAG query system implemented

**Success Criteria**: Natural language queries work, answers generated, sources cited

---

## 📋 Phase 2: Advanced RAG Techniques (Weeks 3-4)

### Task 2.1: Implement HyDE (Hypothetical Document Embeddings)

**Objective**: Implement HyDE for improved retrieval accuracy

**Actions for AI Agent**:

1. **Create HyDE implementation**:
   ```
   File: repo/analyze/src/rag/advanced/hyde.py
   Content:
   from typing import List, Dict, Any
   from langchain_community.llms import Ollama
   from loguru import logger
   from ..vector_store import VectorStoreManager
   from ..config import RAGConfig
   
   class HyDERetriever:
       """Hypothetical Document Embeddings (HyDE) retriever"""
       
       def __init__(self, config: RAGConfig, vector_store: VectorStoreManager):
           self.config = config
           self.vector_store = vector_store
           self.llm = Ollama(
               model=config.llm_model,
               base_url=config.ollama_endpoint,
               temperature=0.7
           )
       
       def generate_hypothetical_document(self, query: str) -> str:
           """Generate hypothetical document that would answer the query"""
           prompt = f"""Generate a hypothetical document that would answer this question: {query}
   
   The document should be informative and detailed, written as if it were part of the FKS documentation.
   Focus on technical details, architecture, and implementation.
   
   Hypothetical document:"""
           
           try:
               response = self.llm.invoke(prompt)
               return response.strip()
           except Exception as e:
               logger.error(f"HyDE generation error: {e}")
               return query  # Fallback to original query
       
       def retrieve(self, query: str, k: int = None) -> List[Dict[str, Any]]:
           """Retrieve documents using HyDE"""
           # Generate hypothetical document
           hyde_doc = self.generate_hypothetical_document(query)
           
           logger.info(f"HyDE: Generated hypothetical document (length: {len(hyde_doc)})")
           
           # Search using hypothetical document
           results = self.vector_store.search(hyde_doc, k=k or self.config.top_k)
           
           # Also search with original query and combine results
           original_results = self.vector_store.search(query, k=k or self.config.top_k)
           
           # Combine and deduplicate
           combined_results = self._combine_results(results, original_results)
           
           return combined_results
       
       def _combine_results(self, results1: List[Dict], results2: List[Dict]) -> List[Dict]:
           """Combine and deduplicate results"""
           seen = set()
           combined = []
           
           # Add HyDE results first (higher priority)
           for result in results1:
               content_hash = hash(result["content"][:100])
               if content_hash not in seen:
                   seen.add(content_hash)
                   result["source"] = "hyde"
                   combined.append(result)
           
           # Add original results
           for result in results2:
               content_hash = hash(result["content"][:100])
               if content_hash not in seen:
                   seen.add(content_hash)
                   result["source"] = "original"
                   combined.append(result)
           
           return combined
   ```

2. **Integrate HyDE into query service**:
   ```
   File: repo/analyze/src/rag/query.py
   # Update RAGQueryService to use HyDE
   
   from .advanced.hyde import HyDERetriever
   
   class RAGQueryService:
       def __init__(self, config: RAGConfig):
           # ... existing code ...
           if config.use_hyde:
               self.hyde_retriever = HyDERetriever(config, self.vector_store)
           else:
               self.hyde_retriever = None
       
       def query(self, question: str, service_filter: Optional[str] = None) -> Dict[str, Any]:
           """Query RAG system with HyDE"""
           try:
               # Use HyDE if enabled
               if self.hyde_retriever:
                   results = self.hyde_retriever.retrieve(question, k=self.config.top_k)
               else:
                   results = self.vector_store.search(question, k=self.config.top_k)
               
               # ... rest of query logic ...
   ```

**Deliverable**: HyDE implementation integrated

**Success Criteria**: HyDE improves retrieval accuracy, hypothetical documents generated

---

### Task 2.2: Implement RAPTOR (Recursive Abstractive Processing for Tree-Organized Retrieval)

**Objective**: Implement RAPTOR for hierarchical document organization

**Actions for AI Agent**:

1. **Create RAPTOR implementation**:
   ```
   File: repo/analyze/src/rag/advanced/raptor.py
   Content:
   from typing import List, Dict, Any
   from langchain_community.llms import Ollama
   from langchain.text_splitter import RecursiveCharacterTextSplitter
   from sklearn.cluster import KMeans
   import numpy as np
   from loguru import logger
   from ..vector_store import VectorStoreManager
   from ..config import RAGConfig
   
   class RAPTORRetriever:
       """RAPTOR (Recursive Abstractive Processing for Tree-Organized Retrieval)"""
       
       def __init__(self, config: RAGConfig, vector_store: VectorStoreManager):
           self.config = config
           self.vector_store = vector_store
           self.llm = Ollama(
               model=config.llm_model,
               base_url=config.ollama_endpoint,
               temperature=0.3  # Lower temperature for summarization
           )
       
       def build_tree(self, documents: List[str], max_depth: int = 3) -> Dict[str, Any]:
           """Build hierarchical tree structure"""
           tree = {
               "nodes": [],
               "edges": [],
               "depth": 0
           }
           
           current_level = documents
           
           for depth in range(max_depth):
               if len(current_level) <= 1:
                   break
               
               # Cluster documents
               clusters = self._cluster_documents(current_level)
               
               # Summarize each cluster
               summaries = []
               for cluster in clusters:
                   summary = self._summarize_cluster(cluster)
                   summaries.append(summary)
                   tree["nodes"].append({
                       "content": summary,
                       "depth": depth,
                       "type": "summary",
                       "children": [doc[:100] for doc in cluster]
                   })
               
               current_level = summaries
               tree["depth"] = depth + 1
           
           return tree
       
       def _cluster_documents(self, documents: List[str], n_clusters: int = 5) -> List[List[str]]:
           """Cluster documents using K-means"""
           # Get embeddings for documents
           embeddings = self.vector_store.embeddings.embed_documents(documents)
           
           # Cluster
           if len(documents) < n_clusters:
               n_clusters = len(documents)
           
           kmeans = KMeans(n_clusters=n_clusters, random_state=42)
           clusters = kmeans.fit_predict(embeddings)
           
           # Group documents by cluster
           clustered_docs = [[] for _ in range(n_clusters)]
           for doc, cluster_id in zip(documents, clusters):
               clustered_docs[cluster_id].append(doc)
           
           return [cluster for cluster in clustered_docs if cluster]
       
       def _summarize_cluster(self, cluster: List[str]) -> str:
           """Summarize a cluster of documents"""
           combined_text = "\n\n".join(cluster[:5])  # Limit to 5 docs
           
           prompt = f"""Summarize the following documents from FKS documentation, focusing on key concepts and technical details:
   
   {combined_text}
   
   Summary:"""
           
           try:
               summary = self.llm.invoke(prompt)
               return summary.strip()
           except Exception as e:
               logger.error(f"RAPTOR summarization error: {e}")
               return combined_text[:500]  # Fallback to truncated text
       
       def retrieve(self, query: str, tree: Dict[str, Any], k: int = 5) -> List[Dict[str, Any]]:
           """Retrieve documents using RAPTOR tree"""
           # Start from root (deepest level)
           current_nodes = [node for node in tree["nodes"] if node["depth"] == tree["depth"] - 1]
           
           # Find most relevant nodes
           query_embedding = self.vector_store.embeddings.embed_query(query)
           
           scores = []
           for node in current_nodes:
               node_embedding = self.vector_store.embeddings.embed_query(node["content"])
               score = np.dot(query_embedding, node_embedding) / (
                   np.linalg.norm(query_embedding) * np.linalg.norm(node_embedding)
               )
               scores.append((node, score))
           
           # Sort by score
           scores.sort(key=lambda x: x[1], reverse=True)
           
           # Retrieve top k nodes and their children
           results = []
           for node, score in scores[:k]:
               results.append({
                   "content": node["content"],
                   "metadata": {"depth": node["depth"], "type": "raptor"},
                   "score": score,
                   "children": node.get("children", [])
               })
           
           return results
   ```

**Deliverable**: RAPTOR implementation for hierarchical retrieval

**Success Criteria**: RAPTOR builds tree structure, improves retrieval for complex queries

---

### Task 2.3: Implement Self-Correction (Self-RAG)

**Objective**: Implement self-correction for improved answer quality

**Actions for AI Agent**:

1. **Create Self-RAG implementation**:
   ```
   File: repo/analyze/src/rag/advanced/self_rag.py
   Content:
   from typing import List, Dict, Any, Optional
   from langchain_community.llms import Ollama
   from langgraph.graph import StateGraph, END
   from langgraph.graph.message import add_messages
   from loguru import logger
   from ..vector_store import VectorStoreManager
   from ..config import RAGConfig
   
   class SelfRAGNode:
       """Self-RAG node for self-correction"""
       
       def __init__(self, config: RAGConfig, vector_store: VectorStoreManager):
           self.config = config
           self.vector_store = vector_store
           self.llm = Ollama(
               model=config.llm_model,
               base_url=config.ollama_endpoint,
               temperature=0.7
           )
       
       def judge_retrieval(self, query: str, documents: List[Dict]) -> Dict[str, Any]:
           """Judge if retrieval is relevant"""
           doc_contents = "\n\n".join([d["content"][:200] for d in documents[:3]])
           
           prompt = f"""Judge if the following retrieved documents are relevant to the query.
   Return "Yes" if relevant, "No" if not relevant.
   
   Query: {query}
   
   Documents:
   {doc_contents}
   
   Judgment:"""
           
           try:
               judgment = self.llm.invoke(prompt)
               is_relevant = "yes" in judgment.lower()
               
               return {
                   "is_relevant": is_relevant,
                   "judgment": judgment,
                   "documents": documents if is_relevant else []
               }
           except Exception as e:
               logger.error(f"Self-RAG judgment error: {e}")
               return {
                   "is_relevant": True,
                   "judgment": "Error in judgment",
                   "documents": documents
               }
       
       def generate_answer(self, query: str, documents: List[Dict]) -> str:
           """Generate answer with self-reflection"""
           doc_contents = "\n\n".join([d["content"] for d in documents])
           
           prompt = f"""Answer the question using the provided context. If the context is insufficient, say so.
   
   Context:
   {doc_contents}
   
   Question: {query}
   
   Answer:"""
           
           try:
               answer = self.llm.invoke(prompt)
               return answer.strip()
           except Exception as e:
               logger.error(f"Self-RAG generation error: {e}")
               return "Error generating answer"
       
       def judge_answer(self, query: str, answer: str, documents: List[Dict]) -> Dict[str, Any]:
           """Judge if answer is faithful to documents"""
           doc_contents = "\n\n".join([d["content"][:200] for d in documents[:3]])
           
           prompt = f"""Judge if the following answer is faithful to the provided documents.
   Return a score from 0.0 to 1.0, where 1.0 is completely faithful.
   
   Query: {query}
   
   Documents:
   {doc_contents}
   
   Answer:
   {answer}
   
   Faithfulness score (0.0-1.0):"""
           
           try:
               score_text = self.llm.invoke(prompt)
               # Extract score from response
               import re
               score_match = re.search(r"(\d+\.?\d*)", score_text)
               score = float(score_match.group(1)) if score_match else 0.5
               score = max(0.0, min(1.0, score))  # Clamp to [0, 1]
               
               return {
                   "score": score,
                   "is_faithful": score >= self.config.ragas_threshold,
                   "judgment": score_text
               }
           except Exception as e:
               logger.error(f"Self-RAG faithfulness judgment error: {e}")
               return {
                   "score": 0.5,
                   "is_faithful": False,
                   "judgment": "Error in judgment"
               }
       
       def refine_answer(self, query: str, answer: str, feedback: Dict[str, Any]) -> str:
           """Refine answer based on feedback"""
           if feedback["is_faithful"]:
               return answer
           
           prompt = f"""The previous answer was not faithful to the documents. Refine it to be more accurate.
   
   Query: {query}
   
   Previous Answer:
   {answer}
   
   Feedback: {feedback["judgment"]}
   
   Refined Answer:"""
           
           try:
               refined = self.llm.invoke(prompt)
               return refined.strip()
           except Exception as e:
               logger.error(f"Self-RAG refinement error: {e}")
               return answer
   
   class SelfRAGWorkflow:
       """Self-RAG workflow using LangGraph"""
       
       def __init__(self, config: RAGConfig, vector_store: VectorStoreManager):
           self.config = config
           self.node = SelfRAGNode(config, vector_store)
           self.workflow = self._build_workflow()
       
       def _build_workflow(self):
           """Build LangGraph workflow"""
           from langgraph.graph import StateGraph
           
           workflow = StateGraph(dict)
           
           # Add nodes
           workflow.add_node("retrieve", self._retrieve)
           workflow.add_node("judge_retrieval", self._judge_retrieval)
           workflow.add_node("generate", self._generate)
           workflow.add_node("judge_answer", self._judge_answer)
           workflow.add_node("refine", self._refine)
           
           # Define edges
           workflow.set_entry_point("retrieve")
           workflow.add_edge("retrieve", "judge_retrieval")
           workflow.add_conditional_edges(
               "judge_retrieval",
               self._should_continue_retrieval,
               {
                   "continue": "generate",
                   "retry": "retrieve"
               }
           )
           workflow.add_edge("generate", "judge_answer")
           workflow.add_conditional_edges(
               "judge_answer",
               self._should_refine,
               {
                   "accept": END,
                   "refine": "refine"
               }
           )
           workflow.add_edge("refine", "judge_answer")
           
           return workflow.compile()
       
       def _retrieve(self, state: Dict) -> Dict:
           """Retrieve documents"""
           query = state["query"]
           results = self.node.vector_store.search(query, k=5)
           return {"documents": results}
       
       def _judge_retrieval(self, state: Dict) -> Dict:
           """Judge retrieval relevance"""
           judgment = self.node.judge_retrieval(state["query"], state["documents"])
           return {"retrieval_judgment": judgment}
       
       def _generate(self, state: Dict) -> Dict:
           """Generate answer"""
           documents = state["retrieval_judgment"]["documents"]
           answer = self.node.generate_answer(state["query"], documents)
           return {"answer": answer}
       
       def _judge_answer(self, state: Dict) -> Dict:
           """Judge answer faithfulness"""
           judgment = self.node.judge_answer(
               state["query"],
               state["answer"],
               state["retrieval_judgment"]["documents"]
           )
           return {"answer_judgment": judgment}
       
       def _refine(self, state: Dict) -> Dict:
           """Refine answer"""
           refined = self.node.refine_answer(
               state["query"],
               state["answer"],
               state["answer_judgment"]
           )
           return {"answer": refined}
       
       def _should_continue_retrieval(self, state: Dict) -> str:
           """Determine if retrieval should continue"""
           if state["retrieval_judgment"]["is_relevant"]:
               return "continue"
           return "retry"
       
       def _should_refine(self, state: Dict) -> str:
           """Determine if answer should be refined"""
           if state["answer_judgment"]["is_faithful"]:
               return "accept"
           return "refine"
       
       async def run(self, query: str) -> Dict[str, Any]:
           """Run Self-RAG workflow"""
           initial_state = {"query": query}
           result = await self.workflow.ainvoke(initial_state)
           return result
   ```

**Deliverable**: Self-RAG implementation with self-correction

**Success Criteria**: Self-RAG improves answer quality, faithfulness scores >0.9

---

## 📋 Phase 3: RAG in fks_ai for Signal Refinement (Weeks 5-6)

### Task 3.1: Integrate RAG into fks_ai Multi-Agent System

**Objective**: Use RAG to enhance multi-agent debates and signal generation

**Actions for AI Agent**:

1. **Create market data RAG service**:
   ```
   File: repo/ai/src/rag/market_rag.py
   Content:
   from typing import List, Dict, Any
   from langchain.vectorstores import Chroma
   from langchain.embeddings import HuggingFaceEmbeddings
   from loguru import logger
   import httpx
   
   class MarketDataRAG:
       """RAG service for market data and trading signals"""
       
       def __init__(self):
           self.embeddings = HuggingFaceEmbeddings(
               model_name="sentence-transformers/all-MiniLM-L6-v2"
           )
           self.vector_store = None
           self.data_service_url = "http://fks_data:8003"
       
       async def load_historical_signals(self, symbol: str, days: int = 30):
           """Load historical trading signals for RAG"""
           try:
               async with httpx.AsyncClient() as client:
                   response = await client.get(
                       f"{self.data_service_url}/api/v1/signals/{symbol}",
                       params={"days": days}
                   )
                   response.raise_for_status()
                   signals = response.json()
                   
                   # Convert signals to documents
                   documents = []
                   for signal in signals:
                       doc = f"""
                       Symbol: {signal['symbol']}
                       Signal: {signal['signal_type']}
                       Entry: {signal['entry_price']}
                       Exit: {signal.get('exit_price', 'N/A')}
                       PnL: {signal.get('pnl', 'N/A')}
                       Indicators: {signal.get('indicators', {})}
                       Timestamp: {signal['timestamp']}
                       """
                       documents.append(doc)
                   
                   # Store in vector database
                   if documents:
                       self.vector_store = Chroma.from_texts(
                           documents,
                           embedding=self.embeddings,
                           collection_name=f"signals_{symbol}"
                       )
                       logger.info(f"Loaded {len(documents)} historical signals for {symbol}")
           except Exception as e:
               logger.error(f"Failed to load historical signals: {e}")
       
       async def retrieve_similar_signals(self, query: str, symbol: str, k: int = 5) -> List[Dict]:
           """Retrieve similar historical signals"""
           if not self.vector_store:
               await self.load_historical_signals(symbol)
           
           if not self.vector_store:
               return []
           
           try:
               results = self.vector_store.similarity_search_with_score(query, k=k)
               return [
                   {
                       "content": doc.page_content,
                       "score": score,
                       "metadata": doc.metadata
                   }
                   for doc, score in results
               ]
           except Exception as e:
               logger.error(f"Signal retrieval error: {e}")
               return []
   ```

2. **Integrate RAG into multi-agent debates**:
   ```
   File: repo/ai/src/agents/rag_enhanced_debate.py
   Content:
   from typing import Dict, Any
   from ..rag.market_rag import MarketDataRAG
   from loguru import logger
   
   class RAGEnhancedDebate:
       """Multi-agent debate enhanced with RAG"""
       
       def __init__(self):
           self.market_rag = MarketDataRAG()
       
       async def enhance_debate(self, symbol: str, debate_context: Dict[str, Any]) -> Dict[str, Any]:
           """Enhance debate with RAG-retrieved historical signals"""
           # Retrieve similar historical signals
           query = f"{symbol} {debate_context.get('signal_type', '')} {debate_context.get('indicators', {})}"
           similar_signals = await self.market_rag.retrieve_similar_signals(query, symbol, k=5)
           
           # Add historical context to debate
           debate_context["historical_signals"] = similar_signals
           
           # Enhance arguments with historical data
           if similar_signals:
               historical_summary = self._summarize_signals(similar_signals)
               debate_context["historical_context"] = historical_summary
           
           logger.info(f"Enhanced debate with {len(similar_signals)} historical signals")
           
           return debate_context
       
       def _summarize_signals(self, signals: List[Dict]) -> str:
           """Summarize historical signals"""
           summary = "Historical Signals:\n"
           for signal in signals:
               summary += f"- {signal['content']}\n"
           return summary
   ```

**Deliverable**: RAG integrated into fks_ai multi-agent system

**Success Criteria**: RAG enhances debates, historical signals retrieved, accuracy improved

---

### Task 3.2: Implement Semantic Routing in fks_api

**Objective**: Implement semantic routing to direct queries to appropriate agents

**Actions for AI Agent**:

1. **Create semantic router**:
   ```
   File: repo/api/src/routing/semantic_router.py
   Content:
   from typing import Dict, Any, List
   from langchain.embeddings import HuggingFaceEmbeddings
   from sklearn.metrics.pairwise import cosine_similarity
   import numpy as np
   from loguru import logger
   
   class SemanticRouter:
       """Semantic router for intelligent query distribution"""
       
       def __init__(self):
           self.embeddings = HuggingFaceEmbeddings(
               model_name="sentence-transformers/all-MiniLM-L6-v2"
           )
           
           # Define routes and their descriptions
           self.routes = {
               "stocks": {
                   "description": "Stock market analysis, equity trading, NASDAQ, NYSE",
                   "endpoint": "http://fks_ai:8007/ai/bots/stock/signal",
                   "keywords": ["stock", "equity", "nasdaq", "nyse", "aapl", "spy", "qqq"]
               },
               "forex": {
                   "description": "Forex trading, currency pairs, EUR/USD, GBP/USD",
                   "endpoint": "http://fks_ai:8007/ai/bots/forex/signal",
                   "keywords": ["forex", "fx", "eur", "gbp", "usd", "currency", "pair"]
               },
               "crypto": {
                   "description": "Cryptocurrency trading, Bitcoin, Ethereum, crypto markets",
                   "endpoint": "http://fks_ai:8007/ai/bots/crypto/signal",
                   "keywords": ["crypto", "bitcoin", "btc", "ethereum", "eth", "blockchain"]
               },
               "portfolio": {
                   "description": "Portfolio optimization, asset allocation, risk management",
                   "endpoint": "http://fks_portfolio:8012/api/portfolio/optimize",
                   "keywords": ["portfolio", "allocation", "optimize", "risk", "diversification"]
               },
               "data": {
                   "description": "Market data, historical data, price data",
                   "endpoint": "http://fks_data:8003/api/v1/data",
                   "keywords": ["data", "historical", "price", "market data", "ohlcv"]
               }
           }
           
           # Pre-compute route embeddings
           self.route_embeddings = {}
           for route_name, route_info in self.routes.items():
               route_text = f"{route_info['description']} {' '.join(route_info['keywords'])}"
               self.route_embeddings[route_name] = self.embeddings.embed_query(route_text)
       
       def route(self, query: str, top_k: int = 1) -> List[Dict[str, Any]]:
           """Route query to appropriate service"""
           # Embed query
           query_embedding = self.embeddings.embed_query(query)
           
           # Calculate similarity with each route
           similarities = {}
           for route_name, route_embedding in self.route_embeddings.items():
               similarity = cosine_similarity(
                   np.array([query_embedding]),
                   np.array([route_embedding])
               )[0][0]
               similarities[route_name] = similarity
           
           # Sort by similarity
           sorted_routes = sorted(
               similarities.items(),
               key=lambda x: x[1],
               reverse=True
           )
           
           # Return top k routes
           results = []
           for route_name, similarity in sorted_routes[:top_k]:
               route_info = self.routes[route_name]
               results.append({
                   "route": route_name,
                   "endpoint": route_info["endpoint"],
                   "similarity": float(similarity),
                   "confidence": "high" if similarity > 0.7 else "medium" if similarity > 0.5 else "low"
               })
           
           logger.info(f"Routed query to: {results[0]['route']} (similarity: {results[0]['similarity']:.2f})")
           
           return results
   ```

2. **Create routing API endpoint**:
   ```
   File: repo/api/src/api/routing_routes.py
   Content:
   from fastapi import APIRouter, HTTPException
   from pydantic import BaseModel
   from ..routing.semantic_router import SemanticRouter
   from loguru import logger
   
   router = APIRouter(prefix="/api/routing", tags=["routing"])
   
   router_service = SemanticRouter()
   
   class RouteRequest(BaseModel):
       query: str
       top_k: int = 1
   
   @router.post("/route")
   async def route_query(request: RouteRequest):
       """Route query to appropriate service"""
       try:
           routes = router_service.route(request.query, top_k=request.top_k)
           return {
               "query": request.query,
               "routes": routes,
               "recommended": routes[0] if routes else None
           }
       except Exception as e:
           logger.error(f"Routing error: {e}")
           raise HTTPException(status_code=500, detail=str(e))
   ```

**Deliverable**: Semantic routing implemented in fks_api

**Success Criteria**: Queries routed correctly, similarity scores calculated, endpoints returned

---

## 📋 Phase 4: Evaluation Framework (Week 7)

### Task 4.1: Implement RAGAS Evaluation

**Objective**: Implement RAGAS for evaluating RAG system quality

**Actions for AI Agent**:

1. **Create RAGAS evaluation service**:
   ```
   File: repo/analyze/src/rag/evaluation/ragas_eval.py
   Content:
   from typing import List, Dict, Any
   from ragas import evaluate
   from ragas.metrics import (
       faithfulness,
       answer_relevancy,
       context_precision,
       context_recall
   )
   from datasets import Dataset
   from loguru import logger
   from ..query import RAGQueryService
   from ..config import RAGConfig
   
   class RAGASEvaluator:
       """RAGAS evaluation for RAG system"""
       
       def __init__(self, config: RAGConfig, rag_service: RAGQueryService):
           self.config = config
           self.rag_service = rag_service
       
       def evaluate(self, questions: List[str], ground_truth: List[str] = None) -> Dict[str, float]:
           """Evaluate RAG system using RAGAS"""
           # Generate answers
           answers = []
           contexts = []
           
           for question in questions:
               response = self.rag_service.query(question)
               answers.append(response["answer"])
               
               # Extract contexts
               context_texts = [doc["content"] for doc in response.get("retrieved_docs", [])]
               contexts.append(context_texts)
           
           # Create dataset
           data = {
               "question": questions,
               "answer": answers,
               "contexts": contexts
           }
           
           if ground_truth:
               data["ground_truth"] = ground_truth
           
           dataset = Dataset.from_dict(data)
           
           # Evaluate
           metrics = [
               faithfulness,
               answer_relevancy,
               context_precision,
               context_recall
           ]
           
           if ground_truth:
               from ragas.metrics import answer_correctness
               metrics.append(answer_correctness)
           
           try:
               results = evaluate(
                   dataset,
                   metrics=metrics
               )
               
               # Extract scores
               scores = {
                   "faithfulness": results["faithfulness"],
                   "answer_relevancy": results["answer_relevancy"],
                   "context_precision": results["context_precision"],
                   "context_recall": results["context_recall"]
               }
               
               if ground_truth:
                   scores["answer_correctness"] = results["answer_correctness"]
               
               logger.info(f"RAGAS evaluation complete: {scores}")
               
               return scores
           except Exception as e:
               logger.error(f"RAGAS evaluation error: {e}")
               return {}
       
       def evaluate_batch(self, test_cases: List[Dict[str, str]]) -> Dict[str, Any]:
           """Evaluate RAG system on batch of test cases"""
           questions = [tc["question"] for tc in test_cases]
           ground_truth = [tc.get("answer") for tc in test_cases]
           
           scores = self.evaluate(questions, ground_truth)
           
           # Check if scores meet threshold
           meets_threshold = all(
               score >= self.config.ragas_threshold
               for score in scores.values()
               if isinstance(score, (int, float))
           )
           
           return {
               "scores": scores,
               "meets_threshold": meets_threshold,
               "threshold": self.config.ragas_threshold
           }
   ```

2. **Create evaluation API endpoint**:
   ```
   File: repo/analyze/src/api/evaluation_routes.py
   Content:
   from fastapi import APIRouter, HTTPException
   from pydantic import BaseModel
   from typing import List, Optional
   from ..rag.evaluation.ragas_eval import RAGASEvaluator
   from ..rag.query import RAGQueryService
   from ..rag.config import RAGConfig
   from loguru import logger
   
   router = APIRouter(prefix="/api/rag/evaluation", tags=["evaluation"])
   
   config = RAGConfig()
   rag_service = RAGQueryService(config)
   evaluator = RAGASEvaluator(config, rag_service)
   
   class EvaluationRequest(BaseModel):
       questions: List[str]
       ground_truth: Optional[List[str]] = None
   
   class TestCase(BaseModel):
       question: str
       answer: Optional[str] = None
   
   @router.post("/evaluate")
   async def evaluate_rag(request: EvaluationRequest):
       """Evaluate RAG system"""
       try:
           scores = evaluator.evaluate(request.questions, request.ground_truth)
           return {
               "scores": scores,
               "threshold": config.ragas_threshold,
               "meets_threshold": all(
                   score >= config.ragas_threshold
                   for score in scores.values()
                   if isinstance(score, (int, float))
               )
           }
       except Exception as e:
           logger.error(f"Evaluation error: {e}")
           raise HTTPException(status_code=500, detail=str(e))
   
   @router.post("/evaluate-batch")
   async def evaluate_batch(test_cases: List[TestCase]):
       """Evaluate RAG system on batch of test cases"""
       try:
           results = evaluator.evaluate_batch([
               {"question": tc.question, "answer": tc.answer}
               for tc in test_cases
           ])
           return results
       except Exception as e:
           logger.error(f"Batch evaluation error: {e}")
           raise HTTPException(status_code=500, detail=str(e))
   ```

**Deliverable**: RAGAS evaluation framework implemented

**Success Criteria**: RAGAS evaluates RAG system, faithfulness scores >0.9, metrics tracked

---

## 📋 Phase 5: HFT-Inspired Network Structure (Week 8)

### Task 5.1: Implement HFT-Inspired Network Architecture

**Objective**: Apply HFT network structure principles to FKS (focus on structure, not speed)

**Actions for AI Agent**:

1. **Create network structure document**:
   ```
   File: repo/main/docs/hft-network-structure.md
   Content:
   # HFT-Inspired Network Structure for FKS
   
   ## Principles (Adapted from HFT)
   
   ### 1. Direct Service Communication
   - Services communicate directly via dedicated channels
   - No intermediate routing for critical paths
   - Pre-established connections for low latency
   
   ### 2. Message Schema Standardization
   - Standardized message formats across all services
   - Versioned schemas for backward compatibility
   - Binary protocols for efficiency (Protocol Buffers, MessagePack)
   
   ### 3. Redundant Paths
   - Multiple communication paths between services
   - Automatic failover on path failure
   - Health checks for path availability
   
   ### 4. Connection Pooling
   - Pre-established connection pools
   - Connection reuse for efficiency
   - Graceful connection retirement
   
   ### 5. Network Monitoring
   - Real-time network metrics
   - Latency tracking per service
   - Bandwidth utilization monitoring
   ```

2. **Create network schema registry**:
   ```
   File: repo/main/config/network_schema.json
   Content:
   {
     "version": "1.0",
     "schemas": {
       "market_data": {
         "format": "protobuf",
         "schema_file": "schemas/market_data.proto",
         "version": "1.0.0",
         "services": ["fks_data", "fks_ai", "fks_portfolio"]
       },
       "trading_signal": {
         "format": "protobuf",
         "schema_file": "schemas/trading_signal.proto",
         "version": "1.0.0",
         "services": ["fks_ai", "fks_portfolio", "fks_execution"]
       },
       "order": {
         "format": "protobuf",
         "schema_file": "schemas/order.proto",
         "version": "1.0.0",
         "services": ["fks_execution", "fks_portfolio"]
       }
     },
     "connections": {
       "fks_data -> fks_ai": {
         "type": "direct",
         "protocol": "http2",
         "pool_size": 10,
         "timeout_ms": 1000
       },
       "fks_ai -> fks_portfolio": {
         "type": "direct",
         "protocol": "http2",
         "pool_size": 10,
         "timeout_ms": 1000
       },
       "fks_portfolio -> fks_execution": {
         "type": "direct",
         "protocol": "http2",
         "pool_size": 5,
         "timeout_ms": 500
       }
     }
   }
   ```

3. **Create connection pool manager**:
   ```
   File: repo/main/src/network/connection_pool.py
   Content:
   from typing import Dict, List
   import httpx
   from loguru import logger
   
   class ConnectionPoolManager:
       """Manage connection pools for service communication"""
       
       def __init__(self):
           self.pools: Dict[str, httpx.AsyncClient] = {}
       
       def get_client(self, service_name: str, base_url: str) -> httpx.AsyncClient:
           """Get or create connection pool for service"""
           if service_name not in self.pools:
               self.pools[service_name] = httpx.AsyncClient(
                   base_url=base_url,
                   timeout=httpx.Timeout(10.0),
                   limits=httpx.Limits(max_keepalive_connections=10, max_connections=20),
                   http2=True  # Use HTTP/2 for better performance
               )
               logger.info(f"Created connection pool for {service_name}")
           
           return self.pools[service_name]
       
       async def close_all(self):
           """Close all connection pools"""
           for service_name, client in self.pools.items():
               await client.aclose()
               logger.info(f"Closed connection pool for {service_name}")
           self.pools.clear()
   ```

**Deliverable**: HFT-inspired network structure implemented

**Success Criteria**: Network schema defined, connection pools created, structure improved

---

## 📊 Success Metrics

### Performance Targets
- Documentation ingestion: 300+ docs in <5 minutes ✅
- Query latency: <2s for natural language queries ✅
- Retrieval accuracy: >0.9 RAGAS faithfulness score ✅
- Signal accuracy improvement: 15-30% ✅
- Code review efficiency: 25-40% improvement ✅

### Business Metrics
- RAG system adoption: 80% of developers use it ✅
- Query success rate: >95% ✅
- Answer quality: >0.9 RAGAS score ✅
- Network structure improvement: 20% faster service communication ✅

---

## 🎯 Implementation Checklist

### Phase 1: RAG Foundation ✅
- [ ] RAG infrastructure set up
- [ ] Document ingestion pipeline implemented
- [ ] Basic RAG query system working
- [ ] 300+ docs ingested

### Phase 2: Advanced RAG ✅
- [ ] HyDE implemented
- [ ] RAPTOR implemented
- [ ] Self-RAG implemented
- [ ] Advanced techniques integrated

### Phase 3: RAG in fks_ai ✅
- [ ] Market data RAG service created
- [ ] RAG integrated into multi-agent debates
- [ ] Semantic routing implemented
- [ ] Signal refinement working

### Phase 4: Evaluation ✅
- [ ] RAGAS evaluation implemented
- [ ] Evaluation API endpoints created
- [ ] Metrics tracked
- [ ] Thresholds met

### Phase 5: Network Structure ✅
- [ ] HFT-inspired network structure defined
- [ ] Network schema registry created
- [ ] Connection pools implemented
- [ ] Structure improvements deployed

---

**This document provides complete, step-by-step instructions for AI agents to implement RAG across FKS services. Follow tasks sequentially, ensuring all deliverables are created and success criteria are met.**


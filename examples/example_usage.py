#!/usr/bin/env python3
"""
FKS Platform - Example Usage Scripts

This file contains example usage patterns for all FKS Platform features.
"""

import asyncio
import httpx
from typing import Dict, Any


# ============================================================================
# Multi-Agent Trading Bots Examples
# ============================================================================

async def example_stockbot_signal():
    """Example: Get StockBot signal"""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "http://localhost:8001/ai/bots/stock/signal",
            json={
                "symbol": "AAPL",
                "market_data": {
                    "close": 150.0,
                    "open": 149.0,
                    "high": 151.0,
                    "low": 148.0,
                    "volume": 1000000,
                    "data": [
                        {
                            "open": 149.0,
                            "high": 151.0,
                            "low": 148.0,
                            "close": 150.0,
                            "volume": 1000000
                        }
                    ]
                }
            }
        )
        result = response.json()
        print(f"StockBot Signal: {result['signal']} (confidence: {result['confidence']})")
        return result


async def example_consensus_signal():
    """Example: Get multi-bot consensus signal"""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "http://localhost:8001/ai/bots/consensus",
            json={
                "symbol": "BTC-USD",
                "market_data": {
                    "close": 50000.0,
                    "open": 49000.0,
                    "high": 51000.0,
                    "low": 48000.0,
                    "volume": 100000000,
                    "data": [
                        {
                            "open": 49000.0,
                            "high": 51000.0,
                            "low": 48000.0,
                            "close": 50000.0,
                            "volume": 100000000
                        }
                    ]
                },
                "include_stock": True,
                "include_forex": True,
                "include_crypto": True
            }
        )
        result = response.json()
        print(f"Consensus Signal: {result['consensus_signal']['signal']} "
              f"(confidence: {result['consensus_signal']['confidence']})")
        return result


# ============================================================================
# RAG System Examples
# ============================================================================

async def example_rag_query():
    """Example: Query RAG system"""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "http://localhost:8004/api/v1/rag/query",
            json={
                "query": "How does portfolio optimization work?",
                "filter": {
                    "service": "fks_portfolio"
                }
            }
        )
        result = response.json()
        print(f"RAG Answer: {result['answer'][:100]}...")
        print(f"Sources: {len(result['sources'])} documents retrieved")
        return result


async def example_rag_ingest():
    """Example: Ingest documents into RAG system"""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "http://localhost:8004/api/v1/rag/ingest",
            json={
                "root_dir": "/path/to/fks",
                "include_code": True,
                "clear_existing": False
            }
        )
        result = response.json()
        print(f"Ingestion Status: {result['status']}")
        print(f"Documents Added: {result['documents_added']}")
        return result


async def example_rag_evaluate():
    """Example: Evaluate RAG quality"""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "http://localhost:8004/api/v1/rag/evaluate",
            json={
                "query": "How does portfolio optimization work?",
                "answer": "Portfolio optimization uses mean-variance optimization...",
                "contexts": [
                    "Context 1: Mean-variance optimization...",
                    "Context 2: Risk management..."
                ]
            }
        )
        result = response.json()
        print(f"RAGAS Metrics: {result['metrics']}")
        print(f"Overall Score: {result['overall_score']}")
        return result


# ============================================================================
# PPO Training Examples
# ============================================================================

def example_ppo_training():
    """Example: Train PPO model (command-line)"""
    import subprocess
    
    # This would be run from command line:
    # python -m training.src.ppo.train_trading_ppo \
    #     --ticker AAPL \
    #     --start-date 2020-01-01 \
    #     --end-date 2025-01-01 \
    #     --max-episodes 1000 \
    #     --data-source yfinance \
    #     --use-mlflow
    
    print("PPO Training Example:")
    print("python -m training.src.ppo.train_trading_ppo \\")
    print("    --ticker AAPL \\")
    print("    --start-date 2020-01-01 \\")
    print("    --end-date 2025-01-01 \\")
    print("    --max-episodes 1000 \\")
    print("    --data-source yfinance \\")
    print("    --use-mlflow")


def example_ppo_evaluation():
    """Example: Evaluate PPO model (command-line)"""
    # This would be run from command line:
    # python -m training.src.ppo.evaluate_model \
    #     --model-path ./models/ppo/ppo_meta_learning.pt \
    #     --ticker AAPL \
    #     --start-date 2024-01-01 \
    #     --end-date 2025-01-01 \
    #     --n-episodes 10 \
    #     --compare-baseline
    
    print("PPO Evaluation Example:")
    print("python -m training.src.ppo.evaluate_model \\")
    print("    --model-path ./models/ppo/ppo_meta_learning.pt \\")
    print("    --ticker AAPL \\")
    print("    --start-date 2024-01-01 \\")
    print("    --end-date 2025-01-01 \\")
    print("    --n-episodes 10 \\")
    print("    --compare-baseline")


# ============================================================================
# Python API Examples
# ============================================================================

async def example_python_bots():
    """Example: Use bots directly in Python"""
    from src.agents.stockbot import StockBot
    from src.agents.cryptobot import CryptoBot
    
    # StockBot
    stock_bot = StockBot()
    market_data = {
        "data": [
            {"open": 149, "high": 151, "low": 148, "close": 150, "volume": 1000000}
        ]
    }
    signal = await stock_bot.analyze("AAPL", market_data)
    print(f"StockBot Signal: {signal['signal']} (confidence: {signal['confidence']})")
    
    # CryptoBot
    crypto_bot = CryptoBot()
    signal = await crypto_bot.analyze("BTC-USD", market_data)
    print(f"CryptoBot Signal: {signal['signal']} (confidence: {signal['confidence']})")


async def example_python_rag():
    """Example: Use RAG system directly in Python"""
    from src.rag.query_service import RAGQueryService
    from src.rag.config import RAGConfig
    from src.rag.vector_store import VectorStoreManager
    
    # Initialize
    config = RAGConfig()
    vector_store = VectorStoreManager(config)
    query_service = RAGQueryService(config, vector_store)
    
    # Query
    result = query_service.query("How does portfolio optimization work?")
    print(f"RAG Answer: {result['answer'][:100]}...")
    print(f"Sources: {len(result['sources'])} documents")


def example_python_ppo():
    """Example: Use PPO components directly in Python"""
    from src.ppo.feature_extractor import FKSFeatureExtractor
    from src.ppo.trading_env import TradingEnv
    from src.ppo.evaluation import PPOEvaluator
    import torch
    
    # Feature extraction
    fe = FKSFeatureExtractor()
    # Use with data...
    
    # Trading environment
    env = TradingEnv(
        ticker="AAPL",
        start_date="2024-01-01",
        end_date="2025-01-01",
        data_source="yfinance"
    )
    
    # Evaluation (after training)
    # model = DualHeadPPOPolicy(feature_dim=22, num_actions=3)
    # model.load_state_dict(torch.load("model.pt"))
    # evaluator = PPOEvaluator(model, env)
    # metrics = evaluator.evaluate_performance(n_episodes=10)
    # print(f"Average Return: {metrics['avg_return']:.2%}")


# ============================================================================
# Main Examples
# ============================================================================

async def main():
    """Run all examples"""
    print("=" * 60)
    print("FKS Platform - Example Usage")
    print("=" * 60)
    print()
    
    print("1. Multi-Agent Trading Bots Examples")
    print("-" * 60)
    # await example_stockbot_signal()
    # await example_consensus_signal()
    print("(Uncomment to run examples)")
    print()
    
    print("2. RAG System Examples")
    print("-" * 60)
    # await example_rag_query()
    # await example_rag_ingest()
    # await example_rag_evaluate()
    print("(Uncomment to run examples)")
    print()
    
    print("3. PPO Training Examples")
    print("-" * 60)
    example_ppo_training()
    print()
    example_ppo_evaluation()
    print()
    
    print("4. Python API Examples")
    print("-" * 60)
    # await example_python_bots()
    # await example_python_rag()
    # example_python_ppo()
    print("(Uncomment to run examples)")
    print()
    
    print("=" * 60)
    print("Examples complete!")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())


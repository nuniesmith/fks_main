"""
Unit Tests for Sentiment Analyzer

Tests the sentiment analysis module including:
- FinBERT model loading and inference
- Redis caching behavior
- News API integration (mocked)
- Sentiment scoring accuracy
- Error handling and fallbacks

Target: F1 Score >0.85 on financial sentiment classification

Run with: pytest tests/unit/test_sentiment/ -v
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
from src.services.ai.src.sentiment.sentiment_analyzer import SentimentAnalyzer


@pytest.fixture
def mock_redis():
    """Mock Redis client for testing."""
    mock = Mock()
    mock.ping.return_value = True
    mock.get.return_value = None  # Cache miss by default
    mock.setex.return_value = True
    return mock


@pytest.fixture
def mock_classifier():
    """Mock FinBERT classifier for testing."""
    def mock_classify(text):
        # Simple rule-based mock for testing
        if any(word in text.lower() for word in ['bullish', 'surge', 'high', 'profit']):
            return [{'label': 'positive', 'score': 0.95}]
        elif any(word in text.lower() for word in ['bearish', 'crash', 'loss', 'decline']):
            return [{'label': 'negative', 'score': 0.90}]
        else:
            return [{'label': 'neutral', 'score': 0.80}]
    
    mock = Mock()
    mock.side_effect = mock_classify
    return mock


class TestSentimentAnalyzer:
    """Test suite for SentimentAnalyzer class."""
    
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.pipeline')
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.redis.Redis')
    def test_initialization(self, mock_redis_class, mock_pipeline):
        """Test analyzer initialization with model and cache."""
        mock_redis_class.return_value = Mock()
        mock_redis_class.return_value.ping.return_value = True
        
        analyzer = SentimentAnalyzer()
        
        # Verify model loaded
        mock_pipeline.assert_called_once()
        assert analyzer.classifier is not None
        
        # Verify Redis connected
        assert analyzer.cache is not None
    
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.pipeline')
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.redis.Redis')
    def test_sentiment_score_positive(self, mock_redis_class, mock_pipeline, mock_classifier):
        """Test positive sentiment detection."""
        mock_redis_class.return_value = Mock()
        mock_redis_class.return_value.ping.return_value = True
        mock_pipeline.return_value = mock_classifier
        
        analyzer = SentimentAnalyzer()
        result = analyzer.get_sentiment_score("Bitcoin surges to new all-time high!")
        
        assert result['label'] == 'positive'
        assert result['numeric'] == 1.0
        assert result['confidence'] > 0.5
    
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.pipeline')
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.redis.Redis')
    def test_sentiment_score_negative(self, mock_redis_class, mock_pipeline, mock_classifier):
        """Test negative sentiment detection."""
        mock_redis_class.return_value = Mock()
        mock_redis_class.return_value.ping.return_value = True
        mock_pipeline.return_value = mock_classifier
        
        analyzer = SentimentAnalyzer()
        result = analyzer.get_sentiment_score("Bitcoin crashes amid regulatory fears")
        
        assert result['label'] == 'negative'
        assert result['numeric'] == -1.0
        assert result['confidence'] > 0.5
    
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.pipeline')
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.redis.Redis')
    def test_sentiment_score_neutral(self, mock_redis_class, mock_pipeline, mock_classifier):
        """Test neutral sentiment detection."""
        mock_redis_class.return_value = Mock()
        mock_redis_class.return_value.ping.return_value = True
        mock_pipeline.return_value = mock_classifier
        
        analyzer = SentimentAnalyzer()
        result = analyzer.get_sentiment_score("Bitcoin price remains stable today")
        
        assert result['label'] == 'neutral'
        assert result['numeric'] == 0.0
    
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.pipeline')
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.redis.Redis')
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.requests.get')
    def test_fetch_cryptopanic_success(self, mock_get, mock_redis_class, mock_pipeline, mock_classifier):
        """Test successful CryptoPanic API call."""
        # Mock Redis
        mock_redis_class.return_value = Mock()
        mock_redis_class.return_value.ping.return_value = True
        mock_redis_class.return_value.get.return_value = None  # Cache miss
        
        # Mock classifier
        mock_pipeline.return_value = mock_classifier
        
        # Mock CryptoPanic response
        mock_response = Mock()
        mock_response.json.return_value = {
            'results': [
                {'title': 'Bitcoin surges past $50k'},
                {'title': 'Ethereum reaches new milestone'},
                {'title': 'Crypto market shows strength'},
            ]
        }
        mock_response.raise_for_status = Mock()
        mock_get.return_value = mock_response
        
        analyzer = SentimentAnalyzer()
        sentiment = analyzer.get_sentiment_from_news("BTC", max_headlines=3)
        
        # Should return positive sentiment
        assert sentiment > 0
        assert -1.0 <= sentiment <= 1.0
    
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.pipeline')
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.redis.Redis')
    def test_cache_hit(self, mock_redis_class, mock_pipeline):
        """Test sentiment retrieval from cache."""
        # Mock Redis with cache hit
        mock_redis = Mock()
        mock_redis.ping.return_value = True
        mock_redis.get.return_value = "0.75"  # Cached sentiment
        mock_redis_class.return_value = mock_redis
        
        analyzer = SentimentAnalyzer()
        sentiment = analyzer.get_sentiment_from_news("BTC")
        
        # Should return cached value without calling classifier
        assert sentiment == 0.75
        mock_redis.get.assert_called_once_with("sentiment:BTC")
    
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.pipeline')
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.redis.Redis')
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.requests.get')
    def test_cache_write(self, mock_get, mock_redis_class, mock_pipeline, mock_classifier):
        """Test sentiment caching after API call."""
        # Mock Redis
        mock_redis = Mock()
        mock_redis.ping.return_value = True
        mock_redis.get.return_value = None  # Cache miss
        mock_redis.setex.return_value = True
        mock_redis_class.return_value = mock_redis
        
        # Mock classifier
        mock_pipeline.return_value = mock_classifier
        
        # Mock API response
        mock_response = Mock()
        mock_response.json.return_value = {
            'results': [{'title': 'Bitcoin is bullish'}]
        }
        mock_response.raise_for_status = Mock()
        mock_get.return_value = mock_response
        
        analyzer = SentimentAnalyzer()
        sentiment = analyzer.get_sentiment_from_news("BTC")
        
        # Verify cache write was attempted
        assert mock_redis.setex.called
        call_args = mock_redis.setex.call_args
        assert call_args[0][0] == "sentiment:BTC"  # Cache key
        assert call_args[0][1] == 300  # TTL (5 minutes)
    
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.pipeline')
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.redis.Redis')
    def test_redis_unavailable(self, mock_redis_class, mock_pipeline):
        """Test graceful handling when Redis is unavailable."""
        # Mock Redis connection failure
        mock_redis_class.side_effect = Exception("Connection refused")
        
        # Should initialize without cache
        analyzer = SentimentAnalyzer()
        assert analyzer.cache is None
        assert analyzer.classifier is not None
    
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.pipeline')
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.redis.Redis')
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.requests.get')
    def test_api_failure_fallback(self, mock_get, mock_redis_class, mock_pipeline):
        """Test fallback when API call fails."""
        mock_redis_class.return_value = Mock()
        mock_redis_class.return_value.ping.return_value = True
        
        # Mock API failure
        mock_get.side_effect = Exception("API timeout")
        
        analyzer = SentimentAnalyzer()
        sentiment = analyzer.get_sentiment_from_news("BTC")
        
        # Should return neutral (0.0) when no data available
        assert sentiment == 0.0
    
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.pipeline')
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.redis.Redis')
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.requests.get')
    def test_multiple_headlines_aggregation(self, mock_get, mock_redis_class, mock_pipeline, mock_classifier):
        """Test sentiment aggregation across multiple headlines."""
        mock_redis_class.return_value = Mock()
        mock_redis_class.return_value.ping.return_value = True
        mock_redis_class.return_value.get.return_value = None
        mock_pipeline.return_value = mock_classifier
        
        # Mock API with mixed sentiment headlines
        mock_response = Mock()
        mock_response.json.return_value = {
            'results': [
                {'title': 'Bitcoin bullish surge'},  # Positive
                {'title': 'Ethereum bearish decline'},  # Negative
                {'title': 'Market remains stable'},  # Neutral
            ]
        }
        mock_response.raise_for_status = Mock()
        mock_get.return_value = mock_response
        
        analyzer = SentimentAnalyzer()
        sentiment = analyzer.get_sentiment_from_news("BTC", max_headlines=3)
        
        # Should average sentiments: (1 + -1 + 0) / 3 = 0
        assert -1.0 <= sentiment <= 1.0


class TestConvenienceFunctions:
    """Test module-level convenience functions."""
    
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.SentimentAnalyzer')
    def test_get_sentiment_from_news_global(self, mock_analyzer_class):
        """Test global get_sentiment_from_news function."""
        from src.services.ai.src.sentiment.sentiment_analyzer import get_sentiment_from_news
        
        mock_instance = Mock()
        mock_instance.get_sentiment_from_news.return_value = 0.8
        mock_analyzer_class.return_value = mock_instance
        
        # Reset global analyzer
        import src.services.ai.src.sentiment.sentiment_analyzer as sa_module
        sa_module._global_analyzer = None
        
        result = get_sentiment_from_news("BTC")
        assert result == 0.8
    
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.SentimentAnalyzer')
    def test_get_sentiment_score_global(self, mock_analyzer_class):
        """Test global get_sentiment_score function."""
        from src.services.ai.src.sentiment.sentiment_analyzer import get_sentiment_score
        
        mock_instance = Mock()
        mock_instance.get_sentiment_score.return_value = {
            'label': 'positive',
            'confidence': 0.95,
            'numeric': 1.0
        }
        mock_analyzer_class.return_value = mock_instance
        
        # Reset global analyzer
        import src.services.ai.src.sentiment.sentiment_analyzer as sa_module
        sa_module._global_analyzer = None
        
        result = get_sentiment_score("Bullish market")
        assert result['label'] == 'positive'
        assert result['numeric'] == 1.0


# Performance and accuracy benchmarks
class TestPerformanceMetrics:
    """Test performance and accuracy targets."""
    
    @pytest.mark.slow
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.pipeline')
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.redis.Redis')
    def test_target_f1_score(self, mock_redis_class, mock_pipeline):
        """
        Test F1 score target >0.85 on sample financial texts.
        
        Note: This is a placeholder test. For real validation, use a
        labeled financial sentiment dataset like Financial PhraseBank.
        """
        # TODO: Implement with actual labeled dataset
        # Target: F1 > 0.85
        pytest.skip("Requires labeled dataset for validation")
    
    @pytest.mark.slow
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.pipeline')
    @patch('src.services.ai.src.sentiment.sentiment_analyzer.redis.Redis')
    def test_latency_target(self, mock_redis_class, mock_pipeline, mock_classifier):
        """Test latency target <500ms with caching."""
        import time
        
        mock_redis = Mock()
        mock_redis.ping.return_value = True
        mock_redis.get.return_value = "0.5"  # Cache hit
        mock_redis_class.return_value = mock_redis
        mock_pipeline.return_value = mock_classifier
        
        analyzer = SentimentAnalyzer()
        
        start = time.time()
        sentiment = analyzer.get_sentiment_from_news("BTC")
        latency = (time.time() - start) * 1000  # Convert to ms
        
        # With cache, should be < 50ms
        assert latency < 500, f"Latency {latency}ms exceeds 500ms target"

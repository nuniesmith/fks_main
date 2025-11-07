"""
Tests for ASMBTR prediction task with sentiment integration.

Tests cover:
1. Sentiment integration in prediction generation
2. Hybrid signal calculation (technical + sentiment weighting)
3. Fallback behavior when sentiment unavailable
4. Configuration options (sentiment_weight, enable_sentiment)
"""

import json
from datetime import UTC, datetime
from decimal import Decimal
from typing import Any, Dict
from unittest.mock import MagicMock, Mock, patch

import pytest


class MockBTRState:
    """Mock BTR state for testing."""

    def __init__(self, sequence: str = "10110011"):
        self.sequence = sequence


class MockPrediction:
    """Mock prediction from PredictionTable."""

    def __init__(
        self, prediction: str = "UP", confidence: float = 0.75, up_prob: float = 0.75, down_prob: float = 0.25
    ):
        self.prediction = prediction
        self.confidence = confidence
        self.up_probability = up_prob
        self.down_probability = down_prob


@pytest.fixture
def mock_redis():
    """Mock Redis client."""
    with patch("redis.from_url") as mock_from_url:
        redis_mock = MagicMock()
        redis_mock.setex = MagicMock()
        redis_mock.get = MagicMock(return_value=None)
        mock_from_url.return_value = redis_mock
        yield redis_mock


@pytest.fixture
def mock_sentiment():
    """Mock sentiment analysis module."""
    with patch("repo.app.src.tasks.asmbtr_prediction.get_sentiment_from_news") as mock_get:
        mock_get.return_value = 0.5  # Default positive sentiment
        yield mock_get


@pytest.fixture
def mock_asmbtr_components():
    """Mock ASMBTR components (StateEncoder, PredictionTable)."""
    with patch("repo.app.src.tasks.asmbtr_prediction.StateEncoder") as mock_encoder_cls, \
         patch("repo.app.src.tasks.asmbtr_prediction.PredictionTable") as mock_predictor_cls:
        
        # Mock StateEncoder instance
        encoder_instance = MagicMock()
        encoder_instance.get_current_state = MagicMock(return_value=MockBTRState("10110011"))
        encoder_instance.process_tick = MagicMock()
        mock_encoder_cls.return_value = encoder_instance

        # Mock PredictionTable instance
        predictor_instance = MagicMock()
        predictor_instance.predict = MagicMock(return_value=MockPrediction("UP", 0.75, 0.75, 0.25))
        mock_predictor_cls.return_value = predictor_instance

        yield {
            "encoder_cls": mock_encoder_cls,
            "encoder": encoder_instance,
            "predictor_cls": mock_predictor_cls,
            "predictor": predictor_instance,
        }


@pytest.fixture
def prediction_service(mock_redis, mock_sentiment, mock_asmbtr_components):
    """Create ASMBTRPredictionService with mocked dependencies."""
    from repo.app.src.tasks.asmbtr_prediction import ASMBTRPredictionService

    service = ASMBTRPredictionService(
        redis_url="redis://localhost:6379/1",
        depth=8,
        confidence_threshold=Decimal("0.60"),
        sentiment_weight=0.25,
        enable_sentiment=True,
    )
    return service


class TestSentimentIntegration:
    """Test sentiment integration in ASMBTR predictions."""

    def test_sentiment_weight_in_init(self, mock_redis, mock_asmbtr_components):
        """Test sentiment_weight parameter initialization."""
        from repo.app.src.tasks.asmbtr_prediction import ASMBTRPredictionService

        service = ASMBTRPredictionService(sentiment_weight=0.3)
        assert service.sentiment_weight == 0.3
        assert service.technical_weight == 0.7
        assert service.enable_sentiment is True

    def test_disable_sentiment(self, mock_redis, mock_asmbtr_components):
        """Test disabling sentiment analysis."""
        from repo.app.src.tasks.asmbtr_prediction import ASMBTRPredictionService

        service = ASMBTRPredictionService(enable_sentiment=False)
        assert service.enable_sentiment is False

    def test_sentiment_fetched_during_prediction(self, prediction_service, mock_sentiment, mock_asmbtr_components):
        """Test sentiment is fetched and used in prediction."""
        # Set up mock sentiment
        mock_sentiment.return_value = 0.6  # Positive sentiment

        # Generate prediction
        state = MockBTRState("10110011")
        result = prediction_service.generate_prediction("BTC/USDT", state)

        # Verify sentiment was fetched
        mock_sentiment.assert_called_once_with("BTC")

        # Verify result includes sentiment
        assert result is not None
        assert "sentiment_score" in result
        assert result["sentiment_score"] == 0.6
        assert "hybrid_signal" in result
        assert "sentiment_enabled" in result
        assert result["sentiment_enabled"] is True

    def test_hybrid_signal_calculation_positive_sentiment(self, prediction_service, mock_sentiment, mock_asmbtr_components):
        """Test hybrid signal with positive sentiment and UP technical prediction."""
        mock_sentiment.return_value = 0.5
        mock_asmbtr_components["predictor"].predict.return_value = MockPrediction("UP", 0.75, 0.75, 0.25)

        state = MockBTRState("10110011")
        result = prediction_service.generate_prediction("BTC/USDT", state)

        # technical_signal = 1.0 (UP)
        # sentiment_score = 0.5
        # hybrid = 0.75 * 1.0 + 0.25 * 0.5 = 0.75 + 0.125 = 0.875
        expected_hybrid = 0.875
        assert result["technical_signal"] == 1.0
        assert result["sentiment_score"] == 0.5
        assert abs(result["hybrid_signal"] - expected_hybrid) < 0.01
        assert result["prediction"] == "UP"

    def test_hybrid_signal_calculation_negative_sentiment(self, prediction_service, mock_sentiment, mock_asmbtr_components):
        """Test hybrid signal with negative sentiment and UP technical prediction."""
        mock_sentiment.return_value = -0.6  # Negative sentiment
        mock_asmbtr_components["predictor"].predict.return_value = MockPrediction("UP", 0.75, 0.75, 0.25)

        state = MockBTRState("10110011")
        result = prediction_service.generate_prediction("BTC/USDT", state)

        # technical_signal = 1.0 (UP)
        # sentiment_score = -0.6
        # hybrid = 0.75 * 1.0 + 0.25 * (-0.6) = 0.75 - 0.15 = 0.6
        expected_hybrid = 0.6
        assert result["technical_signal"] == 1.0
        assert result["sentiment_score"] == -0.6
        assert abs(result["hybrid_signal"] - expected_hybrid) < 0.01
        assert result["prediction"] == "UP"

    def test_hybrid_signal_down_technical_positive_sentiment(self, prediction_service, mock_sentiment, mock_asmbtr_components):
        """Test hybrid signal with DOWN technical and positive sentiment."""
        mock_sentiment.return_value = 0.8  # Strong positive sentiment
        mock_asmbtr_components["predictor"].predict.return_value = MockPrediction("DOWN", 0.70, 0.30, 0.70)

        state = MockBTRState("10110011")
        result = prediction_service.generate_prediction("BTC/USDT", state)

        # technical_signal = -1.0 (DOWN)
        # sentiment_score = 0.8
        # hybrid = 0.75 * (-1.0) + 0.25 * 0.8 = -0.75 + 0.2 = -0.55
        expected_hybrid = -0.55
        assert result["technical_signal"] == -1.0
        assert result["sentiment_score"] == 0.8
        assert abs(result["hybrid_signal"] - expected_hybrid) < 0.01
        assert result["prediction"] == "DOWN"  # Still bearish despite positive sentiment

    def test_hybrid_signal_neutral_technical(self, prediction_service, mock_sentiment, mock_asmbtr_components):
        """Test hybrid signal with NEUTRAL technical prediction."""
        mock_sentiment.return_value = 0.3
        mock_asmbtr_components["predictor"].predict.return_value = MockPrediction("NEUTRAL", 0.50, 0.50, 0.50)

        state = MockBTRState("10110011")
        result = prediction_service.generate_prediction("BTC/USDT", state)

        # technical_signal = 0.0 (NEUTRAL)
        # sentiment_score = 0.3
        # hybrid = 0.75 * 0.0 + 0.25 * 0.3 = 0.075
        expected_hybrid = 0.075
        assert result["technical_signal"] == 0.0
        assert result["sentiment_score"] == 0.3
        assert abs(result["hybrid_signal"] - expected_hybrid) < 0.01
        # hybrid 0.075 < 0.1 threshold, so NEUTRAL
        assert result["prediction"] == "NEUTRAL"

    def test_sentiment_fallback_on_error(self, prediction_service, mock_sentiment, mock_asmbtr_components):
        """Test sentiment fetch error handling (fallback to 0.0)."""
        mock_sentiment.side_effect = Exception("API error")
        mock_asmbtr_components["predictor"].predict.return_value = MockPrediction("UP", 0.75, 0.75, 0.25)

        state = MockBTRState("10110011")
        result = prediction_service.generate_prediction("BTC/USDT", state)

        # Sentiment should fallback to 0.0 on error
        assert result["sentiment_score"] == 0.0
        # hybrid = 0.75 * 1.0 + 0.25 * 0.0 = 0.75
        assert abs(result["hybrid_signal"] - 0.75) < 0.01
        assert result["prediction"] == "UP"

    def test_sentiment_disabled(self, mock_redis, mock_sentiment, mock_asmbtr_components):
        """Test prediction with sentiment disabled."""
        from repo.app.src.tasks.asmbtr_prediction import ASMBTRPredictionService

        service = ASMBTRPredictionService(enable_sentiment=False)
        mock_asmbtr_components["predictor"].predict.return_value = MockPrediction("UP", 0.75, 0.75, 0.25)

        state = MockBTRState("10110011")
        result = service.generate_prediction("BTC/USDT", state)

        # Sentiment should not be fetched
        mock_sentiment.assert_not_called()

        # Sentiment score should be 0.0
        assert result["sentiment_score"] == 0.0
        assert result["sentiment_enabled"] is False
        # hybrid = 0.75 * 1.0 + 0.25 * 0.0 = 0.75
        assert abs(result["hybrid_signal"] - 0.75) < 0.01
        assert result["prediction"] == "UP"


class TestHybridSignalEdgeCases:
    """Test edge cases in hybrid signal calculation."""

    def test_extreme_positive_sentiment(self, prediction_service, mock_sentiment, mock_asmbtr_components):
        """Test with extreme positive sentiment (+1.0)."""
        mock_sentiment.return_value = 1.0
        mock_asmbtr_components["predictor"].predict.return_value = MockPrediction("DOWN", 0.65, 0.35, 0.65)

        state = MockBTRState("10110011")
        result = prediction_service.generate_prediction("BTC/USDT", state)

        # technical = -1.0, sentiment = 1.0
        # hybrid = 0.75 * (-1.0) + 0.25 * 1.0 = -0.75 + 0.25 = -0.5
        assert abs(result["hybrid_signal"] - (-0.5)) < 0.01
        assert result["prediction"] == "DOWN"

    def test_extreme_negative_sentiment(self, prediction_service, mock_sentiment, mock_asmbtr_components):
        """Test with extreme negative sentiment (-1.0)."""
        mock_sentiment.return_value = -1.0
        mock_asmbtr_components["predictor"].predict.return_value = MockPrediction("UP", 0.65, 0.65, 0.35)

        state = MockBTRState("10110011")
        result = prediction_service.generate_prediction("BTC/USDT", state)

        # technical = 1.0, sentiment = -1.0
        # hybrid = 0.75 * 1.0 + 0.25 * (-1.0) = 0.75 - 0.25 = 0.5
        assert abs(result["hybrid_signal"] - 0.5) < 0.01
        assert result["prediction"] == "UP"

    def test_high_sentiment_weight(self, mock_redis, mock_sentiment, mock_asmbtr_components):
        """Test with higher sentiment weight (0.4)."""
        from repo.app.src.tasks.asmbtr_prediction import ASMBTRPredictionService

        service = ASMBTRPredictionService(sentiment_weight=0.4)
        mock_sentiment.return_value = 0.8
        mock_asmbtr_components["predictor"].predict.return_value = MockPrediction("UP", 0.75, 0.75, 0.25)

        state = MockBTRState("10110011")
        result = service.generate_prediction("BTC/USDT", state)

        # technical = 1.0, sentiment = 0.8, weight = 0.4
        # hybrid = 0.6 * 1.0 + 0.4 * 0.8 = 0.6 + 0.32 = 0.92
        assert abs(result["hybrid_signal"] - 0.92) < 0.01
        assert result["prediction"] == "UP"


class TestSymbolFormatHandling:
    """Test symbol format handling for sentiment analysis."""

    def test_symbol_with_slash(self, prediction_service, mock_sentiment, mock_asmbtr_components):
        """Test symbol format conversion (BTC/USDT → BTC)."""
        mock_sentiment.return_value = 0.5
        mock_asmbtr_components["predictor"].predict.return_value = MockPrediction("UP", 0.75, 0.75, 0.25)

        state = MockBTRState("10110011")
        result = prediction_service.generate_prediction("BTC/USDT", state)

        # Verify symbol was converted to base (BTC)
        mock_sentiment.assert_called_once_with("BTC")
        assert result["symbol"] == "BTC/USDT"

    def test_symbol_without_slash(self, prediction_service, mock_sentiment, mock_asmbtr_components):
        """Test symbol without slash (BTCUSDT)."""
        mock_sentiment.return_value = 0.5
        mock_asmbtr_components["predictor"].predict.return_value = MockPrediction("UP", 0.75, 0.75, 0.25)

        state = MockBTRState("10110011")
        result = prediction_service.generate_prediction("BTCUSDT", state)

        # Should use full symbol when no slash
        mock_sentiment.assert_called_once_with("BTCUSDT")
        assert result["symbol"] == "BTCUSDT"


class TestCeleryTask:
    """Test Celery task integration."""

    @patch("repo.app.src.tasks.asmbtr_prediction.ASMBTRPredictionService")
    def test_task_uses_default_symbols(self, mock_service_cls):
        """Test task uses default symbols when none provided."""
        from repo.app.src.tasks.asmbtr_prediction import predict_asmbtr_task

        mock_service = MagicMock()
        mock_service.run_prediction_cycle = MagicMock()
        mock_service_cls.return_value = mock_service

        # Call task without symbols
        result = predict_asmbtr_task()

        # Verify default symbols used
        mock_service.run_prediction_cycle.assert_called_once_with(["BTC/USDT", "ETH/USDT"])
        assert result["status"] == "success"
        assert result["symbols"] == ["BTC/USDT", "ETH/USDT"]

    @patch("repo.app.src.tasks.asmbtr_prediction.ASMBTRPredictionService")
    def test_task_uses_custom_symbols(self, mock_service_cls):
        """Test task with custom symbols."""
        from repo.app.src.tasks.asmbtr_prediction import predict_asmbtr_task

        mock_service = MagicMock()
        mock_service.run_prediction_cycle = MagicMock()
        mock_service_cls.return_value = mock_service

        custom_symbols = ["SOL/USDT", "ADA/USDT"]
        result = predict_asmbtr_task(symbols=custom_symbols)

        mock_service.run_prediction_cycle.assert_called_once_with(custom_symbols)
        assert result["symbols"] == custom_symbols


class TestPredictionStorage:
    """Test prediction storage in Redis."""

    def test_store_prediction_includes_sentiment_fields(self, prediction_service, mock_sentiment, mock_asmbtr_components, mock_redis):
        """Test stored prediction includes sentiment fields."""
        mock_sentiment.return_value = 0.6
        mock_asmbtr_components["predictor"].predict.return_value = MockPrediction("UP", 0.75, 0.75, 0.25)

        state = MockBTRState("10110011")
        result = prediction_service.generate_prediction("BTC/USDT", state)
        prediction_service.store_prediction("BTC/USDT", result)

        # Verify Redis setex was called
        mock_redis.setex.assert_called_once()
        call_args = mock_redis.setex.call_args
        key, ttl, value = call_args[0]

        assert key == "asmbtr:predictions:BTC/USDT"
        assert ttl == 120

        # Parse stored JSON
        stored_data = json.loads(value)
        assert "sentiment_score" in stored_data
        assert "hybrid_signal" in stored_data
        assert "technical_signal" in stored_data
        assert "sentiment_enabled" in stored_data
        assert stored_data["sentiment_score"] == 0.6


if __name__ == "__main__":
    pytest.main([__file__, "-v"])

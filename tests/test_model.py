from src.model import SentimentModel

model = SentimentModel()


def test_positive_sentiment():
    result = model.predict("J'adore ce produit, c'est super bien")
    assert result["label"] == "POSITIVE"


def test_negative_sentiment():
    result = model.predict("C'est un produit horrible et nul")
    assert result["label"] == "NEGATIVE"


def test_neutral_sentiment():
    result = model.predict("Je regarde un produit")
    assert result["label"] == "NEUTRAL"
# build de test n°2 - vérification du pipeline
from fastapi import FastAPI  # type: ignore
from src.schemas import PredictionRequest, PredictionResponse  # type: ignore
from src.model import SentimentModel  # type: ignore

app = FastAPI(title="SentimentAI", version="0.1.0")

# Le modèle est chargé une seule fois au démarrage du serveur
model = SentimentModel()


@app.get("/health")
def health():
    """Endpoint de healthcheck utilisé par Docker et les load balancers."""
    return {"status": "ok"}


@app.post("/predict", response_model=PredictionResponse)
def predict(request: PredictionRequest):
    """Analyse le sentiment du texte fourni et retourne un label + score."""
    return model.predict(request.text)

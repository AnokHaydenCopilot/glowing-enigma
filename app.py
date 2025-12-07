"""
FastAPI application for Iris classification model inference.
This API loads a pre-trained model and provides a prediction endpoint.
"""

import pickle
from typing import List
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field, validator
import numpy as np
import uvicorn


# Pydantic models for request/response validation
class IrisFeatures(BaseModel):
    """Input features for Iris classification"""
    sepal_length: float = Field(..., ge=0, description="Sepal length in cm")
    sepal_width: float = Field(..., ge=0, description="Sepal width in cm")
    petal_length: float = Field(..., ge=0, description="Petal length in cm")
    petal_width: float = Field(..., ge=0, description="Petal width in cm")
    
    @validator('*')
    def check_positive(cls, v):
        if v < 0:
            raise ValueError('All measurements must be positive')
        return v
    
    class Config:
        schema_extra = {
            "example": {
                "sepal_length": 5.1,
                "sepal_width": 3.5,
                "petal_length": 1.4,
                "petal_width": 0.2
            }
        }


class PredictionResponse(BaseModel):
    """Response model for predictions"""
    prediction: int = Field(..., description="Predicted class (0=setosa, 1=versicolor, 2=virginica)")
    class_name: str = Field(..., description="Human-readable class name")
    confidence: float = Field(..., description="Prediction confidence (probability)")
    probabilities: List[float] = Field(..., description="Probabilities for all classes")


# Initialize FastAPI app
app = FastAPI(
    title="Iris Classification API",
    description="A simple ML API for classifying Iris flowers using Logistic Regression",
    version="1.0.0"
)

# Global variable to store the loaded model
model = None
class_names = ["setosa", "versicolor", "virginica"]


@app.on_event("startup")
async def load_model():
    """Load the trained model on application startup"""
    global model
    try:
        with open("model.pkl", "rb") as f:
            model = pickle.load(f)
        print("Model loaded successfully!")
    except FileNotFoundError:
        print("ERROR: model.pkl not found. Please train the model first.")
        raise
    except Exception as e:
        print(f"ERROR loading model: {e}")
        raise


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "message": "Iris Classification API is running!",
        "status": "healthy",
        "model_loaded": model is not None
    }


@app.get("/health")
async def health_check():
    """Health check endpoint for container orchestration"""
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    return {"status": "healthy"}


@app.post("/predict", response_model=PredictionResponse)
async def predict(features: IrisFeatures):
    """
    Predict the Iris flower class based on input features.
    
    Args:
        features: IrisFeatures object containing sepal and petal measurements
        
    Returns:
        PredictionResponse with prediction, class name, and confidence
    """
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    try:
        # Convert input features to numpy array
        input_data = np.array([[
            features.sepal_length,
            features.sepal_width,
            features.petal_length,
            features.petal_width
        ]])
        
        # Make prediction
        prediction = int(model.predict(input_data)[0])
        probabilities = model.predict_proba(input_data)[0].tolist()
        
        # Get the confidence (max probability)
        confidence = max(probabilities)
        
        return PredictionResponse(
            prediction=prediction,
            class_name=class_names[prediction],
            confidence=confidence,
            probabilities=probabilities
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")


if __name__ == "__main__":
    # Run the API locally for development
    uvicorn.run(app, host="0.0.0.0", port=8000)

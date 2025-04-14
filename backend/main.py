from fastapi import FastAPI, UploadFile, File
from model.model_loader import load_model, preprocess_image
import torch

app = FastAPI()
model = load_model()
class_names = ['fresh', 'rotten']  # classes

@app.get("/")
def root():
    return {"message": "FoodCheck-API running"}

@app.post("/predict/")
async def predict(file: UploadFile = File(...)):
    image = await file.read()
    input_tensor = preprocess_image(image)
    with torch.no_grad():
        output = model(input_tensor)
        probs = torch.nn.functional.softmax(output[0], dim=0)
        pred = probs.argmax().item()
    return {
        "label": class_names[pred],
        "confidence": float(probs[pred])
    }
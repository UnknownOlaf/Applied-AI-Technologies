from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from model.model_loader import load_model, preprocess_image
import torch

app = FastAPI()
model = load_model()
class_names = ['freshapples', 'freshbanana', 'freshoranges', 'rottenapples', 'rottenbanana', 'rottenoranges']

# CORS middleware for frontend access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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
        pred_index = probs.argmax().item()

    label = class_names[pred_index]
    class_confidence = float(probs[pred_index])

    # Aggregate category confidence
    fresh_score = sum(p.item() for i, p in enumerate(probs) if "fresh" in class_names[i])
    rotten_score = sum(p.item() for i, p in enumerate(probs) if "rotten" in class_names[i])

    category = "fresh" if fresh_score > rotten_score else "rotten"
    category_confidence = max(fresh_score, rotten_score)

    return {
        "category": category,
        "confidence": round(category_confidence, 4),
        "label": label,
        "class_confidence": round(class_confidence, 4),
        "score": {
            "fresh": round(fresh_score, 4),
            "rotten": round(rotten_score, 4)
        }
    }

import torch
import torchvision.transforms as transforms
from torchvision.models import resnet18, ResNet18_Weights
from PIL import Image
from io import BytesIO

def load_model():
    model = resnet18(weights=ResNet18_Weights.DEFAULT)
    model.fc = torch.nn.Linear(model.fc.in_features, 6)
    model.load_state_dict(torch.load("model/model.pt", map_location="cpu"))
    model.eval()
    return model

transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225]
    )
])

def preprocess_image(image_bytes):
    image = Image.open(BytesIO(image_bytes)).convert("RGB")
    return transform(image).unsqueeze(0)

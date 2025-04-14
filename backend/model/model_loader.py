import torch
import torchvision.transforms as transforms
from torchvision.models import resnet18
from PIL import Image
from io import BytesIO

def load_model():
    model = resnet18(pretrained=True)
    model.fc = torch.nn.Linear(model.fc.in_features, 2)  # 2 Classes: fresh, rotten
    # model.load_state_dict(torch.load("model/model.pt", map_location="cpu"))  # placeholder
    model.eval()
    return model

transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
])

def preprocess_image(image_bytes):
    image = Image.open(BytesIO(image_bytes)).convert("RGB")
    return transform(image).unsqueeze(0)

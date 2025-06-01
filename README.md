

## 📝 Introduction

**FruitAI** is an AI-powered image classification system that predicts the freshness of fruits (apples, bananas, oranges) based on captured or uploaded images. This project demonstrates a complete stack using FastAPI (Python) for the backend and Flutter (Dart) for the frontend, integrating a PyTorch model for image analysis.


## ✨ Features

- Upload or capture images of fruits directly from the browser
- Classifies fruits as fresh or rotten, with specific class labels (apple, banana, orange)
- Responsive web frontend built with Flutter
- Backend API built with FastAPI, serving predictions from a trained PyTorch model
- Smooth UI animations and transitions for a polished user experience


## ⚙️ Requirements

- **Backend**:
  - Python 3.9 or higher
  - PyTorch 2.6.0
  - FastAPI 0.115.12
  - Uvicorn 0.34.1

- **Frontend**:
  - Flutter 3.19.0 or higher
  - Dart SDK (compatible with Flutter version)


# Applied-AI-Technologies

Repo for the lecture "Applied Artificial Intelligence" at the University of Applied Sciences Esslingen created by [Dionysios Satikidis](mailto:dionysios.satikidis@gmail.com) and [Jan Seyler](mailto:Jan.Seyler@gmail.com).

[Module Description HS Esslingen](https://www.hs-esslingen.de/fileadmin/media/Fakultaeten/it/FAKULTAET/Studiengaenge/Modulhandbuecher/Wahlfachmodul/HE-IT_Modulhandbuch-Wahlfachmodul-_Wahlpflichtfaecher_SWB_TIB_WKB_2019-02-15.pdf)</br>

Check out the Applied-AI [Wiki](https://github.com/MrDio/Applied-AI-Technologies/wiki) for detailed Information. First start with the chapters and intro to NN and DL.

[Chapter0: Intro Lecture and AIM](https://github.com/MrDio/Applied-AI-Technologies/wiki)</br>
[Chapter1: Neuronal Networks and Deep Learning](https://github.com/MrDio/Smartphone-Sensing-Framework/wiki/Neuronal-Networks-&-Deep-Learning)</br>
[Chapter2: Deep Dive Applied AI with RPI3 and Movidius](https://github.com/MrDio/Applied-AI-Technologies/wiki/2.-AI-on-the-Raspberry-Pi-with-the-Movidius-Neural-Compute-Stick)</br>
[Chapter3: Deep Dive Applied AI with Smartphone Sensing Framework and TF for Mobile](https://github.com/MrDio/Applied-AI-Technologies/wiki/1.-AI-on-Smartphone-Sensing)</br>

## Tool references
Sharing Teaser of your project with [Streamlit](https://www.streamlit.io/)</br>
Implementing and training AI models [Google Colab](https://colab.research.google.com/)</br>
Model search framework [Model Search](https://github.com/google/model_search)</br>

[Appendix: Intro into Deep Reinforcement Learning Technologies](https://sites.google.com/view/deep-rl-bootcamp/lectures)</br>
[Appendix: Hackster.io Respected Project Autonomous driving ai](https://www.hackster.io/dhq/autonomous-driving-ai-for-donkey-car-garbage-collector-846c11)</br>
[Appendix: Github.com Respected Project Android AI Car](https://github.com/umadbro96/androidAICar)</br>

Thanks to our contributors:
</br>
[D. Lagamtzis](https://github.com/DimiHMC)</br>
[Peltzfa](https://github.com/peltzefa/)


# FruitAI – Stack & Setup

## Tech Stack

- **Frontend:** Flutter (Dart, Web)
- **Backend:** FastAPI (Python)
- **ML Framework:** PyTorch
- **HTTP Communication:** REST API (JSON)
- **Image Handling:** image_picker (Flutter), FastAPI UploadFile
- **Deployment:** Localhost (dev), ready for Docker/Cloud

---

## Setup Instructions

### 1. Backend (FastAPI + PyTorch)

```bash
cd backend
# (Optional) Create and activate a virtual environment
# python -m venv venv
# source venv/bin/activate  # or venv\Scripts\activate on Windows

pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 2. Frontend (Flutter Web, Dart)

```bash
cd frontend
flutter pub get
flutter run -d chrome
# For production build:
# flutter build web
```

---

## Usage

1. Start the backend (`uvicorn ...`).
2. Start the frontend (`flutter run -d chrome`), which opens a browser window with the webapp running.
3. Upload an image or use the webcam to analyze fruit.

---


## 📁 Project Structure

```
Applied-AI-Technologies/
├── .gitignore
├── LICENSE
├── README.md
├── data_getting_started.csv
├── hse-aai-2019-teamx.ipynb
├── render.yaml
├── .vscode/
│   └── settings.json
├── backend/
│   ├── main.py
│   ├── requirements.txt
│   ├── train.py
│   └── model/
│       ├── model.pt
│       └── model_loader.py
├── frontend/
│   ├── analysis_options.yaml
│   ├── pubspec.lock
│   ├── pubspec.yaml
│   ├── assets/
│   │   └── images/
│   │       ├── ananas.jpg
│   │       └── bananas.jpg
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   ├── camera_screen.dart
│   │   │   ├── result_screen.dart
│   │   │   └── welcome_screen.dart
│   │   ├── utils/
│   │   │   ├── page_transition.dart
│   │   │   └── theme.dart
│   │   └── widgets/
│   │       ├── animated_background.dart
│   │       ├── animated_text.dart
│   │       ├── bounce_button.dart
│   │       ├── chat_bubble.dart
│   │       └── loading_animation.dart
│   └── web/
│       ├── favicon.png
│       ├── index.html
│       └── manifest.json
```


## 🖥️ Backend Overview

The **backend** is a Python application built with **FastAPI** that provides a RESTful API for image classification. It is designed to predict the freshness of fruits based on images. The core components include:

### Main API (`main.py`)

- **Framework**: FastAPI
- **Model loading**: The pre-trained model is loaded at startup using `model_loader.load_model()`.
- **Classes predicted**:  
  - Fresh fruits: `freshapples`, `freshbanana`, `freshoranges`  
  - Rotten fruits: `rottenapples`, `rottenbanana`, `rottenoranges`
- **Endpoints**:
  - `GET /`: Health check, returns `{"message": "FoodCheck-API running"}`
  - `GET /ping`: Returns `{"status": "ok"}` for basic availability check
  - `POST /predict/`:  
    - Accepts an image file (`UploadFile`) via form-data.
    - Returns a **prediction result** containing:
      - `category`: Fresh/rotten
      - `confidence`: Model's confidence
      - `label`: Class label
      - `class_confidence`: Class-specific confidence
      - `score`: Dictionary of probabilities for all classes

### Additional Backend Files

- `train.py`: Contains the training logic for the fruit classification model, using PyTorch.
- `model_loader.py`: Contains logic for loading the trained model and preprocessing input images.
- `model.pt`: The trained PyTorch model file.
- `requirements.txt`: Lists the following Python dependencies:
  - annotated-types==0.7.0
  - anyio==4.9.0
  - click==8.1.8
  - colorama==0.4.6
  - fastapi==0.115.12
  - filelock==3.16.1
  - fsspec==2024.10.0
  - h11==0.14.0
  - idna==3.10
  - Jinja2==3.1.4
  - MarkupSafe==2.1.5
  - mpmath==1.3.0
  - networkx==3.4.2
  - numpy==2.1.2
  - pillow==11.0.0
  - pydantic==2.11.3
  - pydantic_core==2.33.1
  - python-multipart==0.0.20
  - setuptools==70.2.0
  - sniffio==1.3.1
  - starlette==0.46.2
  - sympy==1.13.1
  - torch==2.6.0
  - torchvision==0.21.0
  - typing-inspection==0.4.0
  - typing_extensions==4.12.2
  - uvicorn==0.34.1


## 🌐 Frontend Overview

The **frontend** is a web application built with **Flutter** (Dart) that allows users to upload images or capture them via webcam, then receive classification results for fruit freshness. The app runs in the browser (Web target) and uses modern Flutter components for a responsive, animated user interface.

### Main Components

- **`main.dart`**: The entry point of the app. It sets up routing between the Welcome, Camera, and Result screens. It applies the app theme from `theme.dart`.
- **`camera_screen.dart`**: Provides camera access (via web) to capture fruit images. Integrates with the backend API by sending the captured image.
- **`result_screen.dart`**: Displays classification results received from the backend (fresh/rotten, class name, confidence, etc.).
- **`welcome_screen.dart`**: Intro screen with animation and navigation to the camera.
- **`page_transition.dart`**: Defines custom page transition animations for navigation between screens.
- **`theme.dart`**: Centralizes the color scheme and typography of the app.
- **Custom Widgets**: Includes animated components for a polished look:
  - `animated_background.dart`: Animated background elements.
  - `animated_text.dart`: Animated text effects.
  - `bounce_button.dart`: Interactive button with bounce effect.
  - `chat_bubble.dart`: Chat-style UI element.
  - `loading_animation.dart`: Spinner/loading animation.

### Project Configuration

- **`pubspec.yaml`**: Declares dependencies such as `http`, `image_picker`, and Flutter SDK. It also specifies asset paths for images.
- **`analysis_options.yaml`**: Defines linting rules and analysis settings for Dart code quality.

### Key Features

- **Camera integration** using Flutter Web camera package.
- **Backend communication** via HTTP POST (multipart form data) for image upload.
- **Dynamic result display** with smooth animations.
- **Theming and transitions** handled with custom components.



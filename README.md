Markdown
# 📂 AI_USB

A fully offline, portable AI toolkit that runs entirely from a USB drive without installing any software on the host computer. It is designed to provide a secure, localized environment for writing, studying, note organization, and automated workflow processing.

---

## 👤 Author
Developed and maintained by **Blake Von Jett**.

---

## 🚀 Quick Start

### 1. Initialize the Environment
Copy your `AI_USB_setup.ps1` script to the root directory of your USB drive (e.g., `E:\`), open **PowerShell 5.1**, and run the initialization command:

```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File "E:\AI_USB_setup.ps1"
⚡ Note: This setup script automatically handles the architecture build. It carves out your directory skeletons (notes/, study/, runtimes/, etc.) and dynamically compiles your execution wrappers (Run_Toolkit.bat) and system documentation (HELP.txt) on the fly.

🧠 Adding the AI Programs & Models
Because this repository remains completely lightweight, it does not bundle heavy runtime binaries or multi-gigabyte model weights. Follow these quick steps to fully arm your toolkit:

Step 1: Download the Inference Engine
Download: llama-b9701-bin-win-cpu-x64.zip (16.4 MB)

Placement: Extract the contents of this zip file (including llama-cli.exe and its supporting .dll files) directly into:

AI_USB\runtimes\llama.cpp\
Step 2: Download the AI Models (GGUF)
Download your preferred quantized linguistic models directly from Hugging Face:

📥 Phi-3-Mini (Q4_K_M) (~2.4 GB) — Highly optimized, fast CPU performance.

📥 Mistral-7B-Instruct-v0.3 (Q4_K_M) (~4.4 GB) — Deep reasoning and complex structured text generation.

Placement: Drop your downloaded .gguf files straight into:

AI_USB\runtimes\llama.cpp\models\
🛠️ Execution
Once your runtimes and models are dropped into place:

Open your AI_USB\config\settings.json and verify your default_model path points to the file you want to use.

Double-click Run_Toolkit.bat in the root directory to launch your localized, completely offline AI session.

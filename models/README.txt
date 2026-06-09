VindexLLM Model Files
=======================

Place downloaded GGUF model files in this folder.

Required for inference test (demo\VindexLLMTest):
  gemma-3-4b-it-q4_0.gguf  (~2.5 GB)

Optional for chat/memory features (testbed):
  embeddinggemma-300m-qat-Q8_0.gguf  (~278 MB)

Download links (vetted by tinyBigGAMES):
  Inference model:
  https://huggingface.co/tinybiggames/gemma-3-4b-it-qat-q4_0-gguf/resolve/main/gemma-3-4b-it-q4_0.gguf

  Embedding model:
  https://huggingface.co/tinybiggames/embeddinggemma-300m-qat-Q8_0/resolve/main/embeddinggemma-300m-qat-Q8_0.gguf

Requirements:
  - Windows 10/11 x64
  - Vulkan 1.0+ GPU (NVIDIA, AMD, or Intel)
  - 4+ GB VRAM for Q4_0 inference model
  - 16+ GB system RAM

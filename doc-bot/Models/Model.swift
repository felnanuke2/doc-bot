import Foundation

struct Model: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    let name: String
    let url: String
    let filename: String
    let status: String
}

struct LocalModel  {
    let localPath: URL
}

let completionModels: [Model] = [
    Model(name: "TinyLlama-1.1B (Q4_0, 0.6 GiB)", url: "https://huggingface.co/TheBloke/TinyLlama-1.1B-1T-OpenOrca-GGUF/resolve/main/tinyllama-1.1b-1t-openorca.Q4_0.gguf?download=true", filename: "tinyllama-1.1b-1t-openorca.Q4_0.gguf", status: "download"),
    Model(name: "TinyLlama-1.1B Chat (Q8_0, 1.1 GiB)", url: "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q8_0.gguf?download=true", filename: "tinyllama-1.1b-chat-v1.0.Q8_0.gguf", status: "download"),
    Model(name: "TinyLlama-1.1B (F16, 2.2 GiB)", url: "https://huggingface.co/ggml-org/models/resolve/main/tinyllama-1.1b/ggml-model-f16.gguf?download=true", filename: "tinyllama-1.1b-f16.gguf", status: "download"),
    Model(name: "Phi-2.7B (Q4_0, 1.6 GiB)", url: "https://huggingface.co/ggml-org/models/resolve/main/phi-2/ggml-model-q4_0.gguf?download=true", filename: "phi-2-q4_0.gguf", status: "download"),
    Model(name: "Phi-2.7B (Q8_0, 2.8 GiB)", url: "https://huggingface.co/ggml-org/models/resolve/main/phi-2/ggml-model-q8_0.gguf?download=true", filename: "phi-2-q8_0.gguf", status: "download"),
    Model(name: "Mistral-7B-v0.1 (Q4_0, 3.8 GiB)", url: "https://huggingface.co/TheBloke/Mistral-7B-v0.1-GGUF/resolve/main/mistral-7b-v0.1.Q4_0.gguf?download=true", filename: "mistral-7b-v0.1.Q4_0.gguf", status: "download"),
    Model(name: "OpenHermes-2.5-Mistral-7B (Q3_K_M, 3.52 GiB)", url: "https://huggingface.co/TheBloke/OpenHermes-2.5-Mistral-7B-GGUF/resolve/main/openhermes-2.5-mistral-7b.Q3_K_M.gguf?download=true", filename: "openhermes-2.5-mistral-7b.Q3_K_M.gguf", status: "download")
]

let embeddModels: [Model] = [
    Model(name: "nomic-embed-text-v1.5 (Q4_0, 477 MB)", url: "https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF/resolve/main/nomic-embed-text-v1.5.Q4_0.gguf?download=true", filename: "nomic-embed-text-v1.5.Q4_0.gguf", status: "download"),
    Model(name: "bge-small-en-v1.5 (Q4_0, 418 MB)", url: "https://huggingface.co/ggml-org/models/resolve/main/bge-small-en-v1.5/ggml-model-q4_0.gguf?download=true", filename: "bge-small-en-v1.5-q4_0.gguf", status: "download")
]

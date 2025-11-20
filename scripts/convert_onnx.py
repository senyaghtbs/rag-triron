import torch
import torch.onnx
from transformers import AutoModel, AutoTokenizer
import os

def convert_embedder_to_onnx():
    # Конфигурация
    model_name = "intfloat/e5-small-v2"  # или ваша модель
    onnx_path = "model-repository/embedder/1/model.onnx"
    os.makedirs(os.path.dirname(onnx_path), exist_ok=True)
    
    # Загрузка модели и токенизатора
    print("Loading model...")
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModel.from_pretrained(model_name)
    model.eval()  # Важно: режим инференса
    
    # Создаем пример входных данных
    # Для текстовых эмбеддеров обычно [batch_size, sequence_length]
    batch_size = 1
    seq_length = 512  # Максимальная длина последовательности
    
    # Создаем dummy input
    dummy_input = torch.randint(0, 1000, (batch_size, seq_length), dtype=torch.long)
    
    # Для некоторых моделей нужен attention_mask
    attention_mask = torch.ones((batch_size, seq_length), dtype=torch.long)
    
    print("Converting to ONNX...")
    
    # Экспорт в ONNX
    torch.onnx.export(
        model,
        (dummy_input, attention_mask),  # Входные данные
        onnx_path,
        export_params=True,
        opset_version=14,
        do_constant_folding=True,
        input_names=['input_ids', 'attention_mask'],
        output_names=['last_hidden_state'],
        dynamic_axes={
            'input_ids': {0: 'batch_size', 1: 'sequence_length'},
            'attention_mask': {0: 'batch_size', 1: 'sequence_length'},
            'last_hidden_state': {0: 'batch_size', 1: 'sequence_length'}
        },
        verbose=True
    )
    print(f"Model successfully converted to {onnx_path}")

if __name__ == "__main__":
    convert_embedder_to_onnx()
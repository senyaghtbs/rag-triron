import onnx

model = onnx.load("model-repository/embedder/1/model.onnx")
onnx.checker.check_model(model)
print("✅ ONNX model is valid!")
print(f"Inputs: {[input.name for input in model.graph.input]}")
print(f"Outputs: {[output.name for output in model.graph.output]}")

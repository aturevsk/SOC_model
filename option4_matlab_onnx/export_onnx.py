"""
Export PyTorch SOC model to ONNX format for MATLAB import (Option 4).

Usage:
    python export_onnx.py

This script:
  1. Loads the .pt2 ExportedProgram
  2. Reconstructs the nn.Module
  3. Exports to ONNX (opset 17)
  4. Validates the ONNX model
"""

import torch
import torch.nn as nn
import numpy as np
import os

class SOCModel(nn.Module):
    """SOC estimation model: 2-layer LSTM + dense head."""

    def __init__(self):
        super().__init__()
        self.lstm = nn.LSTM(
            input_size=5,
            hidden_size=64,
            num_layers=2,
            batch_first=True
        )
        self.head = nn.Sequential(
            nn.Linear(64, 64),
            nn.ReLU(),
            nn.Linear(64, 1)
        )

    def forward(self, x):
        # x: (batch, seq_len, features) = (1, 10, 5)
        output, (h_n, c_n) = self.lstm(x)
        last_hidden = h_n[-1]  # (batch, hidden_size)
        return self.head(last_hidden)


def main():
    pt2_path = os.path.join('..', 'soc_model.pt2')
    onnx_path = os.path.join('..', 'soc_model.onnx')

    # Load exported program
    print("Loading .pt2 model...")
    ep = torch.export.load(pt2_path)

    # Reconstruct model
    model = SOCModel()
    model.load_state_dict(ep.state_dict)
    model.eval()

    # Test input
    x = torch.randn(1, 10, 5)

    # Validate reconstruction
    with torch.no_grad():
        ref_out = ep.module()(x)
        our_out = model(x)
        diff = (ref_out - our_out).abs().max().item()
        print(f"Reconstruction error: {diff:.2e}")
        assert diff < 1e-5, f"Reconstruction mismatch: {diff}"

    # Export to ONNX
    print("Exporting to ONNX...")
    torch.onnx.export(
        model,
        x,
        onnx_path,
        input_names=["input"],
        output_names=["output"],
        opset_version=17,
        do_constant_folding=True,
    )
    print(f"ONNX model saved to: {onnx_path}")

    # Validate with onnxruntime if available
    try:
        import onnxruntime as ort
        sess = ort.InferenceSession(onnx_path)
        ort_out = sess.run(None, {"input": x.numpy()})[0]
        ort_diff = np.abs(ref_out.numpy() - ort_out).max()
        print(f"ONNX runtime validation error: {ort_diff:.2e}")
    except ImportError:
        print("onnxruntime not installed, skipping validation.")

    print("Done.")


if __name__ == "__main__":
    main()

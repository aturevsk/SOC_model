"""
Generate 100 random test vectors and compute PyTorch reference outputs.
Exports to C header format for numerical equivalence validation.
"""

import torch
import numpy as np

# Load model
ep = torch.export.load('../soc_model.pt2')
model = ep.module()

N_TESTS = 100
np.random.seed(42)

# Generate random inputs
inputs = np.random.randn(N_TESTS, 10, 5).astype(np.float32)

# Compute reference outputs
outputs = np.zeros(N_TESTS, dtype=np.float32)
with torch.no_grad():
    for i in range(N_TESTS):
        x = torch.from_numpy(inputs[i:i+1])
        y = model(x)
        outputs[i] = y.item()

# Save as npz
np.savez('test_vectors_100.npz', inputs=inputs, outputs=outputs)

# Generate C header
with open('test_vectors_100.h', 'w') as f:
    f.write('/* Auto-generated: 100 test vectors for numerical equivalence */\n')
    f.write('#ifndef TEST_VECTORS_100_H\n')
    f.write('#define TEST_VECTORS_100_H\n\n')
    f.write(f'#define N_TEST_VECTORS {N_TESTS}\n\n')

    f.write(f'static const float test_inputs[{N_TESTS}][10][5] = {{\n')
    for i in range(N_TESTS):
        f.write('  {\n')
        for t in range(10):
            vals = ', '.join(f'{v:.8e}' for v in inputs[i, t, :])
            f.write(f'    {{{vals}}},\n')
        f.write('  },\n')
    f.write('};\n\n')

    f.write(f'static const float test_expected[{N_TESTS}] = {{\n')
    for i in range(0, N_TESTS, 5):
        chunk = outputs[i:i+5]
        vals = ', '.join(f'{v:.8e}' for v in chunk)
        f.write(f'    {vals},\n')
    f.write('};\n\n')

    f.write('#endif /* TEST_VECTORS_100_H */\n')

print(f"Generated {N_TESTS} test vectors")
print(f"Output range: [{outputs.min():.6f}, {outputs.max():.6f}]")
print(f"Output mean: {outputs.mean():.6f}, std: {outputs.std():.6f}")

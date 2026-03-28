#!/usr/bin/env python3
"""
Generate single-page web app for SOC Model C Code Generation project.
Reads all source files and embeds them into a self-contained HTML file.
"""

import os
import html
import json

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Files to include in the Code Explorer
CODE_FILES = [
    # Option 1
    ("Option 1: Manual C", "option1_c/soc_model.h", "c"),
    ("Option 1: Manual C", "option1_c/soc_model.c", "c"),
    ("Option 1: Manual C", "option1_c/main_test.c", "c"),
    ("Option 1: Manual C", "option1_c/test_equivalence.c", "c"),
    ("Option 1: Manual C", "option1_c/Makefile", "makefile"),
    # Option 2
    ("Option 2: PyTorch Coder", "option2_matlab_pytorch_coder/generate_code_pytorch_coder.m", "matlab"),
    ("Option 2: PyTorch Coder", "option2_matlab_pytorch_coder/predict_soc.m", "matlab"),
    ("Option 2: PyTorch Coder", "option2_matlab_pytorch_coder/outputDir/predict_soc.h", "c"),
    ("Option 2: PyTorch Coder", "option2_matlab_pytorch_coder/outputDir/predict_soc.c", "c"),
    # Option 3
    ("Option 3: Import PyTorch", "option3_matlab_import_pytorch/generate_code_import_pytorch.m", "matlab"),
    ("Option 3: Import PyTorch", "option3_matlab_import_pytorch/predict_soc_dlnet.m", "matlab"),
    # Option 4
    ("Option 4: ONNX", "option4_matlab_onnx/generate_code_onnx.m", "matlab"),
    ("Option 4: ONNX", "option4_matlab_onnx/predict_soc_onnx.m", "matlab"),
    ("Option 4: ONNX", "option4_matlab_onnx/export_onnx.py", "python"),
    ("Option 4: ONNX", "option4_matlab_onnx/outputDir/callPredict.c", "c"),
    # Option 5
    ("Option 5: Native dlnetwork", "option5_matlab_manual_dlnetwork/generate_code_manual_dlnetwork.m", "matlab"),
    ("Option 5: Native dlnetwork", "option5_matlab_manual_dlnetwork/predict_soc_native.m", "matlab"),
    ("Option 5: Native dlnetwork", "option5_matlab_manual_dlnetwork/outputDir/callPredict.c", "c"),
    # Benchmarks
    ("Benchmarks", "benchmarks/bench_all_host.c", "c"),
    ("Benchmarks", "test_equivalence_matlab.m", "matlab"),
    # Compression — Option 4
    ("Opt 4: Compression", "option4_compressed/step1_compress.m", "matlab"),
    ("Opt 4: Compression", "option4_compressed/TestPipeline_opt4.m", "matlab"),
    # Compression — Option 5
    ("Opt 5: Compression", "option5_compressed/step1_compress.m", "matlab"),
    ("Opt 5: Compression", "option5_compressed/step2_simulink_sim.m", "matlab"),
    ("Opt 5: Compression", "option5_compressed/step3_codegen_compare.m", "matlab"),
    ("Opt 5: Compression", "option5_compressed/TestPipeline_opt5.m", "matlab"),
]


def read_file(rel_path):
    full = os.path.join(BASE, rel_path)
    try:
        with open(full, "r", errors="replace") as f:
            content = f.read()
        lines = content.count("\n") + (1 if content and not content.endswith("\n") else 0)
        return content, lines
    except FileNotFoundError:
        return f"// File not found: {rel_path}", 1


def build_file_data():
    """Read all files and build JSON-safe data structure."""
    files = []
    for group, rel_path, lang in CODE_FILES:
        content, lines = read_file(rel_path)
        basename = os.path.basename(rel_path)
        files.append({
            "group": group,
            "path": rel_path,
            "name": basename,
            "lang": lang,
            "lines": lines,
            "content": content,
        })
    return files


def generate_html(file_data):
    # Build the file tree sidebar HTML
    groups = {}
    for i, f in enumerate(file_data):
        g = f["group"]
        if g not in groups:
            groups[g] = []
        groups[g].append((i, f))

    file_tree_html = ""
    for gname, items in groups.items():
        file_tree_html += f'<div class="tree-group">{html.escape(gname)}</div>\n'
        for idx, f in items:
            badge = f' <span class="line-badge">{f["lines"]:,} lines</span>' if f["lines"] > 500 else ""
            file_tree_html += (
                f'<div class="tree-file" onclick="showFile({idx})" id="tf-{idx}">'
                f'{html.escape(f["name"])}{badge}</div>\n'
            )

    # JSON encode file data for embedding
    # We only need content, name, lang, lines, path for the JS side
    js_files = []
    for f in file_data:
        js_files.append({
            "name": f["name"],
            "path": f["path"],
            "lang": f["lang"],
            "lines": f["lines"],
        })
    js_files_json = json.dumps(js_files)

    # Build hidden pre blocks for each file's content
    hidden_content_blocks = ""
    for i, f in enumerate(file_data):
        escaped = html.escape(f["content"])
        hidden_content_blocks += f'<pre id="file-content-{i}" style="display:none">{escaped}</pre>\n'

    return f'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SOC Model &mdash; C Code Generation Explorer</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-dark.min.css">
<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/languages/c.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/languages/matlab.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/languages/python.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/languages/makefile.min.js"></script>
<style>
:root {{
  --bg: #0f1117; --surface: #1a1d27; --surface2: #222535; --border: #2e3250;
  --accent: #4f8ef7; --green: #22c55e; --yellow: #f59e0b; --red: #ef4444;
  --purple: #a855f7; --text: #e2e8f0; --muted: #7c8db5;
  --opt1: #22c55e; --opt2: #4f8ef7; --opt3: #ef4444; --opt4: #f59e0b; --opt5: #a855f7;
}}
* {{ box-sizing: border-box; margin: 0; padding: 0; }}
body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: var(--bg); color: var(--text); min-height: 100vh; }}
#app {{ display: flex; flex-direction: column; min-height: 100vh; }}
.topbar {{ display: flex; align-items: center; gap: 16px; padding: 0 24px; height: 56px; background: var(--surface); border-bottom: 1px solid var(--border); position: sticky; top: 0; z-index: 100; }}
.topbar-logo {{ font-weight: 800; font-size: 1rem; color: var(--accent); letter-spacing: -0.3px; }}
.topbar-sub {{ color: var(--muted); font-size: 0.8rem; }}
.topbar-nav {{ display: flex; gap: 4px; margin-left: auto; flex-wrap: wrap; }}
.nav-btn {{ padding: 6px 14px; border-radius: 6px; border: none; background: transparent; color: var(--muted); font-size: 0.85rem; cursor: pointer; font-weight: 500; transition: all .15s; }}
.nav-btn:hover {{ background: var(--surface2); color: var(--text); }}
.nav-btn.active {{ background: var(--accent); color: #fff; }}
.content {{ flex: 1; padding: 24px; max-width: 1200px; margin: 0 auto; width: 100%; }}
.page {{ display: none; }} .page.active {{ display: block; }}
h2 {{ font-size: 1.4rem; margin-bottom: 16px; font-weight: 700; }}
h3 {{ font-size: 1.1rem; margin: 20px 0 10px; font-weight: 600; color: var(--accent); }}
p, li {{ line-height: 1.6; color: var(--muted); margin-bottom: 8px; }}
.card {{ background: var(--surface); border: 1px solid var(--border); border-radius: 12px; padding: 20px; margin-bottom: 16px; }}
.card-title {{ font-weight: 700; font-size: 1rem; margin-bottom: 12px; }}
.grid2 {{ display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }}
.grid4 {{ display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; }}
.grid5 {{ display: grid; grid-template-columns: repeat(5, 1fr); gap: 12px; }}
@media (max-width: 900px) {{ .grid2, .grid4, .grid5 {{ grid-template-columns: 1fr; }} }}
.stat-card {{ background: var(--surface); border: 1px solid var(--border); border-radius: 10px; padding: 16px; text-align: center; }}
.stat-val {{ font-size: 1.8rem; font-weight: 800; }}
.stat-label {{ font-size: 0.75rem; color: var(--muted); margin-top: 4px; }}
.badge {{ display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 0.75rem; font-weight: 600; }}
.badge-pass {{ background: #22c55e22; color: var(--green); }}
.badge-fail {{ background: #ef444422; color: var(--red); }}
table {{ width: 100%; border-collapse: collapse; font-size: 0.85rem; }}
th {{ background: var(--surface2); padding: 10px 12px; text-align: left; font-weight: 600; border-bottom: 2px solid var(--border); }}
td {{ padding: 8px 12px; border-bottom: 1px solid var(--border); }}
tr:hover {{ background: var(--surface2); }}
.chart-box {{ background: var(--surface); border: 1px solid var(--border); border-radius: 12px; padding: 20px; margin-bottom: 16px; }}
.opt-dot {{ display: inline-block; width: 10px; height: 10px; border-radius: 50%; margin-right: 6px; }}
.highlight-best {{ color: var(--green); font-weight: 700; }}
pre {{ border-radius: 8px; overflow-x: auto; }}
code {{ font-size: 0.82rem; }}
.issue-list {{ list-style: none; padding: 0; }}
.issue-list li {{ padding: 8px 12px; border-left: 3px solid var(--yellow); margin-bottom: 6px; background: var(--surface2); border-radius: 0 6px 6px 0; }}
.issue-list li.resolved {{ border-left-color: var(--green); }}
.issue-list li.unresolved {{ border-left-color: var(--red); }}
.footer {{ padding: 16px 24px; text-align: center; color: var(--muted); font-size: 0.75rem; border-top: 1px solid var(--border); }}

/* Code Explorer specific */
.code-explorer {{ display: flex; gap: 16px; height: calc(100vh - 140px); }}
.file-tree {{ width: 260px; min-width: 200px; background: var(--surface); border: 1px solid var(--border); border-radius: 12px; padding: 12px; overflow-y: auto; flex-shrink: 0; }}
.tree-group {{ font-size: 0.75rem; font-weight: 700; color: var(--accent); padding: 8px 6px 4px; text-transform: uppercase; letter-spacing: 0.5px; }}
.tree-file {{ padding: 5px 10px; border-radius: 6px; cursor: pointer; font-size: 0.82rem; color: var(--muted); transition: all .15s; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }}
.tree-file:hover {{ background: var(--surface2); color: var(--text); }}
.tree-file.active {{ background: var(--accent); color: #fff; }}
.line-badge {{ display: inline-block; padding: 1px 5px; border-radius: 3px; font-size: 0.65rem; font-weight: 600; background: var(--surface2); color: var(--yellow); margin-left: 4px; }}
.code-viewer {{ flex: 1; background: var(--surface); border: 1px solid var(--border); border-radius: 12px; overflow: hidden; display: flex; flex-direction: column; }}
.code-header {{ padding: 10px 16px; background: var(--surface2); border-bottom: 1px solid var(--border); font-size: 0.85rem; font-weight: 600; display: flex; justify-content: space-between; align-items: center; }}
.code-body {{ flex: 1; overflow: auto; padding: 0; }}
.code-body pre {{ margin: 0; border-radius: 0; }}
.code-body code {{ font-size: 0.78rem; line-height: 1.5; }}
@media (max-width: 900px) {{ .code-explorer {{ flex-direction: column; height: auto; }} .file-tree {{ width: 100%; max-height: 200px; }} }}
</style>
</head>
<body>
<div id="app">
<div class="topbar">
  <span class="topbar-logo">SOC Model</span>
  <span class="topbar-sub">C Code Generation Explorer</span>
  <div class="topbar-nav">
    <button class="nav-btn active" onclick="show('overview')">Overview</button>
    <button class="nav-btn" onclick="show('accuracy')">Accuracy</button>
    <button class="nav-btn" onclick="show('performance')">Performance</button>
    <button class="nav-btn" onclick="show('options')">Options Detail</button>
    <button class="nav-btn" onclick="show('issues')">Issues &amp; Fixes</button>
    <button class="nav-btn" onclick="show('compression')">Compression</button>
    <button class="nav-btn" onclick="show('code')">Code Explorer</button>
  </div>
</div>
<div class="content">

<!-- OVERVIEW -->
<div id="overview" class="page active">
<h2>Project Overview</h2>
<p>Comparison of 5 approaches for generating embedded C code from a PyTorch LSTM-based State of Charge (SOC) estimation model, targeting the <b>STM32F746G-Discovery</b> (ARM Cortex-M7 @ 216 MHz).</p>

<div class="grid4" style="margin: 20px 0">
  <div class="stat-card"><div class="stat-val" style="color:var(--green)">4/5</div><div class="stat-label">Options Passed</div></div>
  <div class="stat-card"><div class="stat-val" style="color:var(--accent)">100</div><div class="stat-label">Test Vectors</div></div>
  <div class="stat-card"><div class="stat-val" style="color:var(--purple)">48.7 &mu;s</div><div class="stat-label">Best Latency (host)</div></div>
  <div class="stat-card"><div class="stat-val" style="color:var(--yellow)">55,681</div><div class="stat-label">Model Parameters</div></div>
</div>

<div class="card">
<div class="card-title">Model Architecture</div>
<table>
<tr><th>Component</th><th>Type</th><th>Parameters</th></tr>
<tr><td>LSTM Layer 0</td><td>input=5, hidden=64</td><td>17,664</td></tr>
<tr><td>LSTM Layer 1</td><td>input=64, hidden=64</td><td>33,024</td></tr>
<tr><td>Head: Linear 0</td><td>64 &rarr; 64 + ReLU</td><td>4,160</td></tr>
<tr><td>Head: Linear 2</td><td>64 &rarr; 1</td><td>65</td></tr>
<tr><th>Total</th><th>Input: [1, 10, 5] &rarr; Output: [1, 1]</th><th>55,681 (217.5 KB)</th></tr>
</table>
</div>

<div class="card">
<div class="card-title">Options Summary</div>
<table>
<tr><th>Option</th><th>Method</th><th>Status</th><th>Lines of C</th><th>Mean Latency</th><th>Throughput</th></tr>
<tr><td><span class="opt-dot" style="background:var(--opt1)"></span>1</td><td>Hand-crafted C</td><td><span class="badge badge-pass">PASS</span></td><td>222</td><td>84.8 &mu;s</td><td>11,827/s</td></tr>
<tr><td><span class="opt-dot" style="background:var(--opt2)"></span>2</td><td>MATLAB Coder PyTorch SP</td><td><span class="badge badge-pass">PASS</span></td><td>12,322</td><td class="highlight-best">48.7 &mu;s</td><td class="highlight-best">20,520/s</td></tr>
<tr><td><span class="opt-dot" style="background:var(--opt3)"></span>3</td><td>importNetworkFromPyTorch</td><td><span class="badge badge-fail">FAIL</span></td><td>&mdash;</td><td>&mdash;</td><td>&mdash;</td></tr>
<tr><td><span class="opt-dot" style="background:var(--opt4)"></span>4</td><td>ONNX Import + Codegen</td><td><span class="badge badge-pass">PASS</span></td><td>11,708</td><td>52.5 &mu;s</td><td>19,055/s</td></tr>
<tr><td><span class="opt-dot" style="background:var(--opt5)"></span>5</td><td>Native dlnetwork + Embedded Coder</td><td><span class="badge badge-pass">PASS</span></td><td>11,563</td><td>51.5 &mu;s</td><td>19,422/s</td></tr>
</table>
</div>
</div>

<!-- ACCURACY -->
<div id="accuracy" class="page">
<h2>Numerical Accuracy (100 Test Vectors)</h2>
<p>100 random input sequences tested against PyTorch reference. All 4 working options achieve perfect equivalence within float32 precision.</p>

<div class="grid2">
<div class="chart-box"><canvas id="chartAccMax"></canvas></div>
<div class="chart-box"><canvas id="chartAccMean"></canvas></div>
</div>

<div class="card">
<div class="card-title">Equivalence Test Results (vs PyTorch Reference)</div>
<table>
<tr><th>Option</th><th>Pass Rate</th><th>Max Abs Error</th><th>Mean Abs Error</th><th>Status</th></tr>
<tr><td><span class="opt-dot" style="background:var(--opt1)"></span>1 &mdash; Manual C</td><td>100/100</td><td>1.49e-8</td><td>4.97e-9</td><td><span class="badge badge-pass">PASS</span></td></tr>
<tr><td><span class="opt-dot" style="background:var(--opt2)"></span>2 &mdash; PT Coder</td><td>100/100</td><td>1.30e-8</td><td>4.41e-9</td><td><span class="badge badge-pass">PASS</span></td></tr>
<tr><td><span class="opt-dot" style="background:var(--opt4)"></span>4 &mdash; ONNX</td><td>100/100</td><td>1.12e-8</td><td>3.43e-9</td><td><span class="badge badge-pass">PASS</span></td></tr>
<tr><td><span class="opt-dot" style="background:var(--opt5)"></span>5 &mdash; Native DL</td><td>100/100</td><td>1.49e-8</td><td>5.0e-9</td><td><span class="badge badge-pass">PASS</span></td></tr>
</table>
<p style="margin-top:10px">All errors are within float32 precision (~1.5e-8 max). The differences arise from floating-point accumulation order in matrix-vector multiplies, not a correctness issue.</p>
</div>
</div>

<!-- PERFORMANCE -->
<div id="performance" class="page">
<h2>Performance Benchmarks</h2>
<p>Host benchmarks: 100K iterations, <code>gcc -O2</code>, Apple Silicon. Option 3 excluded (codegen failed).</p>

<div class="grid2">
<div class="chart-box"><canvas id="chartSpeed"></canvas></div>
<div class="chart-box"><canvas id="chartBinary"></canvas></div>
</div>

<div class="card">
<div class="card-title">Detailed Timing Results (100K iterations, gcc -O2)</div>
<table>
<tr><th>Option</th><th>Mean (&mu;s)</th><th>Median (&mu;s)</th><th>Min (&mu;s)</th><th>P95 (&mu;s)</th><th>Throughput (inf/s)</th></tr>
<tr><td><span class="opt-dot" style="background:var(--opt1)"></span>1 &mdash; Manual C</td><td>84.8</td><td>81</td><td>80</td><td>97</td><td>11,827</td></tr>
<tr><td><span class="opt-dot" style="background:var(--opt2)"></span>2 &mdash; PT Coder</td><td class="highlight-best">48.7</td><td class="highlight-best">49</td><td class="highlight-best">43</td><td class="highlight-best">56</td><td class="highlight-best">20,520</td></tr>
<tr><td><span class="opt-dot" style="background:var(--opt4)"></span>4 &mdash; ONNX</td><td>52.5</td><td>53</td><td>47</td><td>60</td><td>19,055</td></tr>
<tr><td><span class="opt-dot" style="background:var(--opt5)"></span>5 &mdash; Native DL</td><td>51.5</td><td>52</td><td>46</td><td>59</td><td>19,422</td></tr>
</table>
<p style="margin-top:10px">Option 2 (MATLAB Coder PyTorch SP) is fastest, 1.74x faster than Option 1 (Manual C). The MATLAB-generated options use optimized loop structures that the compiler can vectorize more effectively.</p>
</div>

<div class="card">
<div class="card-title">Binary Size Comparison (host, gcc -O2)</div>
<table>
<tr><th>Option</th><th>Binary Size</th><th>vs Option 1</th><th>Lines of C</th></tr>
<tr><td><span class="opt-dot" style="background:var(--opt1)"></span>1 &mdash; Manual C</td><td class="highlight-best">249,048 bytes (243.2 KB)</td><td>1.00x</td><td>222</td></tr>
<tr><td><span class="opt-dot" style="background:var(--opt2)"></span>2 &mdash; PT Coder</td><td>266,472 bytes (260.2 KB)</td><td>1.07x</td><td>12,322</td></tr>
<tr><td><span class="opt-dot" style="background:var(--opt4)"></span>4 &mdash; ONNX</td><td>266,376 bytes (260.1 KB)</td><td>1.07x</td><td>11,708</td></tr>
<tr><td><span class="opt-dot" style="background:var(--opt5)"></span>5 &mdash; Native DL</td><td>267,000 bytes (260.7 KB)</td><td>1.07x</td><td>11,563</td></tr>
</table>
<p style="margin-top:10px">Binary sizes are within 7% because the 217.5 KB of float32 model weights dominates. The actual code logic difference is only ~17 KB.</p>
</div>
</div>

<!-- OPTIONS DETAIL -->
<div id="options" class="page">
<h2>Options Detail</h2>

<div class="card" style="border-left: 3px solid var(--opt1)">
<div class="card-title"><span class="opt-dot" style="background:var(--opt1)"></span>Option 1: Hand-Crafted C <span class="badge badge-pass">PASS</span></div>
<p><b>Approach:</b> Extract weights from PyTorch via Python &rarr; generate C header with static const arrays &rarr; implement LSTM cell, ReLU, Linear layers manually in C99.</p>
<h3>Steps</h3>
<ol style="color:var(--muted)">
<li>Export .pt2 ExportedProgram weights to C header via Python script</li>
<li>Implement matrix-vector multiply, fast sigmoid/tanh, LSTM cell</li>
<li>Layer 0 (input=5, hidden=64) &rarr; Layer 1 (input=64, hidden=64) &rarr; FC head</li>
<li>Compile with gcc -O2, validate against PyTorch reference</li>
</ol>
<p><b>Result:</b> 222 lines of C, 84.8 &mu;s mean latency, 249 KB binary. Zero dependencies, fully readable code.</p>
<p><b>Issues:</b> Slightly slower than MATLAB-generated code (compiler cannot vectorize the naive loop structure as effectively). Optional CMSIS-DSP acceleration path included for ARM targets.</p>
</div>

<div class="card" style="border-left: 3px solid var(--opt2)">
<div class="card-title"><span class="opt-dot" style="background:var(--opt2)"></span>Option 2: MATLAB Coder PyTorch Support Package <span class="badge badge-pass">PASS</span></div>
<p><b>Approach:</b> Load .pt2 ExportedProgram via <code>loadPyTorchExportedProgram</code> &rarr; use <code>net.invoke()</code> API &rarr; generate C with MATLAB Coder + Embedded Coder.</p>
<h3>Steps</h3>
<ol style="color:var(--muted)">
<li>Install MATLAB Coder Support Package for PyTorch and LiteRT Models</li>
<li>Load model: <code>model = loadPyTorchExportedProgram('soc_model.pt2')</code></li>
<li>Create entry-point: <code>soc = net.invoke(input)</code> (NOT predict())</li>
<li>Configure: <code>DeepLearningConfig('none')</code> for pure C output</li>
<li>Run codegen &rarr; 12,322 lines of optimized C</li>
</ol>
<p><b>Result:</b> Fastest option at 48.7 &mu;s, 20,520 inferences/sec. Single monolithic predict_soc.c file.</p>
<p><b>Key insight:</b> Must use <code>invoke()</code> not <code>predict()</code> for ExportedProgram objects.</p>
</div>

<div class="card" style="border-left: 3px solid var(--opt3)">
<div class="card-title"><span class="opt-dot" style="background:var(--opt3)"></span>Option 3: importNetworkFromPyTorch <span class="badge badge-fail">FAIL</span></div>
<p><b>Approach:</b> Import .pt2 as dlnetwork via <code>importNetworkFromPyTorch</code> &rarr; <code>expandLayers</code> &rarr; codegen.</p>
<h3>Steps</h3>
<ol style="color:var(--muted)">
<li>Import: <code>net = importNetworkFromPyTorch('soc_model.pt2')</code></li>
<li>Expand: <code>net = expandLayers(net)</code></li>
<li>Save network, create entry-point with <code>coder.loadDeepLearningNetwork</code></li>
<li>Configure Embedded Coder with <code>DeepLearningConfig('none')</code></li>
<li>Run codegen &rarr; <b>FAILS</b></li>
</ol>
<p><b>Failure reason:</b> The PyTorch importer creates a custom layer <code>SOC_LSTM_select_2</code> for the <code>h_n[-1]</code> tensor selection operation. This custom layer has no <code>matlabCodegenRedirect</code> method and cannot generate C code.</p>
<p><b>Workaround:</b> Use Option 5 (manually build native dlnetwork with <code>OutputMode='last'</code> on the LSTM layer) or Option 4 (ONNX import, where auto-generated custom layers DO support codegen in R2026a).</p>
</div>

<div class="card" style="border-left: 3px solid var(--opt4)">
<div class="card-title"><span class="opt-dot" style="background:var(--opt4)"></span>Option 4: ONNX Import + Codegen <span class="badge badge-pass">PASS</span></div>
<p><b>Approach:</b> Export PyTorch model to ONNX (legacy exporter, opset 14) &rarr; <code>importNetworkFromONNX</code> &rarr; codegen with Embedded Coder.</p>
<h3>Steps</h3>
<ol style="color:var(--muted)">
<li>Reconstruct nn.Module from ExportedProgram state_dict</li>
<li>Export ONNX: <code>torch.onnx.export(model, x, path, opset_version=14)</code> (must use legacy exporter)</li>
<li>Import: <code>net = importNetworkFromONNX('soc_model_legacy.onnx')</code></li>
<li>Configure: <code>DeepLearningConfig('none')</code> &mdash; critical for Embedded Coder</li>
<li>Run codegen &rarr; 11,708 lines of C</li>
</ol>
<p><b>Result:</b> 52.5 &mu;s, 19,055 inferences/sec. R2026a auto-generated ONNX custom layers support codegen natively.</p>
<p><b>Key insight:</b> Must use legacy TorchScript ONNX exporter. New dynamo exporter creates external .data files (unsupported by MATLAB) and decomposes LSTM into primitive ops.</p>
</div>

<div class="card" style="border-left: 3px solid var(--opt5)">
<div class="card-title"><span class="opt-dot" style="background:var(--opt5)"></span>Option 5: Native dlnetwork + Embedded Coder <span class="badge badge-pass">PASS</span></div>
<p><b>Approach:</b> Import model to extract weights &rarr; manually build codegen-compatible dlnetwork with native MATLAB layers &rarr; transfer weights &rarr; codegen.</p>
<h3>Steps</h3>
<ol style="color:var(--muted)">
<li>Import PyTorch model: <code>importedNet = importNetworkFromPyTorch('soc_model.pt2')</code></li>
<li>Build fresh dlnetwork: <code>sequenceInputLayer &rarr; lstmLayer(OutputMode='sequence') &rarr; lstmLayer(OutputMode='last') &rarr; FC &rarr; ReLU &rarr; FC</code></li>
<li>Transfer all learnable parameters from imported network</li>
<li>Validate equivalence (100 samples, max error &lt; 1e-5)</li>
<li>Configure Embedded Coder, run codegen &rarr; 11,563 lines of C</li>
</ol>
<p><b>Result:</b> 51.5 &mu;s, 19,422 inferences/sec. Best approach for Model-Based Design workflows.</p>
<p><b>Key insight:</b> Uses <code>OutputMode='last'</code> on LSTM layer 2 to avoid the custom <code>SOC_LSTM_select_2</code> layer that blocks Option 3.</p>
</div>
</div>

<!-- ISSUES & FIXES -->
<div id="issues" class="page">
<h2>Issues Encountered &amp; Fixes</h2>

<h3><span class="opt-dot" style="background:var(--opt2)"></span>Option 2: PyTorch Coder Support Package</h3>
<ul class="issue-list">
<li class="resolved"><b>predict() vs invoke()</b> &mdash; ExportedProgram objects use <code>net.invoke()</code>, not <code>predict()</code>. Using predict() causes codegen failure with confusing error messages.<br><b>Fix:</b> Use <code>model.invoke(input)</code> as the entry-point function body.</li>
</ul>

<h3><span class="opt-dot" style="background:var(--opt3)"></span>Option 3: importNetworkFromPyTorch</h3>
<ul class="issue-list">
<li class="unresolved"><b>Custom layer SOC_LSTM_select_2 blocks codegen</b> &mdash; importNetworkFromPyTorch creates a custom layer for the PyTorch <code>h_n[-1]</code> selection operation. This layer lacks a <code>matlabCodegenRedirect</code> method, preventing C code generation. Unlike ONNX-imported custom layers, PyTorch-imported custom layers do not support codegen in R2026a.<br><b>Workaround:</b> Use Option 5 (manually build native dlnetwork) or Option 4 (ONNX import).</li>
</ul>

<h3><span class="opt-dot" style="background:var(--opt4)"></span>Option 4: ONNX Import</h3>
<ul class="issue-list">
<li class="resolved"><b>Missing DeepLearningConfig('none')</b> &mdash; Without explicitly setting <code>cfg.DeepLearningConfig = coder.DeepLearningConfig('none')</code>, Embedded Coder fails for both Options 4 and 5. This was a lesson learned from the earlier LSTMforecaster project.<br><b>Fix:</b> Always set <code>DeepLearningConfig('none')</code> for pure C codegen.</li>
<li class="resolved"><b>ONNX external data files</b> &mdash; The new torch ONNX exporter (dynamo-based) creates a separate <code>.data</code> file for model weights. MATLAB's <code>importNetworkFromONNX</code> does not support loading models with external data.<br><b>Fix:</b> Use the legacy TorchScript ONNX exporter with <code>torch.onnx.export()</code> (not the dynamo exporter).</li>
<li class="resolved"><b>ONNX decomposed ops</b> &mdash; The new dynamo exporter decomposes LSTM into primitive operations (matmul, sigmoid, tanh, etc.), producing a monolithic custom layer instead of a native LSTM layer in MATLAB.<br><b>Fix:</b> Use legacy exporter with <code>opset_version=14</code> to preserve LSTM as a single ONNX op.</li>
</ul>

<h3><span class="opt-dot" style="background:var(--opt5)"></span>Option 5: Native dlnetwork</h3>
<ul class="issue-list">
<li class="resolved"><b>Missing DeepLearningConfig('none')</b> &mdash; Same issue as Option 4. Embedded Coder requires explicit deep learning configuration.<br><b>Fix:</b> Set <code>cfg.DeepLearningConfig = coder.DeepLearningConfig('none')</code>.</li>
</ul>

<h3>Cross-Option Issues</h3>
<ul class="issue-list">
<li class="resolved"><b>macOS section attribute</b> &mdash; MATLAB-generated C code uses <code>__attribute__((section(".rodata")))</code> which fails on macOS (Mach-O uses different section syntax than ELF).<br><b>Fix:</b> Conditional <code>#define</code> to disable the attribute on macOS.</li>
<li class="resolved"><b>OpenMP dependency</b> &mdash; MATLAB-generated code includes <code>#include &lt;omp.h&gt;</code> even for single-threaded targets.<br><b>Fix:</b> Provide a minimal <code>omp.h</code> stub with empty macros.</li>
<li class="resolved"><b>EmbeddedCodeConfig property removal</b> &mdash; R2026a removed <code>EfficientFloat2IntCast</code> and <code>SaturateOnIntegerOverflow</code> from the Embedded Coder config object. Scripts using these properties fail with property-not-found errors.<br><b>Fix:</b> Remove or guard these property assignments with try/catch.</li>
</ul>
</div>

<!-- COMPRESSION -->
<div id="compression" class="page">
<h2>Model Compression &mdash; Options 4 &amp; 5</h2>
<p>Post-training compression pipeline targeting <b>MAE &lt; 1e-3</b> vs PyTorch on 100 test vectors, with maximum Flash savings for embedded deployment.</p>

<div class="grid2" style="margin: 16px 0">
  <div class="stat-card"><div class="stat-val" style="color:var(--green)">77.5%</div><div class="stat-label">Flash Savings (Opt 5 winner)</div></div>
  <div class="stat-card"><div class="stat-val" style="color:var(--accent)">48.4 KB</div><div class="stat-label">Compressed Size (from 215.5 KB)</div></div>
</div>

<div class="card" style="border-left: 3px solid var(--opt4)">
<div class="card-title"><span class="opt-dot" style="background:var(--opt4)"></span>Option 4 (ONNX) &mdash; Compression Results</div>
<p>ONNX-imported custom layers limit available compression techniques.</p>
<table>
<tr><th>Technique</th><th>Status</th><th>MAE</th><th>Size</th><th>Savings</th></tr>
<tr><td>neuronPCA projection</td><td><span class="badge badge-pass">WORKS</span></td><td>varies</td><td>varies</td><td>varies</td></tr>
<tr><td>dlquantizer (int8)</td><td><span class="badge badge-fail">FAILS</span></td><td colspan="3">Custom ONNX layers not supported by quantizer</td></tr>
<tr><td>taylorPrunableNetwork</td><td><span class="badge badge-fail">FAILS</span></td><td colspan="3">LSTM not supported in R2026a</td></tr>
<tr style="background:rgba(34,197,94,0.08)"><td><b>manual_int8 &larr; BEST</b></td><td><span class="badge badge-pass">PASS</span></td><td>3.55e-04</td><td>~53.9 KB</td><td>75.0%</td></tr>
<tr><td>Simulink export</td><td><span class="badge badge-fail">FAILS</span></td><td colspan="3">ONNX custom layers not exportable to Simulink</td></tr>
</table>
</div>

<div class="card" style="border-left: 3px solid var(--opt5)">
<div class="card-title"><span class="opt-dot" style="background:var(--opt5)"></span>Option 5 (Native dlnetwork) &mdash; Compression Results</div>
<p>Full compression toolchain available &mdash; no custom layers.</p>
<table>
<tr><th>Technique</th><th>Status</th><th>MAE</th><th>Size (KB)</th><th>Savings</th></tr>
<tr><td>Baseline float32</td><td>&mdash;</td><td>5.16e-09</td><td>215.5</td><td>0%</td></tr>
<tr><td>proj_cf01 (10% projection)</td><td><span class="badge badge-pass">PASS</span></td><td>3.93e-04</td><td>193.6</td><td>10.2%</td></tr>
<tr><td>proj_cf07 (70% projection)</td><td><span class="badge badge-fail">FAIL</span></td><td>1.70e-03</td><td>61.9</td><td>71.3%</td></tr>
<tr><td>proj_cf09 (90% projection)</td><td><span class="badge badge-fail">FAIL</span></td><td>1.64e-03</td><td>19.3</td><td>91.0%</td></tr>
<tr style="background:rgba(34,197,94,0.12)"><td><b>proj10_quant (10%+int8) &larr; WINNER</b></td><td><span class="badge badge-pass">PASS</span></td><td>9.50e-04</td><td><b>48.4</b></td><td><b>77.5%</b></td></tr>
<tr><td>quant_int8 (baseline+int8)</td><td><span class="badge badge-pass">PASS</span></td><td>9.31e-04</td><td>53.9</td><td>75.0%</td></tr>
<tr><td>manual_int8</td><td><span class="badge badge-pass">PASS</span></td><td>3.55e-04</td><td>53.9</td><td>75.0%</td></tr>
<tr><td>taylorPrunableNetwork</td><td><span class="badge badge-fail">FAILS</span></td><td colspan="3">LSTM not supported in R2026a</td></tr>
</table>
</div>

<div class="card">
<div class="card-title">Combined Pipeline: proj10_quant</div>
<p>The winning approach chains two compression stages:</p>
<ol style="color:var(--muted); padding-left:20px; margin-bottom:12px">
  <li><b>Stage 1 &mdash; neuronPCA projection (10%):</b> Pre-compute PCA on LSTM/FC activations with <code>neuronPCA(net, mbq)</code>, then compress with <code>compressNetworkUsingProjection(net, npca, LearnablesReductionGoal=0.10, UnpackProjectedLayers=true)</code>. Achieves 10.2% reduction without fine-tuning (MAE = 3.93e-04). No fine-tuning required.</li>
  <li><b>Stage 2 &mdash; dlquantizer int8:</b> Apply <code>dlquantizer(projNet, ExecutionEnvironment='MATLAB')</code> to the projected network. Critical: call <code>prepareNetwork(qObj)</code> before <code>calibrate()</code>. Reduces 193.6 KB &rarr; 48.4 KB int8.</li>
</ol>
<p><b>Final result:</b> 215.5 KB &rarr; 48.4 KB = <span style="color:var(--green);font-weight:700">77.5% Flash savings</span>, MAE = 9.50e-04 &#10003;</p>
</div>

<div class="card">
<div class="card-title">Simulink &amp; Codegen Verification (Option 5)</div>
<table>
<tr><th>Stage</th><th>Result</th><th>Metric</th></tr>
<tr><td>MATLAB predict (compressed vs PyTorch)</td><td><span class="badge badge-pass">PASS</span></td><td>MAE = 9.50e-04 &lt; 1e-03</td></tr>
<tr><td>Simulink simulation (100 &times; 10 steps)</td><td><span class="badge badge-pass">PASS</span></td><td>MAE = 2.09e-03 &lt; 5e-03</td></tr>
<tr><td>Codegen &mdash; direct float32</td><td>14 C files / 854 KB</td><td>12,463 lines</td></tr>
<tr><td>Codegen &mdash; Simulink fixed-point (proj10_quant)</td><td>3 C files / 262 KB</td><td>3,534 lines</td></tr>
<tr style="background:rgba(34,197,94,0.08)"><td><b>Code size reduction</b></td><td colspan="2"><b>69% smaller &mdash; 0.31&times; vs direct codegen</b></td></tr>
</table>
</div>

<h3>Key Technical Issues &amp; Fixes</h3>
<ul class="issue-list">
<li class="resolved"><b>neuronPCA minibatchqueue format</b> &mdash; Must use cell array of [T&times;F] sequences with <code>MiniBatchFormat='TCB'</code> and <code>MiniBatchFcn=@(X) cat(3,X&#123;:&#125;)</code>. Standard numeric datastores fail.<br><b>Fix:</b> <code>arrayDatastore(seqData, 'IterationDimension',1, 'OutputType','same')</code> where <code>seqData</code> is a cell array of [T&times;F] single matrices.</li>
<li class="resolved"><b>dlquantizer: fi() cannot handle LSTM table outputs</b> &mdash; Without <code>prepareNetwork(qObj)</code>, LSTM (h,c) states are packaged as MATLAB <code>table</code> objects during Fixed-Point simulation. The <code>fi()</code> function throws <code>fixed:fi:unsupportedType</code>.<br><b>Fix:</b> Always call <code>prepareNetwork(qObj)</code> before <code>calibrate(qObj, ds)</code>.</li>
<li class="resolved"><b>calibrate() rejects minibatchqueue</b> &mdash; Despite documentation hints, <code>calibrate</code> only accepts <code>ArrayDatastore</code> of [T&times;F] cell sequences. Numeric [N&times;T&times;F] arrays fail with "Input data size not compatible."<br><b>Fix:</b> <code>arrayDatastore(seqData, 'IterationDimension',1, 'OutputType','same')</code></li>
<li class="resolved"><b>macOS crash after quantize()</b> &mdash; MATLAB R2026a crashes in a background thread (<code>detectHomeSessionAndSetInfo</code>) immediately after <code>quantize()</code> returns.<br><b>Fix:</b> <code>save('model.mat', 'qNet', '-v7.3')</code> immediately after <code>quantize()</code>, before any other operations.</li>
<li class="resolved"><b>ARM Cortex-M codegen word size error</b> &mdash; Fixed-point int type checks fail: <i>"Code was generated for compiler with different sized ulong/long"</i> when targeting ARM Cortex-M (32-bit) from macOS ARM64 (64-bit).<br><b>Fix:</b> <code>set_param(model, 'PortableWordSizes', 'on')</code></li>
<li class="resolved"><b>Projection accuracy degrades above 10%</b> &mdash; Test vectors come from a narrow operating condition (all outputs &asymp; &minus;0.031 &plusmn; 0.002). Aggressive projection (70%, 90%) exceeds recovery capability of 100 real samples. Synthetic N(0,1) training data makes accuracy worse (distribution mismatch).<br><b>Finding:</b> Only 10% projection passes without fine-tuning. Combined with int8 quantization gives 77.5% savings.</li>
<li class="resolved"><b>trainnet [T&times;F] format</b> &mdash; For dlnetwork with SequenceInputLayer, <code>trainnet</code> expects cell arrays of [T&times;F] per sample (time-first, TCB convention), not [F&times;T] (features-first, traditional MATLAB).<br><b>Fix:</b> <code>seqData&#123;i&#125; = reshape(inputs(i,:,:), [T, F])</code> &mdash; do NOT transpose.</li>
</ul>
</div>

<!-- CODE EXPLORER -->
<div id="code" class="page">
<h2>Code Explorer</h2>
<p>Full source code for all files across all options. Select a file from the tree to view.</p>
<div class="code-explorer">
<div class="file-tree">
{file_tree_html}
</div>
<div class="code-viewer">
<div class="code-header">
  <span id="code-filename">Select a file to view</span>
  <span id="code-meta" style="color:var(--muted);font-size:0.75rem"></span>
</div>
<div class="code-body" id="code-body">
<pre><code class="language-c" id="code-display">// Select a file from the tree on the left</code></pre>
</div>
</div>
</div>
</div>

</div><!-- end content -->

<div class="footer">
  SOC Model &mdash; C Code Generation + Compression for STM32F746G-Discovery &bull; MATLAB R2026a &bull; 5 options compared &bull; Compression: 77.5% Flash savings &bull; March 2026
</div>
</div><!-- end app -->

<!-- Hidden file contents -->
<div id="file-contents-store" style="display:none">
{hidden_content_blocks}
</div>

<script>
// Navigation
function show(id) {{
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
  document.getElementById(id).classList.add('active');
  event.target.classList.add('active');
  // Initialize charts when switching to their pages
  if (id === 'accuracy' && !window._accChartsInit) initAccuracyCharts();
  if (id === 'performance' && !window._perfChartsInit) initPerformanceCharts();
}}

// File data metadata
const FILES = {js_files_json};

// Code Explorer
function showFile(idx) {{
  // Update active state
  document.querySelectorAll('.tree-file').forEach(f => f.classList.remove('active'));
  const tf = document.getElementById('tf-' + idx);
  if (tf) tf.classList.add('active');

  const f = FILES[idx];
  document.getElementById('code-filename').textContent = f.path;
  const linesBadge = f.lines > 500 ? ' (' + f.lines.toLocaleString() + ' lines)' : '';
  document.getElementById('code-meta').textContent = f.lang.toUpperCase() + linesBadge;

  // Get content from hidden pre block
  const contentEl = document.getElementById('file-content-' + idx);
  const content = contentEl ? contentEl.textContent : '// Content not available';

  const codeEl = document.getElementById('code-display');
  codeEl.className = 'language-' + f.lang;
  codeEl.textContent = content;
  hljs.highlightElement(codeEl);
}}

// Charts
const OPT_COLORS = ['#22c55e','#4f8ef7','#ef4444','#f59e0b','#a855f7'];

function initAccuracyCharts() {{
  window._accChartsInit = true;

  new Chart(document.getElementById('chartAccMax'), {{
    type: 'bar',
    data: {{
      labels: ['Opt 1: Manual C', 'Opt 2: PT Coder', 'Opt 4: ONNX', 'Opt 5: Native DL'],
      datasets: [{{
        label: 'Max Abs Error',
        data: [1.49e-8, 1.30e-8, 1.12e-8, 1.49e-8],
        backgroundColor: [OPT_COLORS[0], OPT_COLORS[1], OPT_COLORS[3], OPT_COLORS[4]],
      }}]
    }},
    options: {{
      responsive: true,
      plugins: {{ title: {{ display: true, text: 'Max Absolute Error (100 vectors)', color: '#e2e8f0' }},
                 legend: {{ labels: {{ color: '#7c8db5' }} }} }},
      scales: {{ y: {{ ticks: {{ color: '#7c8db5', callback: v => v.toExponential(1) }}, grid: {{ color: '#2e3250' }} }},
                x: {{ ticks: {{ color: '#7c8db5' }}, grid: {{ color: '#2e3250' }} }} }}
    }}
  }});

  new Chart(document.getElementById('chartAccMean'), {{
    type: 'bar',
    data: {{
      labels: ['Opt 1: Manual C', 'Opt 2: PT Coder', 'Opt 4: ONNX', 'Opt 5: Native DL'],
      datasets: [{{
        label: 'Mean Abs Error',
        data: [4.97e-9, 4.41e-9, 3.43e-9, 5.0e-9],
        backgroundColor: [OPT_COLORS[0]+'88', OPT_COLORS[1]+'88', OPT_COLORS[3]+'88', OPT_COLORS[4]+'88'],
      }}]
    }},
    options: {{
      responsive: true,
      plugins: {{ title: {{ display: true, text: 'Mean Absolute Error (100 vectors)', color: '#e2e8f0' }},
                 legend: {{ labels: {{ color: '#7c8db5' }} }} }},
      scales: {{ y: {{ ticks: {{ color: '#7c8db5', callback: v => v.toExponential(1) }}, grid: {{ color: '#2e3250' }} }},
                x: {{ ticks: {{ color: '#7c8db5' }}, grid: {{ color: '#2e3250' }} }} }}
    }}
  }});
}}

function initPerformanceCharts() {{
  window._perfChartsInit = true;

  new Chart(document.getElementById('chartSpeed'), {{
    type: 'bar',
    data: {{
      labels: ['Opt 1: Manual C', 'Opt 2: PT Coder', 'Opt 4: ONNX', 'Opt 5: Native DL'],
      datasets: [{{
        label: 'Mean latency (us)',
        data: [84.8, 48.7, 52.5, 51.5],
        backgroundColor: [OPT_COLORS[0], OPT_COLORS[1], OPT_COLORS[3], OPT_COLORS[4]],
        borderColor: [OPT_COLORS[0], OPT_COLORS[1], OPT_COLORS[3], OPT_COLORS[4]],
        borderWidth: 1,
      }}]
    }},
    options: {{
      indexAxis: 'y',
      responsive: true,
      plugins: {{ title: {{ display: true, text: 'Mean Inference Latency (us) - Lower is Better', color: '#e2e8f0' }},
                 legend: {{ labels: {{ color: '#7c8db5' }} }} }},
      scales: {{ x: {{ ticks: {{ color: '#7c8db5' }}, grid: {{ color: '#2e3250' }} }},
                y: {{ ticks: {{ color: '#7c8db5' }}, grid: {{ color: '#2e3250' }} }} }}
    }}
  }});

  new Chart(document.getElementById('chartBinary'), {{
    type: 'bar',
    data: {{
      labels: ['Opt 1: Manual C', 'Opt 2: PT Coder', 'Opt 4: ONNX', 'Opt 5: Native DL'],
      datasets: [{{
        label: 'Binary Size (KB)',
        data: [243.2, 260.2, 260.1, 260.7],
        backgroundColor: [OPT_COLORS[0], OPT_COLORS[1], OPT_COLORS[3], OPT_COLORS[4]],
        borderColor: [OPT_COLORS[0], OPT_COLORS[1], OPT_COLORS[3], OPT_COLORS[4]],
        borderWidth: 1,
      }}]
    }},
    options: {{
      responsive: true,
      plugins: {{ title: {{ display: true, text: 'Binary Size (KB) - Lower is Better', color: '#e2e8f0' }},
                 legend: {{ labels: {{ color: '#7c8db5' }} }} }},
      scales: {{ y: {{ min: 230, ticks: {{ color: '#7c8db5' }}, grid: {{ color: '#2e3250' }} }},
                x: {{ ticks: {{ color: '#7c8db5' }}, grid: {{ color: '#2e3250' }} }} }}
    }}
  }});
}}

// Initialize charts for default page if needed
document.addEventListener('DOMContentLoaded', function() {{
  hljs.highlightAll();
}});
</script>
</body>
</html>'''


def main():
    print("Reading source files...")
    file_data = build_file_data()
    for f in file_data:
        print(f"  {f['path']}: {f['lines']} lines")

    print("\nGenerating HTML...")
    html_content = generate_html(file_data)

    out_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "index.html")
    with open(out_path, "w") as f:
        f.write(html_content)

    size_mb = os.path.getsize(out_path) / (1024 * 1024)
    print(f"\nGenerated: {out_path}")
    print(f"Size: {size_mb:.1f} MB")
    print("Done!")


if __name__ == "__main__":
    main()

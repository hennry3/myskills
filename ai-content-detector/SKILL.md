---
name: "ai-content-detector"
description: "Detects AI-generated text using Tencent Zhuque API and optimizes high-AI-probability paragraphs to remove AI traces. Invoke when user asks to detect AI content, reduce AI traces, remove AI flavor, or optimize AI-generated text."
---

# AI Content Detector & Optimizer

This skill detects whether text is AI-generated using the Tencent Zhuque (朱雀) model, then optimizes paragraphs with high AI probability to make them read more naturally, and finally re-detects to verify improvement.

## When to Invoke

- User asks: "is this text AI-generated?" / "检测AI生成内容" / "这段话是不是AI写的"
- User asks: "reduce AI traces" / "去AI味" / "降低AI痕迹" / "优化AI生成内容"
- User asks: "make text more human-like" / "让文章更自然" / "去AI痕迹"
- User provides text and wants to know AI probability / 检测AI概率

## Prerequisites

- Environment variable `MAKERS_MODEL_KEY` must be set. If missing, stop and tell the user:
  > 环境变量 `MAKERS_MODEL_KEY` 未设置，请先在环境变量中配置朱雀API的Key。

## Core Workflow

### Step 1: Call Zhuque API to Detect

Use `RunCommand` to call the Zhuque API via curl:

```bash
curl -s -X POST "https://ai-gateway.edgeone.link/v1/providers/zhuque-text/classify" \
  -H "Authorization: Bearer $MAKERS_MODEL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "<USER_TEXT_HERE>",
    "is_merge": true
  }'
```

**IMPORTANT**: Replace `<USER_TEXT_HERE>` with the actual text the user wants to detect. Properly escape special characters in JSON (quotes, newlines, backslashes).

**API Parameters**:
- `text` (required): The text to detect
- `is_merge` (optional, bool): Whether to merge paragraphs. Set to `true` for overall detection, `false` for per-paragraph detail. Use `false` when you need segment-level analysis for optimization.

**Response Fields**:
- `softmax_confidence`: Overall AI confidence (lower = more human-like)
- `labels_ratio`: `{"0": human_ratio, "1": AI_ratio, "2": suspected_AI_ratio}`
- `segment_labels`: Array of per-segment results, each with:
  - `text`: segment text
  - `label`: 0=human, 1=AI, 2=suspected AI
  - `conf`: confidence score
  - `order`: segment order
  - `position`: `[start, end]` character positions
- `usage`: token usage info

### Step 2: Analyze & Display Results

Parse the API response and present to the user:

1. **Overall AI Probability**: Show `softmax_confidence` and `labels_ratio`
   - Format as a clear summary:
     ```
     📊 检测结果
     ─────────────────────
     整体AI置信度: 0.85 (高)
     人类占比: 15% | AI占比: 85% | 疑似AI: 0%
     ```
2. **Per-Paragraph Breakdown**: For each segment in `segment_labels`:
   - Show segment order, label (human/AI/suspected), confidence
   - Highlight paragraphs with label=1 (AI) or label=2 (suspected)
   - Example:
     ```
     段落 1: [人类] 置信度 0.02
     段落 2: [AI生成] 置信度 0.95 ← 需要优化
     段落 3: [疑似AI] 置信度 0.60 ← 建议优化
     ```

3. **Recommendation**: Tell the user which paragraphs need optimization (label=1 or label=2, or high conf segments).

### Step 3: Optimize AI-Marked Paragraphs

For paragraphs identified as AI-generated (label=1 or label=2 with high confidence), rewrite them directly using the current LLM capabilities (no external API needed):

**Optimization Guidelines**:
- **Colloquial tone**: Make the language more conversational, like how a real person speaks
- **Personal style**: Add personal voice, opinions, or anecdotes where appropriate
- **Break template patterns**: Disrupt AI-common patterns:
  - Avoid excessive parallel structures (过度排比)
  - Avoid template phrases like "首先...其次...最后", "综上所述", "值得注意的是"
  - Avoid stacking structured lists where prose would be more natural
  - Vary sentence length — mix short punchy sentences with longer ones
- **Preserve core info**: Keep all factual information and key points intact
- **Natural flow**: Make transitions between ideas feel organic, not formulaic

**Output format**: Show the rewritten text clearly, paragraph by paragraph, with before/after comparison:

```
段落 2 优化前:
[original AI-generated text]

段落 2 优化后:
[rewritten natural text]
```

### Step 4: Re-detect & Verify

After optimization, re-run the Zhuque API detection (Step 1) on the optimized full text. Then present a comparison:

```
📈 优化效果对比
─────────────────────
              优化前    优化后
整体AI置信度:  0.85  →  0.12
人类占比:      15%   →  88%
AI占比:        85%   →  12%
```

**Report**:
- If AI confidence dropped significantly: report success
- If still high: suggest further manual editing of specific paragraphs
- Always show the final optimized full text so the user can copy it

## Important Notes

- **Never hardcode the API key**. Always read from `$MAKERS_MODEL_KEY` environment variable.
- The optimization step (Step 3) uses the current Trae session's built-in LLM — no external API call needed.
- If `is_merge=true` returns overall results but no segment detail, re-run with `is_merge=false` to get per-paragraph labels for targeted optimization.
- For very long texts (>5000 chars), consider detecting in chunks to avoid API limits.
- Always show the user the final optimized text in full so they can use it directly.
- Text with `softmax_confidence` < 0.3 is generally considered human-like; > 0.7 is strongly AI.

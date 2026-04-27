---
name: switch
description: モデルバックエンドをUIで切り替える (claude/qwen/qwen-think/glm/kimi/minimax/proxy)
---

Use the AskUserQuestion tool to ask the user which model backend to switch to, with these options:

1. Claude (Anthropic Sonnet) - Default
2. Qwen3.5-Plus (DashScope)
3. Qwen3.5-Plus (DashScope・思考モード)
4. GLM-5.1 (Z.ai)
5. Kimi-K2.5 (ALIBABA Coding Plan)
6. MiniMax-M2.5 (ALIBABA Coding Plan)
7. Proxy mode (/model で自由に切り替え)

After the user selects, run the corresponding bash command:
- 1 → `! ccswitch claude`
- 2 → `! ccswitch qwen`
- 3 → `! ccswitch qwen-think`
- 4 → `! ccswitch glm`
- 5 → `! ccswitch kimi`
- 6 → `! ccswitch minimax`
- 7 → `! ccswitch proxy`

Then confirm which model was set.

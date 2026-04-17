#!/usr/bin/env node
'use strict';
// ccproxy - Claude Code multi-backend proxy
// Routes API requests to DashScope (ALIBABA Coding Plan)
// Usage: node ccproxy.js [--port 18273]

const http = require('http');
const https = require('https');
const { URL } = require('url');
const fs = require('fs');
const path = require('path');

const PORT = parseInt(process.env.CCPROXY_PORT || '18273', 10);

// GLM の API キーをファイルから読み込み
function loadZaiApiKey() {
  const keyFile = path.join(process.env.HOME || '', '.claude', 'zai_api_key.sh');
  try {
    const content = fs.readFileSync(keyFile, 'utf8');
    const match = content.match(/ZAI_API_KEY=["']?([^"'\n]+)["']?/);
    return match ? match[1] : '';
  } catch {
    return process.env.ZAI_API_KEY || '';
  }
}

const BACKENDS = [
  {
    prefix: 'qwen3.5',
    target: 'https://coding-intl.dashscope.aliyuncs.com/apps/anthropic',
    token: process.env.ALIBABACODINGPLAN_API_KEY || ''
  },
  {
    prefix: 'glm',
    target: 'https://api.z.ai/api/anthropic',
    token: loadZaiApiKey()
  }
];

// Model name aliases: short name → full model ID
// Models ending with ! trigger thinking mode injection
const MODEL_ALIASES = {
  'sonnet':          'claude-sonnet-4-6',
  'claude':          'claude-sonnet-4-6',
  'claude-sonnet':   'claude-sonnet-4-6',
  'opus':            'claude-opus-4-7',
  'claude-opus':     'claude-opus-4-7',
  'opus-4-7':        'claude-opus-4-7',
  'claude-opus-4-7': 'claude-opus-4-7',
  'opus-4-5':        'claude-opus-4-5',
  'haiku':           'claude-haiku-4-5',
  'claude-haiku':    'claude-haiku-4-5',
  'qwen':            'qwen3.5-plus',
  'qwen-think':      'qwen3.5-plus!',
  'qwen3.5':         'qwen3.5-plus',
  'qwen3.5-plus':    'qwen3.5-plus',
  'glm':             'glm-5.1',
  'glm-5.1':         'glm-5.1',
};

function resolveModelAlias(model) {
  const m = (model || '').toLowerCase();
  return MODEL_ALIASES[m] || model;
}

function resolveModelAlias(model) {
  const m = (model || '').toLowerCase();
  return MODEL_ALIASES[m] || model;
}

function getBackend(model) {
  const m = (model || '').toLowerCase();
  for (const b of BACKENDS) {
    if (m.startsWith(b.prefix)) return b;
  }
  return null;
}

// Strip thinking marker (!) and return {model, enableThinking}
function parseThinking(model) {
  if (model.endsWith('!')) {
    return { model: model.slice(0, -1), enableThinking: true };
  }
  return { model, enableThinking: false };
}

// Static model list returned for GET /v1/models
const STATIC_MODELS = [
  { type: 'model', id: 'sonnet',          display_name: 'Claude Sonnet 4.6 (Anthropic)',    created_at: '2025-01-01T00:00:00Z' },
  { type: 'model', id: 'opus',            display_name: 'Claude Opus 4.7 (Anthropic)',      created_at: '2025-01-01T00:00:00Z' },
  { type: 'model', id: 'opus-4-5',        display_name: 'Claude Opus 4.5 (Anthropic)',      created_at: '2025-01-01T00:00:00Z' },
  { type: 'model', id: 'haiku',           display_name: 'Claude Haiku 4.5 (Anthropic)',     created_at: '2025-01-01T00:00:00Z' },
  { type: 'model', id: 'qwen',            display_name: 'Qwen3.5-Plus (DashScope)',          created_at: '2025-01-01T00:00:00Z' },
  { type: 'model', id: 'qwen-think',      display_name: 'Qwen3.5-Plus Thinking (DashScope)', created_at: '2025-01-01T00:00:00Z' },
  { type: 'model', id: 'glm',             display_name: 'GLM-5.1 (Z.ai)',                    created_at: '2025-01-01T00:00:00Z' },
];

function handleModels(req, res) {
  const out = JSON.stringify({ data: STATIC_MODELS });
  res.writeHead(200, { 'content-type': 'application/json', 'content-length': Buffer.byteLength(out) });
  res.end(out);
}

const server = http.createServer((req, res) => {
  // Intercept model list to inject extra backends
  if (req.method === 'GET' && req.url.startsWith('/v1/models')) {
    return handleModels(req, res);
  }

  const chunks = [];
  req.on('data', c => chunks.push(c));
  req.on('end', () => {
    const body = Buffer.concat(chunks);
    let model = '';
    let jsonBody = null;
    try { jsonBody = JSON.parse(body.toString()); model = jsonBody.model || ''; } catch {}

    // Resolve short name aliases (e.g. "qwen" → "qwen3.5-plus")
    const resolvedModel = resolveModelAlias(model);
    const { model: finalModel, enableThinking } = parseThinking(resolvedModel);

    if (jsonBody) {
      jsonBody.model = finalModel;
      if (enableThinking && !jsonBody.thinking) {
        jsonBody.thinking = { type: 'enabled', budget_tokens: 10000 };
      }
    }
    let outBody = jsonBody ? Buffer.from(JSON.stringify(jsonBody)) : body;

    const backend = getBackend(finalModel);
    let targetUrl, authToken;

    if (backend) {
      targetUrl = new URL(backend.target);
      authToken = backend.token;
    } else {
      // デフォルトは Anthropic へ
      targetUrl = new URL('https://api.anthropic.com');
      authToken = null;
    }

    const headers = { ...req.headers, host: targetUrl.host };
    delete headers['connection'];
    delete headers['transfer-encoding'];

    // Update content-length to match the (possibly modified) body
    headers['content-length'] = outBody.length;

    if (authToken) {
      headers['x-api-key'] = authToken;
      delete headers['authorization'];
    }
    // Anthropic 直結時、メッセージ内の thinking ブロックを削除
    if (!backend && jsonBody?.messages) {
      jsonBody.messages = jsonBody.messages.map(msg => {
        if (!Array.isArray(msg.content)) return msg;
        return {
          ...msg,
          content: msg.content.filter(block => block.type !== 'thinking')
        };
      });
      const freshBody = Buffer.from(JSON.stringify(jsonBody));
      outBody = freshBody;
      headers['content-length'] = freshBody.length;
    }

    const path = targetUrl.pathname.replace(/\/$/, '') + req.url;
    const isHttps = targetUrl.protocol === 'https:';
    const opts = {
      hostname: targetUrl.hostname,
      port: targetUrl.port || (isHttps ? 443 : 80),
      path,
      method: req.method,
      headers
    };

    const proxy = (isHttps ? https : http).request(opts, pRes => {
      res.writeHead(pRes.statusCode, pRes.headers);
      pRes.pipe(res);
    });

    proxy.on('error', err => {
      const ts = new Date().toISOString();
      console.error('[' + ts + '] ERROR: ' + err.message);
      if (!res.headersSent) {
        res.writeHead(502, { 'content-type': 'application/json' });
        res.end(JSON.stringify({ type: 'error', message: 'ccproxy: ' + err.message }));
      }
    });

    proxy.write(outBody);
    proxy.end();
  });
});

server.listen(PORT, () => {
  console.log('ccproxy listening on http://localhost:' + PORT);
  BACKENDS.forEach(b => console.log('  ' + b.prefix + '* → ' + b.target));
  console.log('  * -> https://api.anthropic.com (passthrough)');
  console.log('');
  console.log('主力モデル：qwen3.5-plus (ALIBABA Coding Plan)');
  console.log('GLM モデル：glm-5.1 (Z.ai) - 環境変数 ZAI_API_KEY を設定');
});

# LiteLLM Worker Registrations

This document captures the normalized LiteLLM payloads for the current worker fleet.

It intentionally does not include the `curl` command or the LiteLLM master key.

## Public model names

Use these client-facing model names in LiteLLM:

- `local-dev-small`
- `local-vision`
- `local-dev-primary`

## Routing intent

- `local-dev-small`
  - pooled lane for the five `Qwen3.5-4B` workers
  - intended for lightweight coding and general development tasks
- `local-vision`
  - single-host lane for the `Qwen2.5-VL-3B` worker
  - intended for OCR and vision tasks
- `local-dev-primary`
  - single-host lane for the `Qwen3.5-9B` worker
  - intended as the strongest default coding/reasoning lane currently in the fleet

## Notes

- The current host install scripts emit smart quotes in the sample JSON. Fix that later; do not rely on the pasted sample formatting verbatim.
- `10.10.10.132` is currently identified with the `zbm1a008gb001` hostname in the payload source, but this is actually the M2 Air device and will be corrected later.
- `model_info` uses the deployed runtime context window, not the GGUF training context length.
- Costs are set to `0.0` because these are local workers.

## Recommended `model_info`

Use these fields consistently:

- `mode`
- `input_cost_per_token`
- `output_cost_per_token`
- `max_input_tokens`
- `max_output_tokens`

Chosen values:

- `local-dev-small`
  - `mode: "chat"`
  - `input_cost_per_token: 0.0`
  - `output_cost_per_token: 0.0`
  - `max_input_tokens: 8192`
  - `max_output_tokens: 8192`
- `local-vision`
  - `mode: "chat"`
  - `input_cost_per_token: 0.0`
  - `output_cost_per_token: 0.0`
  - `max_input_tokens: 8192`
  - `max_output_tokens: 8192`
- `local-dev-primary`
  - `mode: "chat"`
  - `input_cost_per_token: 0.0`
  - `output_cost_per_token: 0.0`
  - `max_input_tokens: 16384`
  - `max_output_tokens: 16384`

## Normalized payloads

### `local-dev-small`

```json
[
  {
    "model_name": "local-dev-small",
    "litellm_params": {
      "model": "openai/qwen35-4b",
      "api_base": "http://10.10.10.151:8001/v1",
      "api_key": "sk-llama-4RSB7X5uFzgpMjYJ8Ye_8BWWQAMoesSqhe5T8-SfWyI",
      "custom_llm_provider": "openai"
    },
    "model_info": {
      "mode": "chat",
      "input_cost_per_token": 0.0,
      "output_cost_per_token": 0.0,
      "max_input_tokens": 8192,
      "max_output_tokens": 8192
    }
  },
  {
    "model_name": "local-dev-small",
    "litellm_params": {
      "model": "openai/qwen35-4b",
      "api_base": "http://10.10.10.121:8001/v1",
      "api_key": "sk-llama-QlrqAki66nbAuHcT63ynRpey-DGY87VANX1KQC19yYQ",
      "custom_llm_provider": "openai"
    },
    "model_info": {
      "mode": "chat",
      "input_cost_per_token": 0.0,
      "output_cost_per_token": 0.0,
      "max_input_tokens": 8192,
      "max_output_tokens": 8192
    }
  },
  {
    "model_name": "local-dev-small",
    "litellm_params": {
      "model": "openai/qwen35-4b",
      "api_base": "http://10.10.10.188:8001/v1",
      "api_key": "sk-llama-oiXYv3JiaFwjjylKiV0tptzEd-r7QSX1RvpSqe4OUgI",
      "custom_llm_provider": "openai"
    },
    "model_info": {
      "mode": "chat",
      "input_cost_per_token": 0.0,
      "output_cost_per_token": 0.0,
      "max_input_tokens": 8192,
      "max_output_tokens": 8192
    }
  },
  {
    "model_name": "local-dev-small",
    "litellm_params": {
      "model": "openai/qwen35-4b",
      "api_base": "http://10.10.10.116:8001/v1",
      "api_key": "sk-llama-8by8LMOSdtk01COo6NEar_pviEpXaAgmqjPxU82auxQ",
      "custom_llm_provider": "openai"
    },
    "model_info": {
      "mode": "chat",
      "input_cost_per_token": 0.0,
      "output_cost_per_token": 0.0,
      "max_input_tokens": 8192,
      "max_output_tokens": 8192
    }
  },
  {
    "model_name": "local-dev-small",
    "litellm_params": {
      "model": "openai/qwen35-4b",
      "api_base": "http://10.10.10.132:8001/v1",
      "api_key": "sk-llama-RR_EEkOkO30Xwb9YAQNNiU9i48SvzDkyUdTPisJMZbE",
      "custom_llm_provider": "openai"
    },
    "model_info": {
      "mode": "chat",
      "input_cost_per_token": 0.0,
      "output_cost_per_token": 0.0,
      "max_input_tokens": 8192,
      "max_output_tokens": 8192
    }
  }
]
```

### `local-vision`

```json
[
  {
    "model_name": "local-vision",
    "litellm_params": {
      "model": "openai/qwen25-vl-3b",
      "api_base": "http://10.10.10.152:8001/v1",
      "api_key": "sk-llama-O7jhNWbpwvdqePC96iePQq_C3MK7Nuc62dMCYepN4Sc",
      "custom_llm_provider": "openai"
    },
    "model_info": {
      "mode": "chat",
      "input_cost_per_token": 0.0,
      "output_cost_per_token": 0.0,
      "max_input_tokens": 8192,
      "max_output_tokens": 8192
    }
  }
]
```

### `local-dev-primary`

```json
[
  {
    "model_name": "local-dev-primary",
    "litellm_params": {
      "model": "openai/qwen35-9b",
      "api_base": "http://10.10.10.131:8001/v1",
      "api_key": "sk-llama-K-XanDFIbE-WKglGb9UPRo4BNqJ3CyyKmbw2Kt9v4U0",
      "custom_llm_provider": "openai"
    },
    "model_info": {
      "mode": "chat",
      "input_cost_per_token": 0.0,
      "output_cost_per_token": 0.0,
      "max_input_tokens": 16384,
      "max_output_tokens": 16384
    }
  }
]
```

## Operator inventory guidance

Do not overload LiteLLM with fleet inventory metadata.

Track this separately:

- hostname
- IP
- hardware class
- lane
- backend model alias
- intended use
- worker API key reference
- last validation time
- notes

return {
  dir = '~/.config/nvim/lua/raphaelluethy/plugins/custom/llm',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local coding_promt =
      'You are an AI programming assistant. Follow the instructions carefully. Do omit any explanations. Do not talk at all. Only output valid code. Do not provide any backticks that surround the code. Never ever output backticks like this ```. Any comment that is asking you for something should be removed after you satisfy them. Other comments should left alone. Do not output backticks'
    local llm = require 'llm'

    local function groq_replace()
      llm.invoke_llm_and_stream_into_editor({
        url = 'https://api.groq.com/openai/v1/chat/completions',
        model = 'llama-3.1-70b-versatile',
        api_key_name = 'GROQ_API_KEY',
        system_prompt = coding_promt,
        replace = true,
      }, llm.make_openai_spec_curl_args, llm.handle_openai_spec_data)
    end
    local function groq_help()
      llm.invoke_llm_and_stream_into_editor({
        url = 'https://api.groq.com/openai/v1/chat/completions',
        model = 'llama-3.1-70b-versatile',
        api_key_name = 'GROQ_API_KEY',
        system_prompt = coding_promt,
        replace = false,
      }, llm.make_openai_spec_curl_args, llm.handle_openai_spec_data)
    end

    local function anthropic_replace()
      llm.invoke_llm_and_stream_into_editor({
        url = 'https://api.anthropic.com/v1/messages',
        model = 'claude-3-5-sonnet-20240620',
        api_key_name = 'ANTHROPIC_API_KEY',
        system_prompt = coding_promt,
        replace = true,
      }, llm.make_anthropic_spec_curl_args, llm.handle_anthropic_spec_data)
    end
    local function anthropic_help()
      llm.invoke_llm_and_stream_into_editor({
        url = 'https://api.anthropic.com/v1/messages',
        model = 'claude-3-5-sonnet-20240620',
        api_key_name = 'ANTHROPIC_API_KEY',
        system_prompt = coding_promt,
        replace = false,
      }, llm.make_anthropic_spec_curl_args, llm.handle_anthropic_spec_data)
    end

    local function ollama_replace()
      llm.invoke_llm_and_stream_into_editor({
        url = 'http://localhost:11434/api/chat',
        model = 'mistral-nemo',
        system_prompt = coding_promt,
        replace = true,
      }, llm.make_ollama_spec_curl_args, llm.handle_ollama_spec_data)
    end
    local function ollama_help()
      llm.invoke_llm_and_stream_into_editor({
        url = 'http://localhost:11434/api/chat',
        model = 'mistral-nemo',
        system_prompt = coding_promt,
        replace = false,
      }, llm.make_ollama_spec_curl_args, llm.handle_ollama_spec_data)
    end

    vim.keymap.set({ 'n', 'v' }, '<leader>lgr', groq_replace, {
      desc = 'llm groq',
    })
    vim.keymap.set({ 'n', 'v' }, '<leader>lgh', groq_help, {
      desc = 'llm groq help',
    })
    vim.keymap.set({ 'n', 'v' }, '<leader>lar', anthropic_replace, {
      desc = 'llm anthropic_help',
    })
    vim.keymap.set({ 'n', 'v' }, '<leader>lah', anthropic_help, {
      desc = 'llm anthropic help',
    })
    vim.keymap.set({ 'n', 'v' }, '<leader>lor', ollama_replace, {
      desc = 'llm ollama',
    })
    vim.keymap.set({ 'n', 'v' }, '<leader>loh', ollama_help, {
      desc = 'llm ollama help',
    })
  end,
}

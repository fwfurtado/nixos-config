-- ~/.config/nvim/init.lua — Neovim 0.12+, um único plugin (nvim-treesitter)
vim.loader.enable()

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

--------------------------------------------------------------------------------
-- Options
--------------------------------------------------------------------------------
local o = vim.o

o.number = true
o.relativenumber = true
o.signcolumn = 'yes'
o.cursorline = true
o.scrolloff = 8
o.wrap = false
o.winborder = 'rounded'

o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.smartindent = true

o.ignorecase = true
o.smartcase = true
o.inccommand = 'split'

o.undofile = true
o.swapfile = false
o.updatetime = 250

o.splitbelow = true
o.splitright = true

o.mousescroll = 'ver:1,hor:2'

-- :find <Tab> vira um finder decente sem plugin
o.path = '.,**'
o.wildignore = '**/.git/*,**/node_modules/*,**/target/*,**/build/*,**/.venv/*'
o.wildoptions = 'pum,fuzzy'

-- completação embutida
o.completeopt = 'menuone,noselect,fuzzy,popup'

-- :grep usando ripgrep, resultado no quickfix
if vim.fn.executable('rg') == 1 then
    o.grepprg = 'rg --vimgrep --smart-case'
    o.grepformat = '%f:%l:%c:%m'
end


-- usar clipboard do SO.
vim.schedule(function()
    vim.o.clipboard = 'unnamedplus'
end)

-- forçar OSC 52 quando o provider nativo não serve
if vim.env.SSH_TTY then
    local osc52 = require('vim.ui.clipboard.osc52')
    vim.g.clipboard = {
        name = 'OSC 52',
        copy = { ['+'] = osc52.copy('+'), ['*'] = osc52.copy('*') },
        paste = { ['+'] = osc52.paste('+'), ['*'] = osc52.paste('*') },
    }
end

--------------------------------------------------------------------------------
-- Plugins
--------------------------------------------------------------------------------
-- Hook precisa ser registrado ANTES do vim.pack.add, senão não roda na primeira
-- instalação nem no bootstrap a partir do lockfile.
vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
        if ev.data.spec.name == 'nvim-treesitter' and ev.data.kind ~= 'delete' then
            if not ev.data.active then vim.cmd.packadd('nvim-treesitter') end
            vim.cmd('TSUpdate')
        end
    end,
})

vim.pack.add({
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects', version = 'main' },
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter',             version = 'main' },
    'https://github.com/nvim-mini/mini.nvim',
    'https://github.com/stevearc/oil.nvim',
    'https://github.com/FylerOrg/fyler.nvim',
}, { confirm = false })


vim.cmd.colorscheme('minicyan')

--------------------------------------------------------------------------------
-- Treesitter
--------------------------------------------------------------------------------
local parsers = {
    'bash', 'c', 'dart', 'diff', 'dockerfile', 'fish', 'go', 'gomod', 'gosum',
    'gitcommit', 'hcl', 'json', 'lua', 'make', 'markdown',
    'markdown_inline', 'python', 'query', 'rust', 'sql', 'toml', 'vim',
    'vimdoc', 'yaml', 'zig',
}

require('nvim-treesitter').install(parsers)

--------------------------------------------------------------------------------
-- mini.nvim
--------------------------------------------------------------------------------
require('mini.icons').setup()
require('mini.icons').mock_nvim_web_devicons()

require('mini.surround').setup({
    search_method = 'nearest'
})

-- gen_ai_spec vive no módulo, não depende de MiniExtra.setup() ter rodado.
local gen_ai_spec = require('mini.extra').gen_ai_spec

local ai = require('mini.ai')
ai.setup({
    n_lines = 500,
    custom_textobjects = {
        -- Estes dependem de queries `textobjects.scm`, que NÃO vêm no
        -- nvim-treesitter (branch main só traz highlights/indents/folds/locals).
        -- Quem fornece é o nvim-treesitter-textobjects, no vim.pack.add acima.
        -- Sem ele: "Can not get query for buffer N and language X".

        -- argumento/parâmetro (44 linguagens; substitui o `a` por patterns)
        a = ai.gen_spec.treesitter({ a = '@parameter.outer', i = '@parameter.inner' }),

        -- chamada de função — recupera o que o `f` built-in fazia
        F = ai.gen_spec.treesitter({ a = '@call.outer', i = '@call.inner' }),

        f = ai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }),
        c = ai.gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' }),
        o = ai.gen_spec.treesitter({
            a = { '@conditional.outer', '@loop.outer' },
            i = { '@conditional.inner', '@loop.inner' },
        }),

        -- bloco e comentário
        k = ai.gen_spec.treesitter({ a = '@block.outer', i = '@block.inner' }),
        C = ai.gen_spec.treesitter({ a = '@comment.outer', i = '@comment.outer' }),

        -- os abaixo não dependem de parser treesitter: funcionam em qualquer buffer
        B = gen_ai_spec.buffer(),
        D = gen_ai_spec.diagnostic(),
        I = gen_ai_spec.indent(),
        L = gen_ai_spec.line(),
        N = gen_ai_spec.number(),
    },
})

require('mini.pick').setup()

-- Precisa vir DEPOIS de mini.pick: MiniExtra.setup() só registra os pickers em
-- MiniPick.registry se o global MiniPick já existir (extra.lua, apply_config).
require('mini.extra').setup()

require('mini.move').setup({
    mappings = {
        left = '<M-Left>',
        right = '<M-Right>',
        down = '<M-Down>',
        up = '<M-Up>',

        line_left = '<M-Left>',
        line_right = '<M-Right>',
        line_down = '<M-Down>',
        line_up = '<M-Up>',
    }
})

require('mini.animate').setup({
    scroll = {
        timing = function(_, n) return math.min(250 / n, 10) end,
    },
})
require('mini.indentscope').setup()
require('mini.trailspace').setup()
require('mini.statusline').setup()
require('mini.tabline').setup()

-- mini.clue — janela de dicas para prefixos de teclas.
-- As descrições vêm do campo `desc` dos mapeamentos já existentes; os `clues`
-- abaixo só nomeiam os GRUPOS (o que aparece antes da segunda tecla).
local miniclue = require('mini.clue')
miniclue.setup({
    triggers = {
        { mode = { 'n', 'x' }, keys = '<Leader>' },
        { mode = 'n',          keys = '<C-w>' },
        { mode = { 'n', 'x' }, keys = 'g' },
        { mode = { 'n', 'x' }, keys = 'z' },
        { mode = { 'n', 'x' }, keys = "'" },
        { mode = { 'n', 'x' }, keys = '`' },
        { mode = { 'n', 'x' }, keys = '"' },
        { mode = { 'n', 'x' }, keys = '[' },
        { mode = { 'n', 'x' }, keys = ']' },
        { mode = { 'i', 'c' }, keys = '<C-r>' },
        { mode = 'i',          keys = '<C-x>' },
    },

    clues = {
        { mode = 'n', keys = '<Leader>f', desc = '+Find' },
        { mode = 'n', keys = '<Leader>g', desc = '+Git' },
        { mode = 'n', keys = '<Leader>l', desc = '+LSP' },
        { mode = 'n', keys = '<Leader>b', desc = '+Buffer' },

        -- conjuntos prontos para teclas built-in do Vim
        miniclue.gen_clues.g(),
        miniclue.gen_clues.z(),
        miniclue.gen_clues.marks(),
        miniclue.gen_clues.registers(),
        miniclue.gen_clues.windows(),
        miniclue.gen_clues.builtin_completion(),
        miniclue.gen_clues.square_brackets(),
    },

    window = {
        delay = 300,
        config = { width = 'auto' },
    },
})

require('mini.misc').setup_auto_root(
    { '.git' },
    function(path) return vim.fs.dirname(path) end
)
--------------------------------------------------------------------------------
-- oil.nvim
--------------------------------------------------------------------------------
-- default_file_explorer = false enquanto isso for teste: assumir os buffers de
-- diretório é irreversível dentro da sessão e mudaria o comportamento de
-- `nvim .` sem você pedir. Vire para true se decidir adotar.
require('oil').setup({
    default_file_explorer = false,

    -- mini.icons já está carregado e faz mock de nvim-web-devicons,
    -- então a coluna de ícone funciona sem dependência nova.
    columns = { 'icon' },

    delete_to_trash = true,
    watch_for_changes = true,
    skip_confirm_for_simple_edits = true,

    lsp_file_methods = {
        enabled = true,
        timeout_ms = 1000, -- mesmo default do options.lsp_timeout do mini.files
    },

    view_options = {
        show_hidden = true,
    },
})

--------------------------------------------------------------------------------
-- fyler.nvim — em avaliação, convivendo com o oil.nvim
--------------------------------------------------------------------------------
require('fyler').setup({
    use_as_default_explorer = true,

    follow_root_dir = false,

    integrations = {
        icon = 'mini_icons',
    },

    extensions = {
        git = { enabled = true, inline = false },
        trash = { enabled = true },
        watcher = { enabled = true },
    },

    ui = {
        indent_guides = true,
        hidden_items = { switches = {} },
    },
})

vim.api.nvim_create_autocmd('FileType', {
    pattern = parsers,
    callback = function()
        -- realce, dobra e indentação baseados na árvore sintática
        pcall(vim.treesitter.start)
        vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})

-- dobras existem mas começam todas abertas
o.foldmethod = 'expr'
o.foldlevelstart = 99

--------------------------------------------------------------------------------
-- LSP — definido à mão, sem nvim-lspconfig
--------------------------------------------------------------------------------
local servers = {
    rust_analyzer = {
        cmd = { 'rust-analyzer' },
        filetypes = { 'rust' },
        root_markers = { 'Cargo.toml', 'rust-project.json' },
    },
    gopls = {
        cmd = { 'gopls' },
        filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
        root_markers = { 'go.work', 'go.mod', '.git' },
        settings = {
            gopls = {
                staticcheck = true,
                gofumpt = true,
                usePlaceholders = true, -- completion de função vem com snippet dos argumentos
                hints = {
                    assignVariableTypes = true,
                    compositeLiteralFields = true,
                    constantValues = true,
                    parameterNames = true,
                    rangeVariableTypes = true,
                },
            },
        },
    },
    zls = {
        cmd = { 'zls' },
        filetypes = { 'zig', 'zir' },
        root_markers = { 'build.zig', '.git' },
    },
    lua_ls = {
        cmd = { 'lua-language-server' },
        filetypes = { 'lua' },
        root_markers = { '.luarc.json', '.luarc.jsonc', '.git' },
        settings = {
            Lua = {
                runtime = { version = 'LuaJIT' },
                workspace = { library = vim.api.nvim_get_runtime_file('', true) },
                diagnostics = { globals = { 'vim' } },
            },
        },
    },
    basedpyright = {
        cmd = { 'basedpyright-langserver', '--stdio' },
        filetypes = { 'python' },
        root_markers = { 'pyproject.toml', 'setup.py', 'requirements.txt', '.git' },
    },
    ruff = {
        cmd = { 'ruff', 'server' },
        filetypes = { 'python' },
        root_markers = { 'pyproject.toml', 'ruff.toml', '.git' },
    },
}

for name, config in pairs(servers) do
    vim.lsp.config(name, config)
    -- só habilita o que existe no PATH: evita ruído em máquina sem a toolchain
    if vim.fn.executable(config.cmd[1]) == 1 then
        vim.lsp.enable(name)
    end
end

vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client and client:supports_method('textDocument/completion') then
            vim.lsp.completion.enable(true, ev.data.client_id, ev.buf, { autotrigger = true })
        end

        -- Triggers do mini.clue são mapeamentos buffer-local e precisam ser os
        -- mais recentes. O LSP cria os seus no attach, então recria os triggers
        -- depois (doc do mini.clue, "Triggers are implemented as special
        -- buffer-local mappings").
        vim.schedule(function()
            if vim.api.nvim_buf_is_valid(ev.buf) then
                MiniClue.ensure_buf_triggers(ev.buf)
            end
        end)
    end,
})

vim.diagnostic.config({
    virtual_text = { current_line = true },
    severity_sort = true,
    signs = true,
})

--------------------------------------------------------------------------------
-- Keymaps
--------------------------------------------------------------------------------
-- Defaults de LSP do 0.11+ já cobrem: K (hover), grn (rename), gra (code action),
-- grr (references), gri (implementation), gO (symbols), CTRL-S (signature).
local map = vim.keymap.set

map('n', '<leader>ff', '<cmd>Pick files<cr>', { desc = 'Find files' })
map('n', '<leader>fg', '<cmd>Pick grep_live<cr>', { desc = 'Live grep' })
map('n', '<leader>fh', '<cmd>Pick help<cr>', { desc = 'Help' })
map('n', '<leader>fr', '<cmd>Pick resume<cr>', { desc = 'Retoma última busca' })

-- pickers do mini.extra
map('n', '<leader>fo', '<cmd>Pick oldfiles<cr>', { desc = 'Oldfiles' })
map('n', '<leader>fl', '<cmd>Pick buf_lines scope="current"<cr>', { desc = 'Linhas do buffer' })
map('n', '<leader>fk', '<cmd>Pick keymaps<cr>', { desc = 'Keymaps' })
--map('n', '<leader>fC', '<cmd>Pick colorschemes<cr>', { desc = 'Colorschemes' })
--map('n', '<leader>fH', '<cmd>Pick hl_groups<cr>', { desc = 'Highlight groups' })
map('n', '<leader>fq', '<cmd>Pick list scope="quickfix"<cr>', { desc = 'Quickfix' })

-- Git maps
map('n', '<leader>gh', '<cmd>Pick git_hunks<cr>', { desc = 'Git hunks' })
map('n', '<leader>gH', '<cmd>Pick git_hunks scope="staged"<cr>', { desc = 'Git hunks (staged)' })
map('n', '<leader>gc', '<cmd>Pick git_commits<cr>', { desc = 'Git commits' })
map('n', '<leader>gb', '<cmd>Pick git_branches<cr>', { desc = 'Git branches' })

-- LSP maps
map('n', '<leader>la', function()
    ---@type vim.lsp.buf.code_action.Opts
    vim.lsp.buf.code_action({ context = { only = { 'quickfix' } } })
end, { desc = 'Quick fix' })

map('n', '<leader>lo', function()
    ---@type vim.lsp.buf.code_action.Opts
    vim.lsp.buf.code_action({ context = { only = { 'source.organizeImports' } }, apply = true })
end, { desc = 'Organize imports' })

map('n', '<leader>lh', function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
end, { desc = 'Toggle inlay hints' })

map('n', '<leader>lv', function()
    local cfg = vim.diagnostic.config() or {}
    local using_lines = cfg.virtual_lines ~= nil and cfg.virtual_lines ~= false
    vim.diagnostic.config({
        virtual_lines = not using_lines and { current_line = true } or false,
        virtual_text = using_lines and { current_line = true } or false,
    })
end, { desc = 'Toggle diagnostics em linhas' })

map('n', '<leader>lr', '<cmd>Pick lsp scope="references"<cr>', { desc = 'LSP references' })
map('n', '<leader>ls', '<cmd>Pick lsp scope="document_symbol"<cr>', { desc = 'LSP symbols' })
map('n', '<leader>lS', '<cmd>Pick lsp scope="workspace_symbol_live"<cr>', { desc = 'LSP workspace symbols' })
map('n', '<leader>lf', function() vim.lsp.buf.format({ async = true }) end, { desc = 'Format' })
map('n', '<leader>ld', vim.diagnostic.open_float, { desc = 'Line diagnostics' })
map('n', '<leader>lD', '<cmd>Pick diagnostic<cr>', { desc = 'Diagnostics' })
map('n', '<leader>q', function()
    local open = vim.fn.getqflist({ winid = 0 }).winid ~= 0
    vim.cmd(open and 'cclose' or 'copen')
end, { desc = 'Toggle quickfix' })

map('n', ']e', function()
    vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
end, { desc = 'Próximo erro' })

map('n', '[e', function()
    vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })
end, { desc = 'Erro anterior' })

-- Buffer Maps
map('n', '<leader>bp', '<cmd>Pick buffers<cr>', { desc = 'Buffers' })
map('n', '<leader>bd', function() require('mini.bufremove').delete() end, { desc = 'Fecha buffer' })
map('n', '<leader>bo', '<cmd>%bd|e#|bd#<cr>', { desc = 'Fecha os outros buffers' })

-- Trim maps
map('n', '<leader>t', function()
    MiniTrailspace.trim()
    MiniTrailspace.trim_last_lines()
end, { desc = 'Trim all' })


-- Dir buffer maps
map('n', '-', '<cmd>Oil<cr>', { desc = 'Oil (diretório do buffer)' })
map('n', '<leader>e', function() require('fyler').toggle({ kind='split_right_most' }) end, { desc = 'Fyler (diretório do buffer)' })


-- Helper maps
map('n', '<leader>w', '<cmd>write<cr>', { desc = 'Write' })
map('n', '<esc>', '<cmd>nohlsearch<cr>', { desc = 'Clear highlight' })

-- Replace selected line with yanked text and keep yanked text in register (like dd + p keeping yanked text)
map('x', '<leader>p', [["_dP]], { desc = 'Paste keeping register' })

-- Create an undo point after each space
map('i', '<Space>', '<C-g>u<Space>')

-- Tab/S-Tab: navega no menu; se houver snippet ativo, pula entre placeholders
map({ 'i', 's' }, '<Tab>', function()
    if vim.fn.pumvisible() == 1 then return '<C-n>' end
    if vim.snippet.active({ direction = 1 }) then return '<cmd>lua vim.snippet.jump(1)<cr>' end
    return '<Tab>'
end, { expr = true, desc = 'Completion: próximo / snippet' })

map({ 'i', 's' }, '<S-Tab>', function()
    if vim.fn.pumvisible() == 1 then return '<C-p>' end
    if vim.snippet.active({ direction = -1 }) then return '<cmd>lua vim.snippet.jump(-1)<cr>' end
    return '<S-Tab>'
end, { expr = true, desc = 'Completion: anterior / snippet' })

-- Enter confirma se houver item selecionado; senão, quebra linha com undo break
map('i', '<CR>', function()
    if vim.fn.pumvisible() == 1 and vim.fn.complete_info({ 'selected' }).selected ~= -1 then
        return '<C-y>'
    end
    return '<C-g>u<CR>'
end, { expr = true, desc = 'Confirma completion ou nova linha' })

map('i', '<C-Space>', vim.lsp.completion.get, { desc = 'Trigger completion' })

--------------------------------------------------------------------------------
-- Autocmds
--------------------------------------------------------------------------------
vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function() vim.hl.on_yank() end,
})

-- grep abre o quickfix automaticamente
vim.api.nvim_create_autocmd('QuickFixCmdPost', {
    pattern = { 'grep', 'grepadd' },
    command = 'cwindow',
})

vim.env.GIT_CONFIG_GLOBAL = ""


-- Remove the white status bar below
vim.o.laststatus = 0

-- True colour support
vim.o.termguicolors = true

-- lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

local function nvim_tree_on_attach(bufnr)
	local api = require("nvim-tree.api")
	local nt_remote = require("nvim_tree_remote")

	local function opts(desc)
		return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
	end

	local function default_edit()
		local tmux_options = nt_remote.tmux_defaults()
		-- tmux_options.split_position = ""
		-- nt_remote.open_file_remote_and_folder_local(vim.g.nvim_tree_remote_socket_path, "edit", tmux_options)

		local node = api.tree.get_node_under_cursor()
		if node.type == "file" then
			nt_remote.remote_nvim_open(
				vim.g.nvim_tree_remote_socket_path,
				"edit",
				node.absolute_path,
				nt_remote.tmux_defaults()
			)
		else
			-- api.node.open.edit()
			local pane_id = tmux_options.pane
			-- os.execute("tmux select-pane -t '" .. pane_id .. "'")
			-- os.execute("tmux send-keys -t '" .. pane_id .. "' C-c")
			os.execute("tmux send-keys -t '" .. pane_id .. "' 'cd ''" .. "'\\'")
			os.execute("tmux send-keys -t '" .. pane_id .. "' '" .. node.absolute_path .. "'\\'")
			os.execute("tmux send-keys -t '" .. pane_id .. "' Enter")

			api.tree.change_root_to_node()
		end
	end

	api.config.mappings.default_on_attach(bufnr)

	vim.keymap.set("n", "<CR>", default_edit, opts("Cd and/or run/open in tmux"))
	vim.keymap.set("n", "o", nt_remote.tabnew_main_pane, opts("Open in treemux without tmux split"))
	vim.keymap.set("n", "l", nt_remote.tabnew, opts("Open in treemux"))
	vim.keymap.set("n", "<C-t>", nt_remote.tabnew, opts("Open in treemux"))
	vim.keymap.set("n", "<2-LeftMouse>", nt_remote.tabnew, opts("Open in treemux"))
	vim.keymap.set("n", "v", nt_remote.vsplit, opts("Vsplit in treemux"))
	vim.keymap.set("n", "<C-v>", nt_remote.vsplit, opts("Vsplit in treemux"))
	vim.keymap.set("n", "<C-x>", nt_remote.split, opts("Split in treemux"))

	vim.keymap.set("n", ".", api.tree.toggle_hidden_filter, opts("Open/close hidden"))
	-- vim.keymap.set("n", "n", api.marks.navigate.next, opts "")
	-- vim.keymap.set("n", "s", api.marks.navigate.select, opts "")
	vim.keymap.set("n", "w", api.node.run.system, opts("Open in new window"))
	vim.keymap.set("n", "<F1>", api.node.show_info_popup, opts("Show info popup"))
	vim.keymap.set("n", "u", api.tree.change_root_to_node, opts("Dir up"))
	vim.keymap.set("n", "h", api.tree.close, opts("Close node"))

	-- vim.keymap.set("n", "b", api.node.run.cmd, opts "Open in treemux without tmux split")

	vim.keymap.set("n", "-", "", { buffer = bufnr })
	vim.keymap.del("n", "-", { buffer = bufnr })
	vim.keymap.set("n", "<C-k>", "", { buffer = bufnr })
	vim.keymap.del("n", "<C-k>", { buffer = bufnr })
	vim.keymap.set("n", "O", "", { buffer = bufnr })
	vim.keymap.del("n", "O", { buffer = bufnr })
end

require("lazy").setup({
	{
		"kiyoon/tmux-send.nvim",
		keys = {
			{ "-", "<Plug>(tmuxsend-smart)", mode = { "n", "x" } },
			{ "_", "<Plug>(tmuxsend-plain)", mode = { "n", "x" } },
			{ "<space>-", "<Plug>(tmuxsend-uid-smart)", mode = { "n", "x" } },
			{ "<space>_", "<Plug>(tmuxsend-uid-plain)", mode = { "n", "x" } },
			{ "<C-_>", "<Plug>(tmuxsend-tmuxbuffer)", mode = { "n", "x" } },
		},
	},
	"kiyoon/nvim-tree-remote.nvim",
	"folke/tokyonight.nvim",
	"nvim-tree/nvim-web-devicons",
	{
		"nvim-tree/nvim-tree.lua",
		config = function()
			local nvim_tree = require("nvim-tree")

			nvim_tree.setup({
				on_attach = nvim_tree_on_attach,
				update_focused_file = {
					enable = true,
					update_cwd = true,
				},
				renderer = {
					--root_folder_modifier = ":t",
					icons = {
						glyphs = {
							default = "",
							symlink = "",
							folder = {
								arrow_open = "",
								arrow_closed = "",
								default = "",
								open = "",
								empty = "",
								empty_open = "",
								symlink = "",
								symlink_open = "",
							},
							git = {
								unstaged = "",
								staged = "S",
								unmerged = "",
								renamed = "➜",
								untracked = "U",
								deleted = "",
								ignored = "◌",
							},
						},
					},
				},
				diagnostics = {
					enable = true,
					show_on_dirs = true,
					icons = {
						hint = "",
						info = "",
						warning = "",
						error = "",
					},
				},
				view = {
					width = 30,
					side = "left",
				},
				filters = {
					custom = { ".git" },
				},
			})
		end,
	},
	{
		"aserowy/tmux.nvim",
		config = function()
			-- Navigate tmux, and nvim splits.
			-- Sync nvim buffer with tmux buffer.
			require("tmux").setup({
				copy_sync = {
					enable = true,
					sync_clipboard = false,
					sync_registers = true,
				},
				resize = {
					enable_default_keybindings = false,
				},
			})
		end,
	},
}, {
	performance = {
		rtp = {
			disabled_plugins = {
				-- List of default plugins can be found here
				-- https://github.com/neovim/neovim/tree/master/runtime/plugin
				"gzip",
				"matchit", -- Extended %. replaced by vim-matchup
				"matchparen", -- Highlight matching paren. replaced by vim-matchup
				"netrwPlugin", -- File browser. replaced by nvim-tree, neo-tree, oil.nvim
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})

--vim.cmd([[ colorscheme tokyonight-night ]])
vim.o.cursorline = true

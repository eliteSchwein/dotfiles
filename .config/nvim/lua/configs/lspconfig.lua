local configs = require("nvchad.configs.lspconfig")

local servers = {
	ansiblels = {
		settings = {
			ansible = {
				path = "ansible",
			},
			validation = {
				enabled = true,
				lint = {
					enabled = true,
					path = "ansible-lint",
				},
			},
		},
	},
	dockerls = {},
	pyright = {},
	terraformls = {},
	helm_ls = {
		settings = {
			["helm-ls"] = {
				yamlls = {
					path = "yaml-language-server",
				},
			},
		},
	},
	gopls = {},
	lua_ls = {},
	marksman = {},
	nil_ls = {},
	yamlls = require("yaml-companion").setup({
		builtin_matchers = {
			kubernetes = { enabled = true },
		},

		schemas = {
			-- not loaded automatically, manually select with
			-- :Telescope yaml_schema
			{
				name = "Argo CD Application",
				uri = "https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/argoproj.io/application_v1alpha1.json",
			},
		},
		lspconfig = {
			settings = {
				yaml = {
					validate = true,
					schemasStore = {
						enabled = false,
						url = "",
					},
					schemas = require("schemastore").yaml.schemas({
						select = {
							"kustomization.yaml",
							"Renovate",
							"gitlab-ci",
						},
						extra = {
							url = "https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/playbook",
							name = "Ansible Playbook",
							fileMatch = "ansible/*.{yml,yaml}",
						},
					}),
				},
			},
		},
	}),
}

for name, opts in pairs(servers) do
	opts.on_init = configs.on_init
	opts.on_attach = configs.on_attach
	opts.capabilities = configs.capabilities

	vim.lsp.config(name, {
		cmd = opts.cmd,
		root_markers = opts.root_dir,
		filetypes = opts.filetypes,
		settings = opts.settings,
		on_init = opts.on_init,
		on_attach = opts.on_attach,
		capabilities = opts.capabilities,
	})
	vim.lsp.enable(name)
end

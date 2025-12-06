.PHONY: chores style lint test help

.DEFAULT_GOAL := help

PROJECT_NAME = babel.nvim

# Dependencies for future tests
MINITEST = deps/mini.test

################################################################################
##@ Development

chores: style lint  ## Run all checks (style, lint)

style:  ## Check code formatting with stylua
	stylua --check .

lint:  ## Lint code with selene and typos
	selene lua/ || ([ $$? -eq 1 ] && echo "Warnings only" || exit 1)
	typos lua/ || true

test: $(MINITEST)  ## Run tests with mini.test
	nvim --headless --noplugin -u ./scripts/minimal_init.lua \
		-c "lua MiniTest.run()"

$(MINITEST):
	mkdir -p deps
	git clone --filter=blob:none https://github.com/echasnovski/mini.test $(MINITEST)

################################################################################
##@ Helpers

version:  ## Print plugin version
	@nvim --headless -c 'lua print("v" .. require("babel").VERSION)' -c q 2>&1

clean:  ## Clean dependencies
	rm -rf deps/

help:  ## Show this help
	@echo "Welcome to $(PROJECT_NAME) 🌍"
	@echo ""
	@echo "To get started:"
	@echo "  >>> make chores"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "\033[36m\033[0m"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

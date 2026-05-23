# Makefile — day-to-day interface for this dotfiles repo.
# Run `make help` to see available targets.

DOTFILES_DIR := $(CURDIR)
EXCLUDE      := .git .github .claude
PACKAGES     := $(filter-out $(EXCLUDE),$(patsubst %/,%,$(wildcard */)))

STOW         := stow --target=$(HOME) --dir=$(DOTFILES_DIR)

SKETCHYBAR_FONT_CASK := font-sketchybar-app-font
SKETCHYBAR_ICON_MAP  := $(DOTFILES_DIR)/sketchybar/.config/sketchybar/icon_map.sh

.DEFAULT_GOAL := help
.PHONY: help install brew restow stow unstow check status clean sketchybar-icon-map

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n\nTargets:\n"} \
		/^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

install: brew restow ## Full bootstrap: brew bundle + stow everything

brew: ## Install/update Homebrew deps from Brewfile
	@brew bundle --file=$(DOTFILES_DIR)/Brewfile

restow: ## Re-symlink every package (idempotent)
	@echo "Restowing: $(PACKAGES)"
	@$(STOW) --restow $(PACKAGES)

stow: ## Stow a single package: make stow PKG=nvim
	@test -n "$(PKG)" || { echo "Usage: make stow PKG=<name>"; exit 1; }
	@$(STOW) $(PKG)

unstow: ## Unstow a single package: make unstow PKG=nvim
	@test -n "$(PKG)" || { echo "Usage: make unstow PKG=<name>"; exit 1; }
	@$(STOW) -D $(PKG)

check: ## Dry-run stow + check Brewfile dependencies
	@echo "==> stow dry run"
	@$(STOW) -n -v --restow $(PACKAGES) || true
	@echo
	@echo "==> brew bundle check"
	@brew bundle check --file=$(DOTFILES_DIR)/Brewfile --verbose || true

status: ## List discovered packages
	@echo "Dotfiles dir: $(DOTFILES_DIR)"
	@echo "Target:       $(HOME)"
	@echo "Packages:     $(PACKAGES)"

clean: ## Unstow every package (removes all symlinks)
	@echo "Unstowing: $(PACKAGES)"
	@$(STOW) -D $(PACKAGES)

sketchybar-icon-map: ## Refresh sketchybar app-font icon map to match installed cask version
	@v=$$(brew list --cask --versions $(SKETCHYBAR_FONT_CASK) 2>/dev/null | awk '{print $$2}'); \
	if [ -z "$$v" ]; then \
	  echo "$(SKETCHYBAR_FONT_CASK) not installed; run: brew install --cask $(SKETCHYBAR_FONT_CASK)" >&2; \
	  exit 1; \
	fi; \
	url="https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v$$v/icon_map.sh"; \
	echo "==> fetching $$url"; \
	curl -sSfL "$$url" -o "$(SKETCHYBAR_ICON_MAP)" && \
	echo "Wrote $(SKETCHYBAR_ICON_MAP) (v$$v) — review with git diff, then reload sketchybar"

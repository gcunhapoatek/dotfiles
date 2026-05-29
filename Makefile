# Makefile — day-to-day interface for this dotfiles repo.
# Run `make help` to see available targets.

DOTFILES_DIR := $(CURDIR)
EXCLUDE      := .git .github .claude scripts
PACKAGES     := $(filter-out $(EXCLUDE),$(patsubst %/,%,$(wildcard */)))

STOW         := stow --target=$(HOME) --dir=$(DOTFILES_DIR)

# --- Output styling -------------------------------------------------------
# Colors are disabled automatically when stdout is not a TTY or NO_COLOR is set.
ifeq ($(strip $(NO_COLOR)),)
  ifeq ($(shell test -t 1 && echo tty),tty)
    C_RESET  := \033[0m
    C_BOLD   := \033[1m
    C_DIM    := \033[2m
    C_BLUE   := \033[36m
    C_GREEN  := \033[32m
    C_YELLOW := \033[33m
    C_RED    := \033[31m
  endif
endif

OK    := $(C_GREEN)✓$(C_RESET)
FAIL  := $(C_RED)✗$(C_RESET)
ARROW := $(C_BLUE)▸$(C_RESET)

# $(call banner,Title) — print a bold section header.
define banner
	@printf "\n$(C_BOLD)$(C_BLUE)══ %s ══$(C_RESET)\n" "$(1)"
endef

# $(call count,N) — print a dim package count.
define count
	@printf "$(C_DIM)%s package(s)$(C_RESET)\n\n" "$(1)"
endef

.DEFAULT_GOAL := help
.PHONY: help install brew restow stow unstow check status clean sketchybar-icon-map

help: ## Show this help
	@printf "$(C_BOLD)Usage:$(C_RESET) make $(C_BLUE)<target>$(C_RESET)\n\n$(C_BOLD)Targets:$(C_RESET)\n"
	@awk 'BEGIN {FS = ":.*##"} \
		/^[a-zA-Z_-]+:.*?##/ { printf "  $(C_BLUE)%-20s$(C_RESET) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf "\n$(C_DIM)Discovered packages: $(words $(PACKAGES))$(C_RESET)\n"

install: brew restow ## Full bootstrap: brew bundle + stow everything
	$(call banner,Bootstrap complete)
	@printf "  $(OK) Homebrew deps installed\n  $(OK) $(words $(PACKAGES)) package(s) stowed\n"

brew: ## Install/update Homebrew deps from Brewfile
	$(call banner,Homebrew bundle)
	@brew bundle --file=$(DOTFILES_DIR)/Brewfile \
		&& printf "  $(OK) Brewfile satisfied\n" \
		|| { printf "  $(FAIL) brew bundle failed\n"; exit 1; }

restow: ## Re-symlink every package (idempotent)
	$(call banner,Restow)
	$(call count,$(words $(PACKAGES)))
	@fail=0; for pkg in $(PACKAGES); do \
		if err=$$($(STOW) --restow "$$pkg" 2>&1); then \
			printf "  $(OK) %s\n" "$$pkg"; \
		else \
			printf "  $(FAIL) %s\n" "$$pkg"; \
			printf "$(C_DIM)%s$(C_RESET)\n" "$$err" | sed 's/^/      /'; \
			fail=1; \
		fi; \
	done; \
	[ $$fail -eq 0 ] && printf "\n  $(C_GREEN)All packages stowed.$(C_RESET)\n" \
		|| { printf "\n  $(C_RED)Some packages failed — see above.$(C_RESET)\n"; exit 1; }

stow: ## Stow a single package: make stow PKG=nvim
	@test -n "$(PKG)" || { printf "$(FAIL) Usage: make stow PKG=<name>\n"; exit 1; }
	@$(STOW) "$(PKG)" \
		&& printf "  $(OK) stowed $(C_BOLD)$(PKG)$(C_RESET)\n" \
		|| { printf "  $(FAIL) failed to stow $(PKG)\n"; exit 1; }

unstow: ## Unstow a single package: make unstow PKG=nvim
	@test -n "$(PKG)" || { printf "$(FAIL) Usage: make unstow PKG=<name>\n"; exit 1; }
	@$(STOW) -D "$(PKG)" \
		&& printf "  $(OK) unstowed $(C_BOLD)$(PKG)$(C_RESET)\n" \
		|| { printf "  $(FAIL) failed to unstow $(PKG)\n"; exit 1; }

check: ## Dry-run stow + check Brewfile dependencies
	$(call banner,Stow dry-run)
	$(call count,$(words $(PACKAGES)))
	@for pkg in $(PACKAGES); do \
		if err=$$($(STOW) -n --restow "$$pkg" 2>&1); then \
			printf "  $(OK) %s\n" "$$pkg"; \
		else \
			printf "  $(YELLOW)!$(C_RESET) %s $(C_DIM)(conflict)$(C_RESET)\n" "$$pkg"; \
			printf "$(C_DIM)%s$(C_RESET)\n" "$$err" | sed 's/^/      /'; \
		fi; \
	done
	$(call banner,Brewfile check)
	@brew bundle check --file=$(DOTFILES_DIR)/Brewfile --verbose \
		&& printf "  $(OK) all dependencies present\n" \
		|| printf "  $(YELLOW)!$(C_RESET) missing dependencies — run $(C_BOLD)make brew$(C_RESET)\n"

status: ## List discovered packages
	$(call banner,Status)
	@printf "  $(ARROW) Dotfiles dir : $(C_BOLD)$(DOTFILES_DIR)$(C_RESET)\n"
	@printf "  $(ARROW) Target       : $(C_BOLD)$(HOME)$(C_RESET)\n"
	@printf "  $(ARROW) Packages     : $(C_BOLD)$(words $(PACKAGES))$(C_RESET)\n\n"
	@for pkg in $(PACKAGES); do printf "      $(C_DIM)•$(C_RESET) %s\n" "$$pkg"; done

clean: ## Unstow every package (removes all symlinks)
	$(call banner,Clean — removing all symlinks)
	$(call count,$(words $(PACKAGES)))
	@for pkg in $(PACKAGES); do \
		if err=$$($(STOW) -D "$$pkg" 2>&1); then \
			printf "  $(OK) %s\n" "$$pkg"; \
		else \
			printf "  $(FAIL) %s\n" "$$pkg"; \
			printf "$(C_DIM)%s$(C_RESET)\n" "$$err" | sed 's/^/      /'; \
		fi; \
	done

sketchybar-icon-map: ## Refresh sketchybar app-font icon map from latest upstream release
	$(call banner,Refresh sketchybar icon map)
	@$(DOTFILES_DIR)/scripts/refresh-sketchybar-icon-map.sh \
		&& printf "  $(OK) icon map refreshed\n" \
		|| { printf "  $(FAIL) refresh failed\n"; exit 1; }

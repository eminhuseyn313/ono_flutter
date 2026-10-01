# ─────────────────────────────────────────────────────────────
# ONO — Developer Makefile
# Usage:  make <command>      (run from project root)
# ─────────────────────────────────────────────────────────────

.PHONY: help run run-prod ios android web build clean test test-watch \
        test-feature analyze format fix deps upgrade doctor check ci \
        coverage gen loc

# ─── Default: show help ──────────────────────────────────────
help: ## Show all available commands
	@echo ""
	@echo "  ╔══════════════════════════════════════════════╗"
	@echo "  ║          🟣  ONO Developer CLI  🟣           ║"
	@echo "  ╚══════════════════════════════════════════════╝"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
	@echo ""

# ─── Run ─────────────────────────────────────────────────────
run: ## Run app (mock/offline mode)
	flutter run lib/main.dart

run-prod: ## Run app (Supabase/production mode)
	flutter run lib/main_production.dart

ios: ## Run on iOS simulator
	flutter run lib/main.dart -d iPhone

android: ## Run on Android emulator
	flutter run lib/main.dart -d emulator

web: ## Run in Chrome browser
	flutter run lib/main.dart -d chrome

# ─── Build ───────────────────────────────────────────────────
build: ## Build release APK
	flutter build apk --release

build-ios: ## Build iOS release
	flutter build ios --release

build-web: ## Build web release
	flutter build web --release

# ─── Test ────────────────────────────────────────────────────
test: ## Run all tests (pretty output)
	@bash scripts/test_runner.sh

test-quick: ## Run tests (plain output, fast)
	flutter test

test-watch: ## Watch files and re-run tests on change
	@echo "Watching for changes... (Ctrl+C to stop)"
	@while true; do \
		flutter test --reporter compact 2>&1; \
		echo "\n⏳ Waiting for changes..."; \
		sleep 3; \
	done

test-feature: ## Run tests for one feature (e.g. make test-feature F=ai_coach)
	@if [ -z "$(F)" ]; then \
		echo "Usage: make test-feature F=<feature_name>"; \
		echo "Example: make test-feature F=ai_coach"; \
		echo ""; \
		echo "Available test files:"; \
		find test -name "*_test.dart" -exec basename {} \; | sed 's/_test.dart//' | sort; \
		exit 1; \
	fi
	@echo "🧪 Testing: $(F)"
	@flutter test test/**/$(F)*_test.dart --reporter expanded

test-providers: ## Run all provider tests
	flutter test test/ --reporter expanded --name "Provider"

coverage: ## Generate test coverage report
	flutter test --coverage
	@if command -v genhtml > /dev/null 2>&1; then \
		genhtml coverage/lcov.info -o coverage/html; \
		echo "📊 Coverage report: coverage/html/index.html"; \
		open coverage/html/index.html 2>/dev/null || true; \
	else \
		echo "📊 Coverage data: coverage/lcov.info"; \
		echo "   Install lcov for HTML report: brew install lcov"; \
	fi

# ─── Code Quality ───────────────────────────────────────────
analyze: ## Run Dart static analysis
	flutter analyze

format: ## Check formatting (dry run)
	dart format --output=show --set-exit-if-changed lib/ test/

fix: ## Auto-fix formatting + analysis issues
	dart format lib/ test/
	dart fix --apply

# ─── Dependencies ────────────────────────────────────────────
deps: ## Get all dependencies
	flutter pub get

upgrade: ## Upgrade dependencies
	flutter pub upgrade

outdated: ## Show outdated packages
	flutter pub outdated

# ─── Utilities ───────────────────────────────────────────────
clean: ## Clean build artifacts
	flutter clean
	@rm -rf build/ .dart_tool/ .packages
	@echo "✅ Cleaned"

doctor: ## Check Flutter environment
	flutter doctor -v

gen: ## Run build_runner code generation
	flutter pub run build_runner build --delete-conflicting-outputs

loc: ## Count lines of code
	@echo ""
	@echo "📊 ONO Lines of Code"
	@echo "────────────────────────────────────"
	@echo "  Models:     $$(find lib/models -name '*.dart' | xargs cat 2>/dev/null | wc -l | tr -d ' ')"
	@echo "  Gateways:   $$(find lib/gateways -name '*.dart' | xargs cat 2>/dev/null | wc -l | tr -d ' ')"
	@echo "  Providers:  $$(find lib/providers -name '*.dart' | xargs cat 2>/dev/null | wc -l | tr -d ' ')"
	@echo "  Screens:    $$(find lib/screens -name '*.dart' | xargs cat 2>/dev/null | wc -l | tr -d ' ')"
	@echo "  Widgets:    $$(find lib/widgets -name '*.dart' | xargs cat 2>/dev/null | wc -l | tr -d ' ')"
	@echo "  Tests:      $$(find test -name '*.dart' | xargs cat 2>/dev/null | wc -l | tr -d ' ')"
	@echo "────────────────────────────────────"
	@echo "  Total:      $$(find lib test -name '*.dart' | xargs cat 2>/dev/null | wc -l | tr -d ' ')"
	@echo ""

# ─── CI / Pre-push check ────────────────────────────────────
check: ## Quick pre-push check (analyze + format + test)
	@echo "🔍 Running pre-push checks..."
	@echo ""
	@echo "1/3 ▸ Analyzing..."
	@flutter analyze --no-fatal-infos || exit 1
	@echo ""
	@echo "2/3 ▸ Checking format..."
	@dart format --output=none --set-exit-if-changed lib/ test/ || exit 1
	@echo ""
	@echo "3/3 ▸ Running tests..."
	@flutter test --reporter compact || exit 1
	@echo ""
	@echo "✅ All checks passed — safe to push!"

ci: ## Full CI pipeline (clean + deps + check)
	@$(MAKE) clean
	@$(MAKE) deps
	@$(MAKE) check

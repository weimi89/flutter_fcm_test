.PHONY: clean
clean: ## 清理環境並安裝相依套件
	@echo "╠ 清理專案..."
	@rm -rf pubspec.lock
	@flutter clean
	@flutter pub get

clean: ## 清理環境
	@echo "╠ 清理專案..."
	@rm -rf pubspec.lock
	@flutter clean

.PHONY: pub_get
pub_get: ## 執行 flutter pub get
	@echo "👟 正在執行 Flutter pub get..."
	@flutter pub get

.PHONY: dart-fix-dry-run
dart-fix-dry-run: ## 執行 dart fix
	@echo "🔧 正在執行 Dart fix (dry run)..."
	@dart fix --dry-run

.PHONY: dart-fix-apply
dart-fix-apply: ## 執行 dart fix 並應用更改
	@echo "🔧 正在執行 Dart fix (apply)"
	@dart fix --apply

.PHONY: build-apk
build-apk: ## 建置 APK 應用程式
	@echo "🏗️ 正在建置專案..."
	@flutter build apk --release --split-per-abi --no-tree-shake-icons

.PHONY: build-aab
build-aab: ## 建置 AAB 應用程式
	@echo "🏗️ 正在建置專案..."
	@flutter build appbundle --release --no-tree-shake-icons

.PHONY: build-ios
build-ios: ## 建置 iOS 應用程式
	@echo "🏗️ 正在建置專案..."
	@flutter build ios --release --no-codesign

.PHONY: run-dev
run-dev: ## 在 debug 模式執行應用程式
	@echo "🚀 正在執行專案..."
	@flutter run --dart-define=FLUTTER_DOTENV_CONFIG=debug

.PHONY: run-staging
run-staging: ## 在 staging 模式下執行應用程式
	@echo "🚀 正在執行專案..."
	@flutter run --dart-define=FLUTTER_DOTENV_CONFIG=staging

.PHONY: run-release
run-release: ## 在 release 模式下執行應用程式
	@echo "🚀 正在執行專案..."
	@flutter run --release

.PHONY: test
test: ## 執行測試
	@echo "🧪 正在執行測試..."
	@flutter test

.PHONY: help
help: ## 顯示此幫助訊息
	@echo "📜 使用方式:"
	@echo "  make <target>"
	@echo ""
	@echo "🎯 目標:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ""
	@echo "📦 依賴:"
	@echo "  Flutter: $(shell flutter --version)"
	@echo "  Dart: $(shell dart --version)"

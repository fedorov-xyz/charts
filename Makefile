CHARTS := redis
PACKAGES_DIR := packages
OCI_REGISTRY ?= ghcr.io
OCI_OWNER    ?= fedorov-xyz
OCI_REPO     ?= oci://$(OCI_REGISTRY)/$(OCI_OWNER)/charts
LINT_VALUES  := -f redis/ci/lint-values.yaml
HELM         := helm

.PHONY: lint lint-helm lint-yaml lint-kubeconform template package push login clean

lint: lint-helm lint-yaml lint-kubeconform

lint-helm:
	@for chart in $(CHARTS); do \
		echo "==> helm lint $$chart"; \
		$(HELM) lint "$$chart" --strict $(LINT_VALUES); \
	done

lint-yaml:
	@echo "==> yamllint"
	@yamllint -d relaxed redis/values.yaml redis/Chart.yaml redis/ci/

lint-kubeconform: template
	@echo "==> kubeconform"
	@kubeconform -summary -ignore-missing-schemas /tmp/charts-rendered.yaml

template:
	@echo "==> helm template"
	@$(HELM) template redis redis $(LINT_VALUES) --namespace default \
		> /tmp/charts-rendered.yaml

package: lint
	@mkdir -p $(PACKAGES_DIR)
	@for chart in $(CHARTS); do \
		$(HELM) package "$$chart" -d $(PACKAGES_DIR); \
	done

login:
	@test -n "$$GITHUB_TOKEN" || { echo "GITHUB_TOKEN is required"; exit 1; }
	@echo "$$GITHUB_TOKEN" | $(HELM) registry login $(OCI_REGISTRY) \
		-u "$(OCI_OWNER)" --password-stdin

push: package
	@for chart in $(CHARTS); do \
		version=$$(awk '/^version:/{print $$2; exit}' "$$chart/Chart.yaml"); \
		$(HELM) push "$(PACKAGES_DIR)/$$chart-$$version.tgz" "$(OCI_REPO)"; \
	done

clean:
	rm -rf $(PACKAGES_DIR) /tmp/charts-rendered.yaml

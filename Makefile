# SPDX-License-Identifier: GPL-3.0-or-later
ENGINE ?= podman
IMAGE_NAME ?= kepler-ostree-builder:latest
OSTREE_BRANCH ?= kepler/testing/x86_64-v3/gnome
GHCR_USER ?= antux912012
GHCR_IMAGE ?= ghcr.io/$(GHCR_USER)/kepler-os-immutable:testing-x86_64-v3
CONTAINER_RUN = $(ENGINE) run --rm --privileged -v $(CURDIR):/workspace:Z

.PHONY: help init-tree builder mok-keys ostree-commit sbom scan-cve iso oci-bootc test-iso test-installed test-cpu-fail test-rollback test-tpm2-luks spdx-headers git-hooks compliance all clean

all: help

help:
	@echo "================================================================================"
	@echo " KEPLER OS IMMUTABLE (x86-64-v3 / OSTree) - MASTER BUILD & QA TARGETS (STE100)"
	@echo "================================================================================"
	@echo " [BUILD & IMAGE PIPELINE]"
	@echo "  make init-tree       Initialize the immutable OSTree and Live-Build directory tree."
	@echo "  make builder         Build the isolated Debian Testing container image."
	@echo "  make ostree-commit   Assemble the rootfs and commit to the local OSTree repo."
	@echo "  make iso             Package the bootable Live ISO with embedded OSTree repo."
	@echo "  make oci-bootc       Encapsulate the OSTree commit into an OCI bootc archive."
	@echo ""
	@echo " [SUPPLY-CHAIN SECURITY & CRYPTOGRAPHY]"
	@echo "  make mok-keys        Generate RSA-4096 UEFI Secure Boot MOK signing keys."
	@echo "  make sbom            Generate SPDX 2.3 and CycloneDX 1.5 JSON SBOM manifests."
	@echo "  make scan-cve        Scan SBOMs with Trivy and Grype (blocks fixable CRITICAL CVEs)."
	@echo ""
	@echo " [QEMU/KVM HARDWARE & ROLLBACK VERIFICATION]"
	@echo "  make test-iso        Boot the Live ISO in QEMU/KVM (Haswell-v4 + OVMF Secure Boot)."
	@echo "  make test-installed  Boot the installed NVMe image and verify read-only /usr."
	@echo "  make test-cpu-fail   Verify the x86-64-v3 AVX2 hardware gate rejects legacy CPUs."
	@echo "  make test-rollback   Test atomic ostree admin upgrade and rollback in QEMU/KVM."
	@echo "  make test-tpm2-luks  Test unattended TPM 2.0 (PCR 7+14) LUKS2 unlock via swtpm."
	@echo ""
	@echo " [GOVERNANCE & EU REGULATORY COMPLIANCE]"
	@echo "  make spdx-headers    Prepend SPDX GPL-3.0-or-later headers across all source files."
	@echo "  make git-hooks       Install local Git pre-commit (SPDX) and commit-msg (DCO) hooks."
	@echo "  make compliance      Apply SPDX headers, install Git hooks, and update README CRA table."
	@echo "  make clean           Remove staging directories, build artifacts, and test states."
	@echo "================================================================================"

init-tree:
	chmod +x ./init-tree.sh
	./init-tree.sh

builder:
	$(ENGINE) build -t $(IMAGE_NAME) -f Containerfile .

mok-keys:
	$(CONTAINER_RUN) --entrypoint /bin/bash $(IMAGE_NAME) -c "/workspace/scripts/generate-mok-keys.sh"

ostree-commit: mok-keys
	$(CONTAINER_RUN) --entrypoint /workspace/build-ostree-commit.sh $(IMAGE_NAME)

sbom:
	$(CONTAINER_RUN) --entrypoint /workspace/scripts/generate-kepler-sbom.sh $(IMAGE_NAME)

scan-cve:
	$(CONTAINER_RUN) --entrypoint /workspace/scripts/scan-kepler-sbom-cve.sh $(IMAGE_NAME)

iso:
	mkdir -p build_out
	$(CONTAINER_RUN) $(IMAGE_NAME)
	./scripts/verify-release-sbom.sh build_out

oci-bootc: ostree-commit
	$(CONTAINER_RUN) -e GHCR_USER="$(GHCR_USER)" -e GHCR_TOKEN="$(GHCR_TOKEN)" -e GHCR_IMAGE="$(GHCR_IMAGE)" --entrypoint /workspace/export-ostree-oci.sh $(IMAGE_NAME)

test-iso:
	$(CONTAINER_RUN) --entrypoint /workspace/scripts/test-iso-qemu.sh $(IMAGE_NAME) $(ARGS)

test-installed:
	$(CONTAINER_RUN) --entrypoint /workspace/scripts/test-iso-qemu.sh $(IMAGE_NAME) --boot-installed $(ARGS)

test-cpu-fail:
	$(CONTAINER_RUN) --entrypoint /workspace/scripts/test-iso-qemu.sh $(IMAGE_NAME) --legacy-cpu $(ARGS)

test-rollback:
	$(CONTAINER_RUN) --entrypoint /workspace/scripts/test-ostree-rollback-qemu.sh $(IMAGE_NAME) $(ARGS)

test-tpm2-luks:
	$(CONTAINER_RUN) --entrypoint /workspace/scripts/test-tpm2-luks-qemu.sh $(IMAGE_NAME) $(ARGS)

spdx-headers:
	chmod +x ./scripts/apply-spdx-headers.sh
	./scripts/apply-spdx-headers.sh

git-hooks:
	chmod +x ./scripts/install-git-hooks.sh
	./scripts/install-git-hooks.sh

compliance: spdx-headers git-hooks
	chmod +x ./scripts/update-readme-compliance-table.sh
	./scripts/update-readme-compliance-table.sh

clean:
	rm -rf work/ rootfs_staging/ profile/config/includes.chroot/ostree-repo/* build_out/*.iso build_out/*.tar build_out/*.json build_out/*.sarif build_out/swtpm-state

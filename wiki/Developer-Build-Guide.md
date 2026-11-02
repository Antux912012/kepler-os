# Developer Build and Testing Guide

All build actions run inside an isolated Podman container.
This guarantees reproducible builds and protects the host system.

## 1. Build Procedure

```bash
# 1. Initialize directory tree
make init-tree

# 2. Build isolated Debian Testing container
make builder

# 3. Generate UEFI Secure Boot MOK keys
make mok-keys

# 4. Assemble rootfs and commit to local OSTree repository
make ostree-commit

# 5. Generate SBOM manifests (SPDX 2.3 and CycloneDX 1.5)
make sbom

# 6. Scan SBOM manifests for vulnerabilities
make scan-cve

# 7. Package bootable Live ISO
make iso
```

## 2. Automated QA Verification in QEMU/KVM

```bash
# Test Live ISO boot with Haswell-v4 and OVMF Secure Boot
make test-iso

# Test deployed OSTree image and verify read-only /usr
make test-installed

# Verify the hardware gate blocks non-AVX2 CPUs
make test-cpu-fail

# Test atomic upgrade and rollback sequence
make test-rollback

# Test unattended TPM 2.0 (swtpm) LUKS2 auto-unlock
make test-tpm2-luks
```

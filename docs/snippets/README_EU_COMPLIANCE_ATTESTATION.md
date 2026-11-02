![EU AI Act Art. 50 Compliant](https://img.shields.io/badge/EU_AI_Act-Article_50_Transparent-88C0D0?style=for-the-badge&logo=europeanunion&logoColor=white)
![EU CRA Open-Source Steward](https://img.shields.io/badge/EU_CRA_2024%2F2847-SBOM_%26_CVD_Compliant-A3BE8C?style=for-the-badge&logo=linux&logoColor=white)

## EUROPEAN UNION REGULATORY & SUPPLY-CHAIN ATTESTATION (ASD-STE100)

| Regulation / Standard | Article / Annex | Kepler OS Immutable Technical Control | Verification Artifact / Command |
| :--- | :--- | :--- | :--- |
| **EU AI Act (Reg. EU 2024/1689)** | Article 50 (AI Transparency) | Discloses AI-assisted build code generation and mandates local-only execution for Arda-Tech AI runtimes (*Sulimo* / *Elrond Assistance*) with zero cloud telemetry. | `NOTICE.md`, `.github/workflows/lint-pr-compliance.yml` |
| **EU Cyber Resilience Act (Reg. EU 2024/2847)** | Annex I, Part II (SBOM) | Generates machine-readable **SPDX 2.3 (`.spdx.json`)** and **CycloneDX 1.5 (`.cdx.json`)** Software Bills of Materials for every OSTree commit and Live ISO. | `make sbom`, `scripts/verify-release-sbom.sh` |
| **EU Cyber Resilience Act (Reg. EU 2024/2847)** | Annex I, Part II (Vulnerability Handling) | Scans every release SBOM with **Trivy** and **Grype**, blocks fixable `CRITICAL` CVEs, and uploads SARIF 2.1.0 reports to GitHub Code Scanning. | `make scan-cve`, `kepler-cve-trivy.sarif` |
| **EU Cyber Resilience Act (Reg. EU 2024/2847)** | Article 24 (Coordinated Vulnerability Disclosure) | Establishes a 48-hour acknowledgment and 14-day patch window via GitHub Private Vulnerability Reporting and GPG-encrypted advisories. | `SECURITY.md` |
| **EU Cyber Resilience Act (Reg. EU 2024/2847)** | Annex I, Part I (Integrity & Secure Boot) | Enforces read-only `/usr` via **OSTree**, signs kernels with UEFI Secure Boot **MOK**, binds LUKS2 to **TPM 2.0 (PCR 7+14)**, and signs all release artifacts with GPG. | `make mok-keys`, `kepler-enroll-tpm2`, `SHA256SUMS.gpg` |
| **Outbound Licensing & Provenance** | GNU GPL v3.0 & DCO 1.1 | Enforces `SPDX-License-Identifier: GPL-3.0-or-later` headers across all files and DCO `Signed-off-by:` trailers on every commit. | `make spdx-headers`, `make git-hooks` |

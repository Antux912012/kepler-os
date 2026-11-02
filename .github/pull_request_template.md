## Summary of Changes
<!-- Provide a concise ASD-STE100 description of your changes. -->

## Compliance & Governance Checklist
- [ ] **SPDX Headers:** All new scripts/files contain `SPDX-License-Identifier: GPL-3.0-or-later`.
- [ ] **DCO 1.1 Sign-Off:** All commits contain `Signed-off-by: Author <email>` (`git commit -s`).
- [ ] **Microarchitecture Compliance:** Changes comply with the `x86-64-v3` baseline.
- [ ] **Immutability Protection:** No writes to read-only `/usr` outside build-time OSTree recipes.
- [ ] **Testing:** Verified inside the container (`make builder && make sbom && make scan-cve`).

## EU AI Act Disclosure (Article 50)
- AI-Assisted Development: [ ] No | [ ] Yes (Model: ________________)
<!-- If yes, specify how AI code was verified and tested before submission. -->

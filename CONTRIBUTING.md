# Kepler OS Contributor Guidelines (ASD-STE100)

## 1. Code of Conduct & Scope
All contributions must target the `x86-64-v3` architecture baseline, Debian Testing, GNOME 50+, or the `kepler-tuner` system stack.
Write modular, secure, and reproducible code.

## 2. ASD-STE100 Documentation Requirement
All documentation, code comments, commit messages, and Pull Request descriptions must obey the **ASD-STE100 (Simplified Technical English)** standard:
1. Write one instruction per sentence.
2. Use active voice and imperative verbs (for example: *Add*, *Fix*, *Verify*, *Remove*).
3. Keep sentences under 20 words for procedural steps.
4. Avoid idioms and ambiguous marketing terms.

## 3. Developer Certificate of Origin (DCO 1.1) & Licensing
Every commit must include a `Signed-off-by:` trailer (`git commit -s`).
This certifies compliance with the **Developer Certificate of Origin (DCO 1.1)**.
All contributions are licensed under the **GNU General Public License v3.0 or later (`GPL-3.0-or-later`)**.
Prepend the `SPDX-License-Identifier: GPL-3.0-or-later` header to every new file.

## 4. European Union AI Act Disclosure (Regulation EU 2024/1689)
Contributors who use AI coding assistants or Large Language Models must disclose AI usage in their Pull Request description:
```markdown
AI-Assisted: Yes (<Model Name>)
```
Verify and test all code inside the isolated container before submitting a PR:
```bash
make builder && make sbom && make scan-cve
```

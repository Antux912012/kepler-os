# Welcome to the Kepler OS Documentation Wiki

Kepler OS is an immutable atomic workstation based on Debian Testing, OSTree, and the CachyOS BORE kernel.

## Wiki Table of Contents
1. [[Architecture and x86-64-v3 Specification|Architecture-and-x86_64-v3-Spec]]
2. [[Developer Build Guide|Developer-Build-Guide]]
3. [[Scientific Stack and Kepler Tuner Guide|Scientific-Stack-and-Kepler-Tuner]]
4. [[Legal Notices, EU AI Act, and Credits|Legal-EU-AI-Act-and-Credits]]

## Minimum Hardware Requirements
| Component | Minimum Specification | Recommended |
| :--- | :--- | :--- |
| **Processor** | Intel Haswell (4th Gen) or AMD Excavator (AVX2 required) | 8+ Cores with AVX2/FMA support |
| **System Memory** | 4 GB RAM | 16 GB+ for Cytoscape and genomics workflows |
| **Storage** | 20 GB NVMe or SATA SSD | 64 GB+ NVMe with Btrfs compression |
| **Firmware** | UEFI with Secure Boot support | TPM 2.0 security chip |

## Official Distribution Channels
- **Voyager-OSTree Remote:** `https://ostree.voyager-project.org/repo`
- **Voyager-PPA Mirror:** `https://ppa.voyager-project.org/debian`
- **Voyager-Flatpak Remote:** `https://flatpak.voyager-project.org/repo`

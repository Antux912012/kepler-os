# Kepler OS Security Policy

## 1. Supported Versions
Kepler OS is an immutable rolling-release distribution based on Debian Testing (`x86-64-v3`).
Security updates are delivered exclusively for:
- The latest active rolling snapshot
- The latest `linux-cachyos-bore-v3` kernel packages in Voyager-PPA
- Active Flatpak applications in Voyager-Flatpak

## 2. Vulnerability Scope
The following components are in scope:
- `kepler-tuned` D-Bus daemon and root helper actions
- Polkit authorization policy (`org.voyager.KeplerTuned.policy`)
- UEFI Secure Boot MOK generation and signing infrastructure
- Voyager-PPA and Voyager-Flatpak repository signature generation
- Container build boundaries and privileges

## 3. Reporting a Vulnerability
Do not report security vulnerabilities in public GitHub issues.
Use **GitHub Private Vulnerability Reporting**:
1. Open the **Security** tab in the repository.
2. Select **Advisories** and click **Report a vulnerability**.
3. Include reproduction steps, environment details, and affected components.

### Coordinated Vulnerability Disclosure (CRA EU 2024/2847)
- Maintainers acknowledge reports within 48 hours.
- Security patches are developed and released within a 14-day coordinated window.

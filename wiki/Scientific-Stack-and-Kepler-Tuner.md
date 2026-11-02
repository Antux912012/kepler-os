# Scientific Computing Stack & Kepler Tuner

Kepler OS separates the base operating system from user scientific environments.

## 1. Hybrid Scientific Architecture
- **Immutable Base Layer:**
  - OpenJDK 21 Runtime
  - `cytoscape-kepler` (JVM wrapper allocating 70% of total host RAM)
  - Core Python 3 with AVX2 OpenBLAS acceleration
  - Base R
- **Mutable Workspace (kepler-science-box):**
  - Run `kepler-science-shell` to enter the container.
  - Install compiler toolchains (`gcc`, `gfortran`, `cmake`).
  - Install CRAN and Bioconductor packages with pre-compiled Debian binaries via `r2u` and `bspm`.

## 2. Kepler Tuner System Profiles
Use `kepler-tuner-gui` or the GNOME top bar Quick Settings menu to select performance modes:
1. **Silent / Mobile:**
   - Powersave governor, EPP `power`
   - NVMe APST PS4 deep sleep enabled
2. **Balanced Desktop:**
   - Default balanced profile for general daily tasks
3. **Scientific Compute:**
   - Performance CPU governor
   - Transparent HugePages (`THP`) enabled
   - Maximum memory swappiness for heavy matrix allocations

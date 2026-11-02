// SPDX-License-Identifier: GPL-3.0-or-later
mod btrfs_snapshots;

use btrfs_snapshots::BtrfsSnapshotManager;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::Path;
use std::process::Command;
use zbus::{connection, fdo, interface};

const CONFIG_PATH: &str = "/etc/kepler-tuner/config.toml";

#[derive(Debug, Serialize, Deserialize, Clone)]
struct TunerConfig {
    governor: String,
    epp: String,
    sched_ext: String,
    nvme_ps4: bool,
    thp: String,
}

impl Default for TunerConfig {
    fn default() -> Self {
        Self {
            governor: "powersave".into(),
            epp: "balance_performance".into(),
            sched_ext: "none".into(),
            nvme_ps4: true,
            thp: "madvise".into(),
        }
    }
}

struct KeplerTuned {
    config: TunerConfig,
}

impl KeplerTuned {
    fn new() -> Self {
        let config = if Path::new(CONFIG_PATH).exists() {
            fs::read_to_string(CONFIG_PATH)
                .ok()
                .and_then(|data| toml::from_str(&data).ok())
                .unwrap_or_default()
        } else {
            TunerConfig::default()
        };
        Self { config }
    }

    fn save_config(&self) {
        if let Some(parent) = Path::new(CONFIG_PATH).parent() {
            let _ = fs::create_dir_all(parent);
        }
        if let Ok(toml_str) = toml::to_string_pretty(&self.config) {
            let _ = fs::write(CONFIG_PATH, toml_str);
        }
    }
}

#[interface(name = "org.voyager.KeplerTuned1")]
impl KeplerTuned {
    async fn get_cpu_profile(&self) -> String {
        let gov = fs::read_to_string("/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor")
            .unwrap_or_else(|_| "unknown".into());
        let epp = fs::read_to_string("/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference")
            .unwrap_or_else(|_| "unknown".into());
        format!("Governor: {}, EPP: {}", gov.trim(), epp.trim())
    }

    async fn set_cpu_profile(&mut self, governor: &str, epp: &str) -> fdo::Result<()> {
        let allowed_govs = ["powersave", "performance"];
        let allowed_epps = ["power", "balance_power", "balance_performance", "performance"];

        if !allowed_govs.contains(&governor) || !allowed_epps.contains(&epp) {
            return Err(fdo::Error::InvalidArgs("Invalid governor or EPP parameter".into()));
        }

        // Apply across all online cores
        let cpus = fs::read_dir("/sys/devices/system/cpu/").map_err(|e| fdo::Error::Failed(e.to_string()))?;
        for entry in cpus.flatten() {
            let name = entry.file_name().to_string_lossy().to_string();
            if name.starts_with("cpu") && name[3..].chars().all(|c| c.is_ascii_digit()) {
                let gov_path = entry.path().join("cpufreq/scaling_governor");
                let epp_path = entry.path().join("cpufreq/energy_performance_preference");
                if gov_path.exists() {
                    let _ = fs::write(gov_path, governor);
                }
                if epp_path.exists() {
                    let _ = fs::write(epp_path, epp);
                }
            }
        }

        self.config.governor = governor.to_string();
        self.config.epp = epp.to_string();
        self.save_config();
        Ok(())
    }

    async fn set_sched_ext_profile(&mut self, scheduler: &str) -> fdo::Result<()> {
        let scx_services = ["scx_lavd", "scx_bpfland", "scx_rusty"];
        for svc in scx_services {
            let _ = Command::new("systemctl").args(["stop", &format!("{svc}.service")]).output();
        }

        if scheduler != "none" && scx_services.contains(&scheduler) {
            let _ = Command::new("systemctl").args(["start", &format!("{scheduler}.service")]).output();
        }

        self.config.sched_ext = scheduler.to_string();
        self.save_config();
        Ok(())
    }

    async fn set_storage_power_save(&mut self, enable_ps4: bool) -> fdo::Result<()> {
        let aspm_policy = if enable_ps4 { "powersave" } else { "performance" };
        let _ = fs::write("/sys/module/pcie_aspm/parameters/policy", aspm_policy);

        self.config.nvme_ps4 = enable_ps4;
        self.save_config();
        Ok(())
    }

    async fn apply_workload_preset(&mut self, preset: &str) -> fdo::Result<()> {
        match preset {
            "silent_mobile" => {
                self.set_cpu_profile("powersave", "power").await?;
                self.set_storage_power_save(true).await?;
                let _ = fs::write("/sys/kernel/mm/transparent_hugepage/enabled", "madvise");
            }
            "balanced_desktop" => {
                self.set_cpu_profile("powersave", "balance_performance").await?;
                self.set_storage_power_save(true).await?;
                let _ = fs::write("/sys/kernel/mm/transparent_hugepage/enabled", "madvise");
            }
            "scientific_compute" => {
                self.set_cpu_profile("performance", "performance").await?;
                self.set_storage_power_save(false).await?;
                let _ = fs::write("/sys/kernel/mm/transparent_hugepage/enabled", "always");
                let _ = fs::write("/proc/sys/vm/swappiness", "100");
            }
            _ => return Err(fdo::Error::InvalidArgs("Unknown workload preset".into())),
        }
        Ok(())
    }

    async fn get_ostree_status(&self) -> String {
        let output = Command::new("ostree").args(["admin", "status"]).output();
        match output {
            Ok(out) => String::from_utf8_lossy(&out.stdout).to_string(),
            Err(e) => format!("Error fetching status: {e}"),
        }
    }

    async fn trigger_ostree_upgrade(&self) -> fdo::Result<String> {
        let output = Command::new("ostree")
            .args(["admin", "upgrade"])
            .output()
            .map_err(|e| fdo::Error::Failed(e.to_string()))?;
        Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
    }

    async fn trigger_ostree_rollback(&self) -> fdo::Result<String> {
        let output = Command::new("ostree")
            .args(["admin", "deploy", "--rollback"])
            .output()
            .map_err(|e| fdo::Error::Failed(e.to_string()))?;
        Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
    }

    // Btrfs snapshot extensions
    async fn list_var_snapshots(&self) -> fdo::Result<Vec<String>> {
        BtrfsSnapshotManager::list()
    }

    async fn create_var_snapshot(&self, label: &str) -> fdo::Result<String> {
        BtrfsSnapshotManager::create(label)
    }

    async fn restore_var_snapshot(&self, snapshot_name: &str) -> fdo::Result<String> {
        BtrfsSnapshotManager::restore(snapshot_name)
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let service = KeplerTuned::new();
    let _conn = connection::Builder::system()?
        .name("org.voyager.KeplerTuned")?
        .serve_at("/org/voyager/KeplerTuned", service)?
        .build()
        .await?;

    println!("OK: KeplerTuned D-Bus daemon running on org.voyager.KeplerTuned");
    std::future::pending::<()>().await;
    Ok(())
}

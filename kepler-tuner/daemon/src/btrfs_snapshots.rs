// SPDX-License-Identifier: GPL-3.0-or-later
use regex::Regex;
use std::process::Command;
use zbus::fdo;

pub struct BtrfsSnapshotManager;

impl BtrfsSnapshotManager {
    pub fn list() -> fdo::Result<Vec<String>> {
        let output = Command::new("/usr/bin/kepler-var-snapshot")
            .arg("list")
            .output()
            .map_err(|e| fdo::Error::Failed(format!("Failed to execute kepler-var-snapshot: {e}")))?;

        let text = String::from_utf8_lossy(&output.stdout);
        let list: Vec<String> = text
            .lines()
            .filter(|l| l.starts_with(" - "))
            .map(|l| l.trim_start_matches(" - ").to_string())
            .collect();
        Ok(list)
    }

    pub fn create(label: &str) -> fdo::Result<String> {
        let re = Regex::new(r"^[a-zA-Z0-9_-]+$").unwrap();
        if !re.is_match(label) {
            return Err(fdo::Error::InvalidArgs(
                "Label must contain only alphanumeric characters, hyphens or underscores.".into(),
            ));
        }

        let output = Command::new("/usr/bin/kepler-var-snapshot")
            .arg("create")
            .arg(label)
            .output()
            .map_err(|e| fdo::Error::Failed(format!("Failed to execute kepler-var-snapshot: {e}")))?;

        if output.status.success() {
            Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
        } else {
            Err(fdo::Error::Failed(
                String::from_utf8_lossy(&output.stderr).trim().to_string(),
            ))
        }
    }

    pub fn restore(snapshot_name: &str) -> fdo::Result<String> {
        let re = Regex::new(r"^[a-zA-Z0-9_.-]+$").unwrap();
        if !re.is_match(snapshot_name) {
            return Err(fdo::Error::InvalidArgs("Invalid snapshot identifier.".into()));
        }

        let output = Command::new("/usr/bin/kepler-var-snapshot")
            .arg("restore")
            .arg(snapshot_name)
            .output()
            .map_err(|e| fdo::Error::Failed(format!("Failed to execute kepler-var-snapshot: {e}")))?;

        if output.status.success() {
            Ok("Snapshot staged. Please reboot your computer to complete restoration.".to_string())
        } else {
            Err(fdo::Error::Failed(
                String::from_utf8_lossy(&output.stderr).trim().to_string(),
            ))
        }
    }
}

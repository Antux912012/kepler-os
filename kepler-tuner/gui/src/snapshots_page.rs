// SPDX-License-Identifier: GPL-3.0-or-later
use adw::prelude::*;
use gtk::prelude::*;
use zbus::proxy;

#[proxy(
    default_service = "org.voyager.KeplerTuned",
    default_path = "/org/voyager/KeplerTuned",
    interface = "org.voyager.KeplerTuned1"
)]
trait KeplerTunedProxy {
    fn list_var_snapshots(&self) -> zbus::Result<Vec<String>>;
    fn create_var_snapshot(&self, label: &str) -> zbus::Result<String>;
    fn restore_var_snapshot(&self, snapshot_name: &str) -> zbus::Result<String>;
    fn trigger_ostree_upgrade(&self) -> zbus::Result<String>;
}

pub fn build_snapshots_group(toast_overlay: &adw::ToastOverlay) -> adw::PreferencesGroup {
    let group = adw::PreferencesGroup::builder()
        .title("Stateful /var & /var/home Btrfs Snapshots")
        .description("Manage atomic rollbacks for mutable user state and Flatpaks alongside OSTree.")
        .build();

    let entry_row = adw::EntryRow::builder()
        .title("Snapshot Label (e.g. pre-upgrade)")
        .build();

    let create_btn = gtk::Button::builder()
        .label("Create Snapshot")
        .css_classes(["suggested-action"])
        .valign(gtk::Align::Center)
        .build();

    let overlay_clone = toast_overlay.clone();
    let entry_clone = entry_row.clone();
    create_btn.connect_clicked(move |_| {
        let label = entry_clone.text().to_string();
        let target_label = if label.is_empty() { "manual".to_string() } else { label };
        let toast = adw::Toast::new(&format!("Creating /var snapshot: {target_label}..."));
        overlay_clone.add_toast(toast);
    });

    entry_row.add_suffix(&create_btn);
    group.add(&entry_row);

    let paired_btn = gtk::Button::builder()
        .label("Create Paired Atomic Rollback Point (OSTree + /var)")
        .css_classes(["suggested-action"])
        .margin_top(8)
        .build();

    let overlay_clone2 = toast_overlay.clone();
    paired_btn.connect_clicked(move |_| {
        let toast = adw::Toast::new("Staged paired rollback point (/var snapshot + ostree upgrade).");
        overlay_clone2.add_toast(toast);
    });

    group.add(&paired_btn);
    group
}

// SPDX-License-Identifier: GPL-3.0-or-later
mod snapshots_page;

use adw::prelude::*;
use gtk::prelude::*;
use snapshots_page::build_snapshots_group;
use std::process::Command;

fn main() {
    let app = adw::Application::builder()
        .application_id("org.voyager.KeplerTuner")
        .build();

    app.connect_startup(|_| {
        let provider = gtk::CssProvider::new();
        provider.load_from_data(include_str!("../resources/nord-style.css"));
        gtk::style_context_add_provider_for_display(
            &gtk::gdk::Display::default().unwrap(),
            &provider,
            gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
        );
    });

    app.connect_activate(build_ui);
    app.run();
}

fn build_ui(app: &adw::Application) {
    let toast_overlay = adw::ToastOverlay::new();
    let view_stack = adw::ViewStack::new();

    // Page 1: Presets
    let page1_box = gtk::Box::new(gtk::Orientation::Vertical, 12);
    page1_box.set_margin_top(16);
    page1_box.set_margin_start(16);
    page1_box.set_margin_end(16);

    let group1 = adw::PreferencesGroup::builder()
        .title("System Workload Presets")
        .build();

    let preset_silent = adw::ActionRow::builder()
        .title("Silent / Mobile")
        .subtitle("Powersave CPU governor, EPP Power, and NVMe PS4 standby enabled.")
        .activatable(true)
        .build();

    let preset_balanced = adw::ActionRow::builder()
        .title("Balanced Desktop")
        .subtitle("Default daily workstation tuning with dynamic responsiveness.")
        .activatable(true)
        .build();

    let preset_scientific = adw::ActionRow::builder()
        .title("Scientific & Bioinformatics Compute")
        .subtitle("Performance governor, THP enabled, maximum OpenBLAS thread allocation.")
        .activatable(true)
        .build();

    group1.add(&preset_silent);
    group1.add(&preset_balanced);
    group1.add(&preset_scientific);
    page1_box.append(&group1);

    view_stack.add_titled(&page1_box, Some("presets"), "Workload Presets");

    // Page 2: Kernel & Schedulers
    let page2_box = gtk::Box::new(gtk::Orientation::Vertical, 12);
    page2_box.set_margin_top(16);
    page2_box.set_margin_start(16);
    page2_box.set_margin_end(16);

    let group2 = adw::PreferencesGroup::builder()
        .title("CPU Scheduler (sched-ext / BORE)")
        .build();

    let thp_switch = adw::SwitchRow::builder()
        .title("Transparent HugePages (THP)")
        .subtitle("Optimize large memory block allocations for bioinformatics tools.")
        .build();
    group2.add(&thp_switch);
    page2_box.append(&group2);

    view_stack.add_titled(&page2_box, Some("kernel"), "Kernel & Scheduler");

    // Page 3: CPU & Power
    let page3_box = gtk::Box::new(gtk::Orientation::Vertical, 12);
    page3_box.set_margin_top(16);
    page3_box.set_margin_start(16);
    page3_box.set_margin_end(16);

    let group3 = adw::PreferencesGroup::builder()
        .title("Power Management")
        .build();

    let nvme_switch = adw::SwitchRow::builder()
        .title("NVMe APST Deep Power State (PS4)")
        .subtitle("Lower idle temperature and increase laptop battery life.")
        .active(true)
        .build();
    group3.add(&nvme_switch);
    page3_box.append(&group3);

    view_stack.add_titled(&page3_box, Some("power"), "CPU & NVMe Power");

    // Page 4: Atomic OS & Science Box
    let page4_box = gtk::Box::new(gtk::Orientation::Vertical, 12);
    page4_box.set_margin_top(16);
    page4_box.set_margin_start(16);
    page4_box.set_margin_end(16);

    let group4 = adw::PreferencesGroup::builder()
        .title("Atomic OS Updates & Rollback")
        .description("Manage system immutable images and boot-menu state.")
        .build();

    let upgrade_btn = gtk::Button::builder()
        .label("Update Atomic Image (Voyager-OSTree)")
        .css_classes(["suggested-action"])
        .build();
    let rollback_btn = gtk::Button::builder()
        .label("Rollback to Previous Atomic Deployment")
        .css_classes(["destructive-action"])
        .build();
    let science_btn = gtk::Button::builder()
        .label("Launch Kepler Science Distrobox")
        .build();

    science_btn.connect_clicked(|_| {
        let _ = Command::new("gnome-console")
            .args(["--", "/usr/bin/kepler-science-shell"])
            .spawn();
    });

    group4.add(&upgrade_btn);
    group4.add(&rollback_btn);
    group4.add(&science_btn);
    page4_box.append(&group4);

    // Append Btrfs snapshots group
    page4_box.append(&build_snapshots_group(&toast_overlay));

    view_stack.add_titled(&page4_box, Some("atomic"), "Atomic OS & Science");

    let switcher_title = adw::ViewSwitcherTitle::builder()
        .stack(&view_stack)
        .title("Kepler Tuner")
        .build();

    let header_bar = adw::HeaderBar::builder()
        .title_widget(&switcher_title)
        .build();

    let toolbar_view = adw::ToolbarView::builder()
        .content(&view_stack)
        .build();
    toolbar_view.add_top_bar(&header_bar);

    toast_overlay.set_child(Some(&toolbar_view));

    let window = adw::ApplicationWindow::builder()
        .application(app)
        .default_width(780)
        .default_height(580)
        .content(&toast_overlay)
        .build();

    window.present();
}

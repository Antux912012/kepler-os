// SPDX-License-Identifier: GPL-3.0-or-later
use adw::prelude::*;
use gtk::prelude::*;
use std::env;
use std::fs;
use std::path::PathBuf;
use std::process::Command;

fn get_done_flag_path() -> PathBuf {
    let mut path = dirs::config_dir().unwrap_or_else(|| PathBuf::from("/home/antonio/.config"));
    path.push("kepler-welcome-done");
    path
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let flag_path = get_done_flag_path();

    if args.iter().any(|arg| arg == "--autostart") && flag_path.exists() {
        return;
    }

    let app = adw::Application::builder()
        .application_id("org.voyager.KeplerWelcome")
        .build();

    app.connect_startup(|_| {
        let provider = gtk::CssProvider::new();
        provider.load_from_data(
            "
            window {
                background-color: #2E3440;
                color: #ECEFF4;
            }
            headerbar {
                background-color: #3B4252;
                color: #ECEFF4;
                border-bottom: 1px solid #4C566A;
            }
            button.suggested-action {
                background-color: #88C0D0;
                color: #2E3440;
                font-weight: bold;
            }
            .accent-label {
                color: #88C0D0;
                font-size: 1.2em;
                font-weight: bold;
            }
            "
        );
        gtk::style_context_add_provider_for_display(
            &gtk::gdk::Display::default().unwrap(),
            &provider,
            gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
        );
    });

    app.connect_activate(build_ui);
    app.run_with_args(&args);
}

fn build_ui(app: &adw::Application) {
    let carousel = adw::Carousel::new();

    // Page 1: Welcome & Compliance Overview
    let page1 = gtk::Box::new(gtk::Orientation::Vertical, 16);
    page1.set_margin_top(24);
    page1.set_margin_bottom(24);
    page1.set_margin_start(32);
    page1.set_margin_end(32);

    let title1 = gtk::Label::builder()
        .label("Welcome to Kepler OS (Immutable Edition)")
        .css_classes(["title-1", "accent-label"])
        .build();
    let desc1 = gtk::Label::builder()
        .label("Kepler OS features an atomic OSTree architecture with a strictly read-only /usr partition, stateful /var and /etc, and instant boot-menu rollbacks.")
        .wrap(true)
        .justify(gtk::Justification::Center)
        .build();
    let notice1 = gtk::Label::builder()
        .label("Notice & Legal Compliance:\nCompliant with EU AI Act (Regulation EU 2024/1689 Art. 50) and CRA (EU 2024/2847).\nNot affiliated with NASA, ESA, or third-party missions named Kepler or Voyager.")
        .wrap(true)
        .justify(gtk::Justification::Center)
        .build();
    page1.append(&title1);
    page1.append(&desc1);
    page1.append(&notice1);
    carousel.append(&page1);

    // Page 2: Hardware & Security
    let page2 = gtk::Box::new(gtk::Orientation::Vertical, 16);
    page2.set_margin_top(24);
    page2.set_margin_bottom(24);
    page2.set_margin_start(32);
    page2.set_margin_end(32);

    let title2 = gtk::Label::builder()
        .label("Hardware & Secure Boot Setup")
        .css_classes(["title-1", "accent-label"])
        .build();
    let btn_mok = gtk::Button::with_label("Enroll UEFI Secure Boot MOK Key");
    btn_mok.connect_clicked(|_| {
        let _ = Command::new("/usr/bin/kepler-enroll-mok").spawn();
    });
    let btn_tuner = gtk::Button::with_label("Open Kepler Kernel & Power Tuner");
    btn_tuner.connect_clicked(|_| {
        let _ = Command::new("/usr/bin/kepler-tuner-gui").spawn();
    });
    page2.append(&title2);
    page2.append(&btn_mok);
    page2.append(&btn_tuner);
    carousel.append(&page2);

    // Page 3: Scientific Workspace
    let page3 = gtk::Box::new(gtk::Orientation::Vertical, 16);
    page3.set_margin_top(24);
    page3.set_margin_bottom(24);
    page3.set_margin_start(32);
    page3.set_margin_end(32);

    let title3 = gtk::Label::builder()
        .label("Scientific Workspace Setup")
        .css_classes(["title-1", "accent-label"])
        .build();
    let btn_distrobox = gtk::Button::with_label("Assemble Kepler Science Distrobox");
    btn_distrobox.connect_clicked(|_| {
        let _ = Command::new("gnome-console")
            .args(["--", "/usr/bin/kepler-science-shell"])
            .spawn();
    });
    let btn_cyto = gtk::Button::with_label("Launch Cytoscape (Auto JVM Heap)");
    btn_cyto.connect_clicked(|_| {
        let _ = Command::new("/usr/bin/cytoscape-kepler").spawn();
    });
    page3.append(&title3);
    page3.append(&btn_distrobox);
    page3.append(&btn_cyto);
    carousel.append(&page3);

    // Page 4: Arda-Tech Ecosystem & Voyager Flatpaks
    let page4 = gtk::Box::new(gtk::Orientation::Vertical, 16);
    page4.set_margin_top(24);
    page4.set_margin_bottom(24);
    page4.set_margin_start(32);
    page4.set_margin_end(32);

    let title4 = gtk::Label::builder()
        .label("Arda-Tech Ecosystem & Voyager-Flatpak")
        .css_classes(["title-1", "accent-label"])
        .build();
    let btn_imladris = gtk::Button::with_label("Install Imladris (Scientific IDE)");
    btn_imladris.connect_clicked(|_| {
        let _ = Command::new("flatpak")
            .args(["install", "-y", "voyager-flatpak", "io.github.Antux912012.Imladris"])
            .spawn();
    });
    let btn_software = gtk::Button::with_label("Open GNOME Software");
    btn_software.connect_clicked(|_| {
        let _ = Command::new("gnome-software").spawn();
    });
    page4.append(&title4);
    page4.append(&btn_imladris);
    page4.append(&btn_software);
    carousel.append(&page4);

    let dots = adw::CarouselIndicatorDots::builder()
        .carousel(&carousel)
        .build();

    let content_box = gtk::Box::new(gtk::Orientation::Vertical, 8);
    content_box.append(&carousel);
    content_box.append(&dots);

    // Bottom controls
    let bottom_box = gtk::Box::new(gtk::Orientation::Horizontal, 12);
    bottom_box.set_margin_start(24);
    bottom_box.set_margin_end(24);
    bottom_box.set_margin_bottom(16);

    let finish_btn = gtk::Button::builder()
        .label("Finish Setup")
        .css_classes(["suggested-action"])
        .hexpand(true)
        .build();

    let window = adw::ApplicationWindow::builder()
        .application(app)
        .title("Kepler OS Welcome & Setup")
        .default_width(820)
        .default_height(560)
        .content(&adw::ToolbarView::builder()
            .content(&content_box)
            .build())
        .build();

    let win_clone = window.clone();
    finish_btn.connect_clicked(move |_| {
        let flag = get_done_flag_path();
        if let Some(parent) = flag.parent() {
            let _ = fs::create_dir_all(parent);
        }
        let _ = fs::write(flag, "completed");
        win_clone.close();
    });

    bottom_box.append(&finish_btn);
    content_box.append(&bottom_box);

    window.present();
}

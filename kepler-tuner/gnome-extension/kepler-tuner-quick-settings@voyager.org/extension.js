// SPDX-License-Identifier: GPL-3.0-or-later
import Gio from 'gi://Gio';
import GObject from 'gi://GObject';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import {QuickMenuToggle, SystemIndicator} from 'resource:///org/gnome/shell/ui/quickSettings.js';

const KeplerTunedInterface = `
<node>
  <interface name="org.voyager.KeplerTuned1">
    <method name="ApplyWorkloadPreset">
      <arg type="s" direction="in" name="preset"/>
    </method>
    <method name="GetCpuProfile">
      <arg type="s" direction="out" name="profile"/>
    </method>
  </interface>
</node>`;

const KeplerTunedProxy = Gio.DBusProxy.makeProxyWrapper(KeplerTunedInterface);

const KeplerTunerToggle = GObject.registerClass(
class KeplerTunerToggle extends QuickMenuToggle {
    _init() {
        super._init({
            title: 'Kepler Tuner',
            subtitle: 'Balanced Desktop',
            iconName: 'preferences-system-performance-symbolic',
            toggleMode: false,
        });

        this._proxy = new KeplerTunedProxy(
            Gio.DBus.system,
            'org.voyager.KeplerTuned',
            '/org/voyager/KeplerTuned'
        );

        this.menu.setHeader('preferences-system-performance-symbolic', 'Kepler Workload Presets');

        this.menu.addAction('Silent / Mobile (EPP Power + NVMe PS4)', () => {
            this._applyPreset('silent_mobile', 'Silent / Mobile');
        });

        this.menu.addAction('Balanced Desktop (EPP Balance)', () => {
            this._applyPreset('balanced_desktop', 'Balanced Desktop');
        });

        this.menu.addAction('Scientific Compute (Performance + THP)', () => {
            this._applyPreset('scientific_compute', 'Scientific Compute');
        });

        this.menu.addMenuItem(new Gio.MenuItem()); // separator

        this.menu.addAction('Open Kepler Kernel & Atomic OS Tuner...', () => {
            Gio.Subprocess.new(['/usr/bin/kepler-tuner-gui'], Gio.SubprocessFlags.NONE);
        });
    }

    _applyPreset(preset, label) {
        if (this._proxy) {
            this._proxy.ApplyWorkloadPresetRemote(preset, (result, error) => {
                if (!error) {
                    this.subtitle = label;
                }
            });
        }
    }
});

const KeplerTunerIndicator = GObject.registerClass(
class KeplerTunerIndicator extends SystemIndicator {
    _init() {
        super._init();
        this._indicator = this._addIndicator();
        this._indicator.iconName = 'preferences-system-performance-symbolic';
        this.quickSettingsItems.push(new KeplerTunerToggle());
    }
});

export default class KeplerTunerExtension extends Extension {
    enable() {
        this._indicator = new KeplerTunerIndicator();
        Main.panel.statusArea.quickSettings.addExternalIndicator(this._indicator);
    }

    disable() {
        if (this._indicator) {
            this._indicator.destroy();
            this._indicator = null;
        }
    }
}

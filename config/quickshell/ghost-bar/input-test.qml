import QtQuick
import QtTest
import Quickshell

// Test entry only: run offscreen with both GHOST_*_FIXTURE flags set.
ShellRoot {
    FloatingWindow {
        visible: true
        implicitWidth: 900
        implicitHeight: 900

        TestCase {
            id: test

            property int outsideEvents: 0
            property int escapeEvents: 0
            property int soundRequests: 0
            property int actionRequests: 0

            function test_click_sound_and_action() {
                mouseClick(clickProbe, 30, 15);
                compare(soundRequests, 1);
                compare(actionRequests, 1);
                console.info("PASS: click dispatches both fixed SFX and derived action");
            }

            function test_music_layout() {
                compare(musicControls.implicitHeight, 210);
                compare(musicControls.timecode(125), "2:05");
                compare(musicControls.timecode(-1), "0:00");
                musicControls.compact = true;
                compare(musicControls.implicitHeight, 32);
                musicControls.compact = false;
                console.info("PASS: expanded/compact music geometry and time formatting");
            }

            function test_settings_scroll_and_selection() {
                sidebar.visible = false;
                settingsPanel.visible = true;
                settingsPanel.choose("general");
                wait(350);
                const before = JSON.parse(settingsPanel.status());
                mouseWheel(settingsPanel, 120, 400, 0, -240);
                wait(100);
                verify(JSON.parse(settingsPanel.status()).navScroll > before.navScroll);
                settingsPanel.choose("storage");
                wait(35);
                const moving = JSON.parse(settingsPanel.status());
                verify(Math.abs(moving.selectionY - moving.selectionTarget) > 0.5);
                wait(350);
                const settled = JSON.parse(settingsPanel.status());
                compare(settled.selectionY, settled.selectionTarget);
                settingsPanel.visible = false;
                sidebar.visible = true;
                console.info("PASS: Settings wheel propagation and Bezier selection movement");
            }

            function test_settings_reference_header() {
                sidebar.visible = false;
                settingsPanel.visible = true;
                settingsPanel.choose("general");
                wait(350);
                const original = JSON.parse(settingsPanel.status());
                compare(original.navTop, 145);
                compare(original.searchTop, 84);
                compare(original.searchWidth, 227);
                compare(original.portraitTop, 18);
                compare(original.portraitSize, 48);
                compare(original.portraitRadius, 11);
                const spacing = settingsPanel.spacingStatus();
                compare(spacing.rowHeight, 44);
                compare(spacing.rowGap, 8);
                compare(spacing.icons.length, 14);
                for (const icon of spacing.icons) verify(Math.abs(icon.glyph / icon.well - 0.6) < 0.001)
                const selected = findChild(settingsPanel, "settings-navigation-general");
                const unselected = findChild(settingsPanel, "settings-navigation-network");
                verify(selected !== null && unselected !== null);
                mouseMove(selected, 120, 21);
                wait(200);
                verify(selected.hovered);
                compare(findChild(selected, "key-hover-feedback").opacity, 0);
                mouseMove(unselected, 120, 21);
                wait(200);
                verify(unselected.hovered);
                compare(findChild(unselected, "key-hover-feedback").opacity, 0.09);
                settingsPanel.choose("about");
                wait(350);
                const bottom = JSON.parse(settingsPanel.status());
                verify(bottom.navScroll > 0);
                compare(bottom.portraitTop, original.portraitTop);
                compare(bottom.searchTop, original.searchTop);
                mouseClick(settingsPanel, 41, 42);
                verify(JSON.parse(settingsPanel.status()).portraitChooserRequested);
                settingsPanel.cancelPortrait();
                mouseClick(settingsPanel, 206, 42);
                compare(settingsPanel.page, "general");
                const search = findChild(settingsPanel, "settings-search");
                verify(search !== null);
                mouseClick(search, 30, 8);
                keyClick(Qt.Key_S);
                keyClick(Qt.Key_O);
                keyClick(Qt.Key_U);
                keyClick(Qt.Key_N);
                keyClick(Qt.Key_D);
                compare(settingsPanel.filteredCategories.length, 1);
                compare(settingsPanel.filteredCategories[0].id, "sound");
                const clear = findChild(settingsPanel, "settings-search-clear");
                verify(clear.visible);
                mouseClick(clear, 10, 10);
                compare(settingsPanel.query, "");
                compare(settingsPanel.filteredCategories.length, 14);
                for (const category of settingsPanel.categories) {
                    settingsPanel.choose(category.id);
                    wait(10);
                    compare(settingsPanel.page, category.id);
                }
                settingsPanel.choose("general");
                settingsPanel.visible = false;
                sidebar.visible = true;
                console.info("PASS: Settings fixed header, search, portrait, gear and all 14 pages");
            }

            function test_settings_revamp() {
                // Every production page must contain its rows and padded groups.
                function check(item) {
                    if (["settings-device-row", "settings-toggle-row", "settings-control-group", "settings-summary"].includes(item.objectName)) {
                        verify(item.width > 0 && item.height > 0, item.objectName);
                        verify(item.x >= 0 && item.x + item.width <= item.parent.width + 0.1, item.objectName + " horizontal bounds");
                        if (item.objectName === "settings-device-row" && !item.actionable)
                            compare(item.opacity, 1);

                    }
                    for (const child of item.children || []) check(child)
                }

                sidebar.visible = false;
                settingsPanel.visible = true;
                settingsPanel.choose("general");
                wait(200);
                const charge = findChild(settingsPanel, "settings-overview-battery");
                const storage = findChild(settingsPanel, "settings-overview-storage");
                compare(charge.width + storage.width + 16, 690);
                compare(charge.value, "82%");
                compare(storage.value, "392.0 GB");
                mouseClick(charge, 100, 60);
                compare(settingsPanel.page, "battery");
                compare(settingsPanel.publicCaptureItem(), findChild(settingsPanel, "settings-battery-charge"));
                settingsPanel.choose("general");
                wait(20);
                mouseClick(findChild(settingsPanel, "settings-overview-storage"), 100, 60);
                compare(settingsPanel.page, "storage");
                const meter = findChild(settingsPanel, "settings-storage-meter");
                verify(meter !== null);
                verify(Math.abs(findChild(meter, "settings-storage-fill").width / meter.width - 120 / 512) < 0.001);
                for (const category of settingsPanel.categories) {
                    settingsPanel.choose(category.id);
                    wait(20);
                    const loader = findChild(settingsPanel, "settings-page-loader");
                    verify(loader.item !== null, category.id);
                    check(loader.item);
                }
                settingsPanel.choose("sound");
                wait(20);
                const before = JSON.parse(settingsPanel.status());
                verify(before.pageContentHeight > before.pageHeight);
                mouseWheel(settingsPanel, 700, 400, 0, -240);
                wait(100);
                verify(JSON.parse(settingsPanel.status()).pageScroll > before.pageScroll);
                settingsPanel.choose("general");
                compare(JSON.parse(settingsPanel.status()).pageScroll, 0);
                Theme.reducedMotion = true;
                settingsPanel.choose("about");
                compare(JSON.parse(settingsPanel.status()).selectionY, JSON.parse(settingsPanel.status()).selectionTarget);
                Theme.reducedMotion = false;
                settingsPanel.visible = false;
                sidebar.visible = true;
                console.info("PASS: Settings live summaries, passive storage, all-page bounds and content scrolling");
            }

            function test_weather_switcher() {
                sidebar.visible = false;
                weatherSwitcher.visible = true;
                weatherSwitcher.forecastIndex = 2;
                weatherSwitcher.forecastSelected = false;
                wait(20);
                mouseWheel(weatherSwitcher, 100, 170, 0, -120);
                wait(20);
                compare(weatherSwitcher.headlineCondition, "clear");
                compare(weatherSwitcher.headlineTemperature, 20);
                mouseWheel(weatherSwitcher, 100, 170, 0, 120);
                wait(20);
                compare(weatherSwitcher.headlineCondition, "storm");
                compare(weatherSwitcher.headlineTemperature, 15);
                weatherSwitcher.visible = false;
                sidebar.visible = true;
                console.info("PASS: selected weather headline and temperature agree");
            }

            function test_escape_from_root() {
                wait(20);
                sidebar.forceActiveFocus();
                verify(sidebar.activeFocus);
                keyClick(Qt.Key_Escape);
                compare(escapeEvents, 1);
                console.info("PASS: sidebar Escape event");
            }

            function test_outside_pointer() {
                mouseClick(outside, 50, 50);
                compare(outsideEvents, 1);
                console.info("PASS: outside pointer event");
            }

            function test_fullscreen_visibility() {
                compare(fullscreenState.active, false);
                workspace.hasFullscreen = true;
                compare(fullscreenState.active, true);
                workspace.hasFullscreen = false;
                compare(fullscreenState.active, false);
                // Moving to an empty/non-fullscreen workspace restores the rail.
                workspace.hasFullscreen = true;
                fixtureMonitor.activeWorkspace = null;
                compare(fullscreenState.active, false);
                fixtureMonitor.activeWorkspace = workspace;
                compare(fullscreenState.active, true);
                fullscreenState.monitor = null;
                compare(fullscreenState.active, false);
                fullscreenState.monitor = fixtureMonitor;
                workspace.hasFullscreen = false;
                console.info("PASS: per-output fullscreen visibility and restoration");
            }

            function cleanupTestCase() {
                Qt.quit();
            }

            name: "SidebarInput"
            when: true
            visible: true
            width: 900
            height: 900

            Key {
                id: clickProbe

                // Observe both base and derived signal handlers without audio.
                function clickSound() {
                    test.soundRequests++;
                }

                x: 700
                y: 400
                width: 80
                text: "Test"
                onClicked: test.actionRequests++
            }

            QtObject {
                id: workspace

                property bool hasFullscreen: false
            }

            QtObject {
                id: fixtureMonitor

                property var activeWorkspace: workspace
            }

            FullscreenState {
                id: fullscreenState

                monitor: fixtureMonitor
            }

            SidebarFigmaBody {
                id: sidebar

                width: 354
                height: 790
                previewMode: true
                opened: true
                screen: ({
                    "name": "test"
                })
                onCloseRequested: test.escapeEvents++
            }

            DismissArea {
                id: outside

                x: 500
                width: 200
                height: 200
                onDismissed: test.outsideEvents++
            }

            SettingsPanel {
                id: settingsPanel

                visible: false
                width: 1024
                height: 699
                previewMode: true
            }

            CalendarPanel {
                id: weatherSwitcher

                visible: false
                previewMode: true
                width: 733
            }

            MusicBar {
                id: musicControls

                visible: false
                compact: false
                width: 348
            }

        }

    }

}

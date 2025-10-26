# Aircraft Config Center
# Joshua Davidson (Octal450)

# Copyright (c) 2020 Josh Davidson (Octal450)

# Adapted to Cessna 152 by Adrian Fernandez (awall86)

var CONFIG = {
	noUpdateCheck: 0, # Disable ACCONFIG update checks
};

var spinning = maketimer(0.10, func {
	var spinning = getprop("/systems/acconfig/spinning");
	if (spinning == 0) {
		setprop("/systems/acconfig/spin", ">>---");
		setprop("/systems/acconfig/spinning", 1);
	} else if (spinning == 1) {
		setprop("/systems/acconfig/spin", ">>>--");
		setprop("/systems/acconfig/spinning", 2);
	} else if (spinning == 2) {
		setprop("/systems/acconfig/spin", ">>>>-");
		setprop("/systems/acconfig/spinning", 3);
	} else if (spinning == 3) {
		setprop("/systems/acconfig/spin", ">>>>>");
		setprop("/systems/acconfig/spinning", 4);
	} else if (spinning == 4) {
		setprop("/systems/acconfig/spin", "->>>>");
		setprop("/systems/acconfig/spinning", 5);
	} else if (spinning == 5) {
		setprop("/systems/acconfig/spin", "-->>>");
		setprop("/systems/acconfig/spinning", 6);
	} else if (spinning == 6) {
		setprop("/systems/acconfig/spin", "--->>");
		setprop("/systems/acconfig/spinning", 7);
	} else if (spinning == 7) {
		setprop("/systems/acconfig/spin", "---->");
		setprop("/systems/acconfig/spinning", 0);
	}
});

setprop("/systems/acconfig/autoconfig-running", 0);
setprop("/systems/acconfig/spinning", 0);
setprop("/systems/acconfig/spin", ">----");
setprop("/systems/acconfig/new-revision", "NONE");
setprop("/systems/acconfig/out-of-date", 0);
setprop("/systems/acconfig/mismatch-reason", "XX");
setprop("/systems/acconfig/options/revision", "NONE");


var init_dlg = gui.Dialog.new("/sim/gui/dialogs/acconfig/init/dialog", "Aircraft/c152/AircraftConfig/init.xml");
var update_dlg = gui.Dialog.new("/sim/gui/dialogs/acconfig/update/dialog", "Aircraft/c152/AircraftConfig/update.xml");
var updated_dlg = gui.Dialog.new("/sim/gui/dialogs/acconfig/updated/dialog", "Aircraft/c152/AircraftConfig/updated.xml");
var error_mismatch = gui.Dialog.new("/sim/gui/dialogs/acconfig/error/mismatch/dialog", "Aircraft/c152/AircraftConfig/error-mismatch.xml");

spinning.start();
init_dlg.open();
if (!CONFIG.noUpdateCheck) {
	http.load("https://raw.githubusercontent.com/awall086/c152/master/revision.txt").done(func(r) setprop("/systems/acconfig/new-revision", r.response));
}
var revisionFile = (getprop("/sim/aircraft-dir") ~ "/revision.txt");
var current_revision = io.readfile(revisionFile);
setprop("/systems/acconfig/revision", current_revision);

var SYSTEM = { # Prepare for migration to ACCONFIG V2
	autoConfigRunning: props.globals.getNode("/systems/acconfig/autoconfig-running"),
};

setlistener("/systems/acconfig/new-revision", func {
	if (getprop("/systems/acconfig/new-revision") != current_revision and !CONFIG.noUpdateCheck) {
		setprop("/systems/acconfig/out-of-date", 1);
	} else {
		setprop("/systems/acconfig/out-of-date", 0);
	}
});

var fgfsMin = split(".", getprop("/sim/minimum-fg-version"));
var fgfsVer = split(".", getprop("/sim/version/flightgear"));

var versionCheck = func() {
	if (fgfsVer[0] > fgfsMin[0]) {
		return 1;
	} else if (fgfsVer[0] == fgfsMin[0]) {
		if (fgfsVer[1] > fgfsMin[1]) {
			return 1;
		} else if (fgfsVer[1] == fgfsMin[1]) {
			if (fgfsVer[2] >= fgfsMin[2]) {
				return 1;
			} else {
				return 0;
			}
		} else {
			return 0;
		}
	} else {
		return 0;
	}
}

var mismatch_chk = func {
	if (!versionCheck()) {
		setprop("/systems/acconfig/mismatch-reason", "FGFS version is too old! Please update FlightGear to at least " ~ getprop("/sim/minimum-fg-version") ~ ".");
		if (getprop("/systems/acconfig/out-of-date") != 1) {
			error_mismatch.open();
		}
		print("Error: Version");
	}
}

setlistener("/sim/signals/fdm-initialized", func {
	init_dlg.close();
	if (getprop("/systems/acconfig/out-of-date") == 1) {
		update_dlg.open();
		print("System: The Cessna 152 is out of date!");
	} 
	mismatch_chk();
	readSettings();
	if (getprop("/systems/acconfig/out-of-date") != 1 and getprop("/systems/acconfig/options/revision") != current_revision and getprop("/systems/acconfig/mismatch-reason") == "XX" and !CONFIG.noUpdateCheck) {
		updated_dlg.open();
		print("System: The Cessna 152 is up to date!");
	}
	setprop("/systems/acconfig/options/revision", current_revision);
	writeSettings();	
	spinning.stop();
});

var readSettings = func {
	io.read_properties(getprop("/sim/fg-home") ~ "/Export/c152-config.xml", "/systems/acconfig/options");
}

var writeSettings = func {
	io.write_properties(getprop("/sim/fg-home") ~ "/Export/c152-config.xml", "/systems/acconfig/options");
}

# Aircraft Config Center
# Joshua Davidson (Octal450)

# Copyright (c) 2020 Josh Davidson (Octal450)

# Adapted to Cessna 152 by Adrian fernandez (awall86)

var spinning = maketimer(0.10, func {
	var spinning = getprop("/systems/acconfig/spinning");
	if (spinning == 0) {
		setprop("/systems/acconfig/spin", "=o===");
		setprop("/systems/acconfig/spinning", 1);
	} else if (spinning == 1) {
		setprop("/systems/acconfig/spin", "==o==");
		setprop("/systems/acconfig/spinning", 2);
	} else if (spinning == 2) {
		setprop("/systems/acconfig/spin", "===o=");
		setprop("/systems/acconfig/spinning", 3);
	} else if (spinning == 3) {
		setprop("/systems/acconfig/spin", "====o");
		setprop("/systems/acconfig/spinning", 4);
	} else if (spinning == 4) {
		setprop("/systems/acconfig/spin", "===o=");
		setprop("/systems/acconfig/spinning", 5);
	} else if (spinning == 5) {
		setprop("/systems/acconfig/spin", "==o==");
		setprop("/systems/acconfig/spinning", 6);
	} else if (spinning == 6) {
		setprop("/systems/acconfig/spin", "=o===");
		setprop("/systems/acconfig/spinning", 7);
	} else if (spinning == 7) {
		setprop("/systems/acconfig/spin", "o====");
		setprop("/systems/acconfig/spinning", 0);
	}
});

setprop("/systems/acconfig/spinning", 0);
setprop("/systems/acconfig/spin", "o====");
setprop("/systems/acconfig/new-revision", "None");
setprop("/systems/acconfig/out-of-date", 0);
setprop("/systems/acconfig/options/welcome-skip", 0);
setprop("/systems/acconfig/options/save-state", 0);


var init_dlg = gui.Dialog.new("/sim/gui/dialogs/acconfig/init/dialog", "Aircraft/c152/AircraftConfig/init.xml");
var update_dlg = gui.Dialog.new("/sim/gui/dialogs/acconfig/update/dialog", "Aircraft/c152/AircraftConfig/update.xml");
var updated_dlg = gui.Dialog.new("/sim/gui/dialogs/acconfig/updated/dialog", "Aircraft/c152/AircraftConfig/updated.xml");

spinning.start();
init_dlg.open();
http.load("https://raw.githubusercontent.com/awall086/c152/master/revision.txt").done(func(r) setprop("/systems/acconfig/new-revision", r.response));
var revisionFile = (getprop("/sim/aircraft-dir") ~ "/revision.txt");
var current_revision = io.readfile(revisionFile);

setprop("/systems/acconfig/revision", current_revision);

setlistener("/systems/acconfig/new-revision", func {
	if (getprop("/systems/acconfig/new-revision") != current_revision) {
		setprop("/systems/acconfig/out-of-date", 1);
	} else {
		setprop("/systems/acconfig/out-of-date", 0);
	}
	readSettings();
	if (getprop("/systems/acconfig/out-of-date") != 1 and getprop("/systems/acconfig/options/revision") != current_revision) {
		updated_dlg.open();
	}
	setprop("/systems/acconfig/options/revision", current_revision);
	writeSettings();
	if (getprop("/options/system/save-state") == 1)
	{
		save.restore(save.default, getprop("/sim/fg-home") ~ "/Export/" ~ getprop("/sim/aircraft") ~ "-save.xml");
	}

});

setlistener("/sim/signals/fdm-initialized", func {
	init_dlg.close();
	if (getprop("/systems/acconfig/out-of-date") == 1) {
		update_dlg.open();
		print("System: Your Cessna 152 is out of date!");
	} 
	spinning.stop();
});

var readSettings = func {
	io.read_properties(getprop("/sim/fg-home") ~ "/Export/c152-config.xml", "/systems/acconfig/options");
	setprop("/options/system/save-state", getprop("/systems/acconfig/options/save-state"));
}

var writeSettings = func {
	setprop("/systems/acconfig/options/save-state", getprop("/options/system/save-state"));
	io.write_properties(getprop("/sim/fg-home") ~ "/Export/c152-config.xml", "/systems/acconfig/options");
}

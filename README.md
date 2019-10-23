# godot-delta-logger
Simple to use logger for the Godot engine written in GDScript.  Especially useful
for logging your game's `delta` times.

## Usage:

Add this node to your project as a singleton.  You can then log delta times
and other information as follows:

	func _ready():
		logger.out("GameScene._ready()")
		...
		logger.out("Adding game objects to scene...")

	func _process(delta):
		logger.out(delta)
		...

	func handlePlayerDeath():
		logger.out("Game over.")
		...

The logging information is written in a low priority background thread and
should, therefore, have minimal impact on your game's performance.

By default, the log file will be placed in the game's `user://` folder and
will have a filename that looks like the following:

	delta_log-20191023T163858.txt

The timestamp, by default, is in local time.  This can be changed with the
`useUtcTimeStamp` const.  The base filename and extension can be changed
with the `logFileBaseName` and `logFileExtension` consts.

## An (abbreviated) example of the output:

	---Logging begins---
	GameScene._ready()
	0.253773
	0.067668
	0.000391
	0.018182 (6 times)
	0.01671
	0.016667 (25 times)
	0.018182
	Adding game objects to scene...
	0.018182
	0.016667 (183 times)
	0.018182
	0.016667 (562 times)
	Buster formation triggered.
	0.016667 (201 times)
	Ammo crate picked up.
	0.016667 (179 times)
	Game over.
	0.016667 (367 times)
	---Logging ends---

By default, duplicate lines are collapsed as shown above.  This option can
be disabled by changing the `collapseDuplicates` const.  This will make
the log file larger and less (human) readable but may be useful for further
data processing.



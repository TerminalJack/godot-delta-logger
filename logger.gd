extends Node

# Usage:
#
# Add this node to your project as a singleton.  You can then log delta times
# and other information as follows:
#
#   func _ready():
#	    logger.out("GameScene._ready()")
#       ...
#       logger.out("Adding game objects to scene...")
#
#   func _process(delta):
#       logger.out(delta)
#       ...
#
#   func handlePlayerDeath():
#	    logger.out("Game over.")
#       ...
#
# The logging information is written in a low priority background thread and
# should, therefore, have minimal impact on your game's performance.
#
# By default, the log file will be placed in the game's "user://" folder and
# will have a filename that looks like the following:
#
#   delta_log-20191023T163858.txt
#
# The timestamp, by default, is in local time.  This can be changed with the
# 'useUtcTimeStamp' const below.  The base filename and extension can be changed
# with the 'logFileBaseName' and 'logFileExtension' consts below.
#
# An (abbreviated) example of the output:
#
#   ---Logging begins---
#   GameScene._ready()
#   0.253773
#   0.067668
#   0.000391
#   0.018182 (6 times)
#   0.01671
#   0.016667 (25 times)
#   0.018182
#   Adding game objects to scene...
#   0.018182
#   0.016667 (183 times)
#   0.018182
#   0.016667 (562 times)
#   Buster formation triggered.
#   0.016667 (201 times)
#   Ammo crate picked up.
#   0.016667 (179 times)
#   Game over.
#   0.016667 (367 times)
#   ---Logging ends---
#
# By default, duplicate lines are collapsed as shown above.  This option can
# be disabled by changing the 'collapseDuplicates' const below.  This will make
# the log file larger and less (human) readable but may be useful for further
# data processing.
#

const collapseDuplicates = true
const logFileBaseName = "user://delta_log-"
const logFileExtension = ".txt"
const useUtcTimeStamp = false # UTC (true) or local (false)

var bgThread
var msgMutex # Guards the 'msgs' array.
var workSemaphore # Wakes up bgThread for work or to exit.
var logFile
var msgs = [] # Note: Shared between threads.

func _enter_tree():
	if OS.can_use_threads():
		var logFilepath = logFileBaseName + _getTimeStamp(useUtcTimeStamp) + logFileExtension

		logFile = File.new()
		logFile.open(logFilepath, File.WRITE)

		msgMutex = Mutex.new()
		workSemaphore = Semaphore.new()

		bgThread = Thread.new()
		bgThread.start(self, "_thread_function", null, Thread.PRIORITY_LOW)

		out("---Logging begins---")
	else:
		print("Warning: The logger requires thread support but the " + OS.get_name())
		print("platform doesn't currently support threads.  The logger will be disabled.")


func _exit_tree():
	if OS.can_use_threads():
		out("---Logging ends---")
		out("**QUIT**")
		bgThread.wait_to_finish()
		logFile.close()


func out(msg):
	if OS.can_use_threads():
		msgMutex.lock()
		msgs.push_back(msg)
		msgMutex.unlock()
		workSemaphore.post()


func _getTimeStamp(useUtc):
	var dt = OS.get_datetime(useUtc)

	var result = "%02d%02d%02dT%02d%02d%02d" \
		% [ dt["year"], dt["month"], dt["day"], dt["hour"], dt["minute"], dt["second"] ]

	if useUtc:
		result += "Z"

	return result


func _thread_function(userData):
	var terminated = false
	var lastMsg = ""
	var dupCount = 0

	while !terminated:
		workSemaphore.wait()

		msgMutex.lock()

		var msgsCopy = msgs.duplicate()
		msgs.clear()

		msgMutex.unlock()

		for msg in msgsCopy:
			var msgStr = str(msg)

			if msgStr == "**QUIT**":
				terminated = true
			else:
				if collapseDuplicates && msgStr == lastMsg:
					dupCount += 1
				else:
					_writeLine(lastMsg, dupCount)
					dupCount = 0;
					lastMsg = msgStr

	_writeLine(lastMsg, dupCount)


func _writeLine(msgStr, dupCount):
	if msgStr == "":
		return

	if dupCount > 0:
		msgStr += " (" + str(dupCount + 1) + " times)"

	logFile.store_line(msgStr)

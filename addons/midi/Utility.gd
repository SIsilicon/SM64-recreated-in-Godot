"""
	MIDI Utilities by Yui Kinomoto @arlez80
"""

"""
	和音と調を解析する
	@param	notes			MIDI note numbers
	@param	music_chord		music chord (default C)
	@return	if find: { root: _, chord: _, string: _ } not found: null
"""
static func get_chord_and_scale( notes:Array, music_chord:int = 0 ):
	var chord_table:Array = []
	var octave:PoolIntArray = PoolIntArray( [0,0,0,0,0,0,0,0,0,0,0,0] )
	for note in notes: octave[note % 12] = 1
	var sound_count:int = 0
	for i in octave: sound_count += i

	if sound_count == 5:
		chord_table = [
			{ "name": "7(b9)", "notes": [ 4, 7, 10, 13 ] },
			{ "name": "9", "notes": [ 4, 7, 10, 14 ] },
		]
	elif sound_count == 4:
		chord_table = [
			{ "name": "sus4(13)", "notes": [ 5, 7, 9 ] },
			{ "name": "aug M7", "notes": [ 4, 8, 11 ] },
			{ "name": "dim7", "notes": [ 3, 6, 9 ] },
			{ "name": "7sus4", "notes": [ 5, 7, 10 ] },
			{ "name": "m7(-5)", "notes": [ 3, 6, 10 ] },
			{ "name": "mM7", "notes": [ 3, 7, 11 ] },
			{ "name": "m7", "notes": [ 3, 7, 10 ] },
			{ "name": "M7", "notes": [ 4, 7, 11 ] },
			{ "name": "7", "notes": [ 4, 7, 10 ] },
			{ "name": "m6", "notes": [ 3, 7, 9 ] },
			{ "name": "6", "notes": [ 4, 7, 9 ] },
		]
	elif sound_count == 3:
		chord_table = [
			{ "name": "sus4", "notes": [ 5, 7 ] },
			{ "name": "sus2", "notes": [ 2, 7 ] },
			{ "name": "aug", "notes": [ 4, 8 ] },
			{ "name": "dim", "notes": [ 3, 6 ] },
			{ "name": "m", "notes": [ 3, 7 ] },
			{ "name": "", "notes": [ 4, 7 ] },
		]
	#elif sound_count == 2:
	#	chord_table = [
	#		{ "name": "power", "notes": [ 5 ] },
	#	]
	else:
		return null

	for i in range( 0, 12 ):
		var root_note:int = ( i + music_chord ) % 12
		if octave[root_note] == 0: continue

		for chord in chord_table:
			var found:bool = true
			for note in chord.notes:
				if octave[(root_note + note) % 12] == 0:
					found = false
					break
			if found:
				return {
					"root": root_note,
					"chord": chord.name,
					"string": "%s%s" % [
						["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"][root_note],
						chord.name
					]}

	return null

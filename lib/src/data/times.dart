import "dart:convert" show JsonUnsupportedObjectError;
import "package:meta/meta.dart" show immutable;

import "package:ramaz_core/constants.dart";

/// An enum describing the different letter days.
enum Letter {
	/// An M day at Ramaz
	/// 
	/// Happens every Monday
	M, 

	/// An R day at Ramaz.
	/// 
	/// Happens every Thursday.
	R, 

	/// A day at Ramaz.
	/// 
	/// Tuesdays and Wednesdays rotate between A, B, and C days.
	A, 

	/// B day at Ramaz.
	/// 
	/// Tuesdays and Wednesdays rotate between A, B, and C days.
	B, 

	/// C day at Ramaz.
	/// 
	/// Tuesdays and Wednesdays rotate between A, B, and C days.
	C, 

	/// E day at Ramaz.
	/// 
	/// Fridays rotate between E and F days.
	E, 

	/// F day at Ramaz.
	/// 
	/// Fridays rotate between E and F days.
	F
}

/// Maps a [Letter] to a [String] without a function.
const Map<Letter, String> letterToString = {
	Letter.A: "A",
	Letter.B: "B",
	Letter.C: "C",
	Letter.M: "M",
	Letter.R: "R",
	Letter.E: "E",
	Letter.F: "F",
};

/// Maps a [String] to a [Letter] without a function.
const Map<String, Letter> stringToLetter = {
	"A": Letter.A,
	"B": Letter.B,
	"C": Letter.C,
	"M": Letter.M,
	"R": Letter.R,
	"E": Letter.E,
	"F": Letter.F,
	null: null,
};

/// The hour and minute representation of a time. 
/// 
/// This is used instead of [Flutter's TimeOfDay](https://api.flutter.dev/flutter/material/TimeOfDay-class.html)
/// to provide the `>` and `<` operators. 
@immutable
class Time {
	/// Defines the order of the hours in terms of the school day. 
	/// 
	/// Numbers on this clock ignore AM and PM by finding their index in this
	/// list instead. Numbers not in this list are considered to be invalid, 
	/// since they are not real school hours. 
	static const List <int> clock = [
		8, 9, 10, 11, 12, 1, 2, 3, 4, 5
	];

	/// The hour in 12-hour format. 
	final int hour;

	/// The minutes. 
	final int minutes;

	/// A const constructor.
	const Time (this.hour, this.minutes);

	/// Simplifies a [DateTime] object to a [Time].
	/// 
	/// If the hour is outside of the values listed in [clock], it is set to 5.
	/// This is to demonstrate that it is after school. 
	/// 
	/// When after-school events are introduced, this should be fixed. 
	factory Time.fromDateTime (DateTime date) {
		int hour = date.hour;
		if (hour >= 17 || hour < 8) {
			hour = 5;  // garbage value
		} else if (hour > 12) {
			hour -= 12;
		}
		return Time (hour, date.minute);
	}

	/// Returns a new [Time] object from JSON data.
	/// 
	/// The json must have `hour` and `minutes` fields that map to integers.
	Time.fromJson(Map<String, dynamic> json) :
		hour = json ["hour"],
		minutes = json ["minutes"];

	@override
	bool operator == (dynamic other) => other is Time && 
		other.hour == hour && 
		other.minutes == minutes;

	@override
	int get hashCode => "$hour:$minutes".hashCode;

	/// Returns whether this [Time] is before another [Time].
	bool operator < (Time other) => 
		clock.indexOf (hour) < clock.indexOf (other.hour) || 
		(hour == other.hour && minutes < other.minutes);

	/// Returns whether this [Time] is at or before another [Time].
	bool operator <= (Time other) => this < other || this == other;

	/// Returns whether this [Time] is after another [Time].
	bool operator > (Time other) => 
		clock.indexOf (hour) > clock.indexOf (other.hour) ||
		(hour == other.hour && minutes > other.minutes);

	/// Returns whether this [Time] is at or after another [Time].
	bool operator >= (Time other) => this > other || this == other;

	@override 
	String toString() => "$hour:${minutes.toString().padLeft(2, '0')}";
}

/// A range of times.
@immutable
class Range {
	/// Returns a list of [Range]s from a list of JSON objects
	/// 
	/// See [Range.fromJson] for more details.
	static List<Range> getList(List json) => [
		for (final dynamic jsonElement in json) 
			Range.fromJson(Map<String, dynamic>.from(jsonElement))
	];

	/// When this range starts.
	final Time start;

	/// When this range ends.
	final Time end;

	/// Provides a const constructor.
	const Range (this.start, this.end);

	/// Convenience method for manually creating a range by hand.
	Range.nums (
		int startHour, 
		int startMinute, 
		int endHour, 
		int endMinute
	) : 
		start = Time (startHour, startMinute), 
		end = Time (endHour, endMinute);

	/// Returns a new [Range] from JSON data
	/// 
	/// The json must have `start` and `end` fields that map to [Time] JSON 
	/// objects. See [Time.fromJson] for more details.
	Range.fromJson(Map<String, dynamic> json) :
		start = Time.fromJson(Map<String, dynamic>.from(json ["start"])),
		end = Time.fromJson(Map<String, dynamic>.from(json ["end"]));

	/// Returns whether [other] is in this range. 
	bool contains (Time other) => start <= other && other <= end;

	@override String toString() => "$start-$end";

	/// Returns whether this range is before another range.
	bool operator < (Time other) => end.hour < other.hour ||
	(
		end.hour == other.hour &&
		end.minutes < other.minutes
	);

	/// Returns whether this range is after another range.
	bool operator > (Time other) => start.hour > other.hour ||
	(
		start.hour == other.hour &&
		start.minutes > other.minutes
	);
}

/// A description of the time allotment for a day. 
/// 
/// Some days require different time periods, or even periods that 
/// are skipped altogether, as well as homeroom and mincha movements.
/// This class helps facilitate that. 
@immutable
class Special {
	/// The name of this special. 
	final String name;
	
	/// The time allotments for the periods. 
	final List <Range> periods;

	/// The indices of periods to skip. 
	/// 
	/// For example, on fast days, all lunch periods are skipped.
	/// So here, skip would be `[6, 7, 8]`, to skip 6th, 7th and 8th periods.
	final List<int> skip;

	/// The index in [periods] that represents mincha.
	final int mincha;
	
	/// The index in [periods] that represents homeroom.
	final int homeroom;

	/// A const constructor.
	const Special (
		this.name, 
		this.periods, 
		{
			this.homeroom, 
			this.mincha,
			this.skip
		}
	);

	/// Returns a new [Special] from a JSON value. 
	/// 
	/// The value must either be: 
	/// 
	/// - a string, in which case it should be in the [specials] list, or
	/// - a map, in which case it will be interpreted as JSON. The JSON must have: 
	/// 	- a "name" field, which should be a string. See [name].
	/// 	- a "periods" field, which should be a list of [Range] JSON objects. 
	/// 		See [Range.getList] for details.
	/// 	- a "homeroom" field, which should be an integer. See [homeroom].
	/// 	- a "skip" field, which should be a list of integers. See [skip].
	/// 
	factory Special.fromJson(dynamic value) {
		if (value == null) {
			return null;
		} else if (!(value is Map || value is String)) {
			throw ArgumentError.value (
				value, // invalid value
				"Special.fromJson: value", // arg name
				"$value is not a valid special", // message
			);
		} else if (value is String && !stringToSpecial.containsKey(value)) {
			throw ArgumentError.value(
				value, 
				"Special.fromJson: value",
				"'$value' needs to be one of ${stringToSpecial.keys.join(", ")}"
			);
		}
		if (value is String) {
			return stringToSpecial [value];
		}

		final Map<String, dynamic> json = Map<String, dynamic>.from(value);
		return Special (
			json ["name"],
			Range.getList(json ["periods"]),
			homeroom: json ["homeroom"],
			mincha: json ["mincha"],
			skip: List<int>.from(json ["skip"]),
		);
	}

	/// Determines whether to use a Winter Friday or regular Friday schedule. 
	/// 
	/// Winter Fridays mean shorter periods, with an ultimately shorter dismissal.
	static Special getWinterFriday() {
		final DateTime today = DateTime.now();
		final int month = today.month, day = today.day;
		if (month >= Times.schoolStart && month < Times.winterFridayMonthStart) {
			return friday;
		} else if (
			month > Times.winterFridayMonthStart ||
			month < Times.winterFridayMonthEnd
		) {
			return winterFriday;
		} else if (
			month > Times.winterFridayMonthEnd &&
			month <= Times.schoolEnd
		) {
			return friday;
		} else if (month == Times.winterFridayMonthStart) {
			if (day < Times.winterFridayDayStart) {
				return friday;
			} else {
				return winterFriday;
			}
		} else if (month == Times.winterFridayMonthEnd) {
			if (day < Times.winterFridayDayEnd) {
				return winterFriday;
			} else {
				return friday;
			}
		} else {
			return friday;
		}
	}

	@override 
	String toString() => name;

	@override 
	bool operator == (dynamic other) => other is Special && 
		other.name == name;

	@override
	int get hashCode => name.hashCode;

	/// The [Special] for Rosh Chodesh
	static const Special roshChodesh = Special (
		"Rosh Chodesh", 
		[
			Range (Time (8, 00), Time (9, 05)),
			Range (Time (9, 10), Time (9, 50)),
			Range (Time (9, 55), Time (10, 35)),
			Range (Time (10, 35), Time (10, 50)),
			Range (Time (10, 50), Time (11, 30)), 
			Range (Time (11, 35), Time (12, 15)),
			Range (Time (12, 20), Time (12, 55)),
			Range (Time (1, 00), Time (1, 35)),
			Range (Time (1, 40), Time (2, 15)),
			Range (Time (2, 30), Time (3, 00)),
			Range (Time (3, 00), Time (3, 20)),
			Range (Time (3, 20), Time (4, 00)),
			Range (Time (4, 05), Time (4, 45))
		],
		homeroom: 3,
		mincha: 10,
	);

	/// The [Special] for fast days. 
	static const Special fastDay = Special (
		"Tzom",
		[
			Range (Time (8, 00), Time (8, 55)),
			Range (Time (9, 00), Time (9, 35)),
			Range (Time (9, 40), Time (10, 15)),
			Range (Time (10, 20), Time (10, 55)), 
			Range (Time (11, 00), Time (11, 35)), 
			Range (Time (11, 40), Time (12, 15)),
			Range (Time (12, 20), Time (12, 55)), 
			Range (Time (1, 00), Time (1, 35)), 
			Range (Time (1, 35), Time (2, 05))
		],
		mincha: 8,
		skip: [6, 7, 8]
	);

	/// The [Special] for Fridays. 
	static const Special friday = Special (
		"Friday",
		[
			Range (Time (8, 00), Time (8, 45)),
			Range (Time (8, 50), Time (9, 30)),
			Range (Time (9, 35), Time (10, 15)),
			Range (Time (10, 20), Time (11, 00)),
			Range (Time (11, 00), Time (11, 20)),
			Range (Time (11, 20), Time (12, 00)),
			Range (Time (12, 05), Time (12, 45)),
			Range (Time (12, 50), Time (1, 30))
		],
		homeroom: 4
	);

	/// The [Special] for when Rosh Chodesh falls on a Friday. 
	static const Special fridayRoshChodesh = Special (
		"Friday Rosh Chodesh",
		[
			Range(Time (8, 00), Time (9, 05)),
			Range(Time (9, 10), Time (9, 45)),
			Range(Time (9, 50), Time (10, 25)),
			Range(Time (10, 30), Time (11, 05)),
			Range(Time (11, 05), Time (11, 25)),
			Range(Time (11, 25), Time (12, 00)),
			Range(Time (12, 05), Time (12, 40)),
			Range(Time (12, 45), Time (1, 20))
		],
		homeroom: 4
	);

	/// The [Special] for a winter Friday. See [Special.getWinterFriday].
	static const Special winterFriday = Special (
		"Winter Friday",
		[
			Range(Time (8, 00), Time (8, 45)),
			Range(Time (8, 50), Time (9, 25)), 
			Range(Time (9, 30), Time (10, 05)), 
			Range(Time (10, 10), Time (10, 45)),
			Range(Time (10, 45), Time (11, 05)), 
			Range(Time (11, 05), Time (11, 40)),
			Range(Time (11, 45), Time (12, 20)),
			Range(Time (12, 25), Time (1, 00))
		],
		homeroom: 4
	);

	/// The [Special] for when a Rosh Chodesh falls on a Winter Friday.
	static const Special winterFridayRoshChodesh = Special (
		"Winter Friday Rosh Chodesh",
		[
			Range(Time (8, 00), Time (9, 05)),
			Range(Time (9, 10), Time (9, 40)),
			Range(Time (9, 45), Time (10, 15)),
			Range(Time (10, 20), Time (10, 50)), 
			Range(Time (10, 50), Time (11, 10)),
			Range(Time (11, 10), Time (11, 40)),
			Range(Time (11, 45), Time (12, 15)),
			Range(Time (12, 20), Time (12, 50))
		],
		homeroom: 4
	);

	/// The [Special] for when there is an assembly during Homeroom.
	static const Special amAssembly = Special (
		"AM Assembly",
		[
			Range(Time (8, 00), Time (8, 50)),
			Range(Time (8, 55), Time (9, 30)),
			Range(Time (9, 35), Time (10, 10)),
			Range(Time (10, 10), Time (11, 10)),
			Range(Time (11, 10), Time (11, 45)), 
			Range(Time (11, 50), Time (12, 25)),
			Range(Time (12, 30), Time (1, 05)),
			Range(Time (1, 10), Time (1, 45)),
			Range(Time (1, 50), Time (2, 25)),
			Range(Time (2, 30), Time (3, 05)),
			Range(Time (3, 05), Time (3, 25)), 
			Range(Time (3, 25), Time (4, 00)),
			Range(Time (4, 05), Time (4, 45))
		],
		homeroom: 3,

		mincha: 10
	);

	/// The [Special] for when there is an assembly during Mincha.
	static const Special pmAssembly = Special (
		"PM Assembly",
		[
			Range(Time (8, 00), Time (8, 50)), 
			Range(Time (8, 55), Time (9, 30)),
			Range(Time (9, 35), Time (10, 10)),
			Range(Time (10, 15), Time (10, 50)),
			Range(Time (10, 55), Time (11, 30)),
			Range(Time (11, 35), Time (12, 10)),
			Range(Time (12, 15), Time (12, 50)),
			Range(Time (12, 55), Time (1, 30)),
			Range(Time (1, 35), Time (2, 10)), 
			Range(Time (2, 10), Time (3, 30)),
			Range(Time (3, 30), Time (4, 05)),
			Range(Time (4, 10), Time (4, 45))
		],
		mincha: 9
	);

	/// The [Special] for Mondays and Thursdays.
	static const Special regular = Special (
		"M or R day",
		[
			Range(Time (8, 00), Time (8, 50)),
			Range(Time (8, 55), Time (9, 35)),
			Range(Time (9, 40), Time (10, 20)),
			Range(Time (10, 20), Time (10, 35)),
			Range(Time (10, 35), Time (11, 15)), 
			Range(Time (11, 20), Time (12, 00)),
			Range(Time (12, 05), Time (12, 45)),
			Range(Time (12, 50), Time (1, 30)),
			Range(Time (1, 35), Time (2, 15)), 
			Range(Time (2, 20), Time (3, 00)),
			Range(Time (3, 00), Time (3, 20)), 
			Range(Time (3, 20), Time (4, 00)),
			Range(Time (4, 05), Time (4, 45))
		],
		homeroom: 3,
		mincha: 10
	);

	/// The [Special] for Tuesday and Wednesday (letters A, B, and C)
	static const Special rotate = Special (
		"A, B, or C day",
		[
			Range(Time (8, 00), Time (8, 45)), 
			Range(Time (8, 50), Time (9, 30)),
			Range(Time (9, 35), Time (10, 15)),
			Range(Time (10, 15), Time (10, 35)),
			Range(Time (10, 35), Time (11, 15)),
			Range(Time (11, 20), Time (12, 00)),
			Range(Time (12, 05), Time (12, 45)),
			Range(Time (12, 50), Time (1, 30)),
			Range(Time (1, 35), Time (2, 15)),
			Range(Time (2, 20), Time (3, 00)),
			Range(Time (3, 00), Time (3, 20)),
			Range(Time (3, 20), Time (4, 00)),
			Range(Time (4, 05), Time (4, 45))
		],
		homeroom: 3,
		mincha: 10
	);

	/// The [Special] for an early dismissal.
	static const Special early = Special (
		"Early Dismissal",
		[
			Range(Time (8, 00), Time (8, 45)),
			Range(Time (8, 50), Time (9, 25)), 
			Range(Time (9, 30), Time (10, 05)),
			Range(Time (10, 05), Time (10, 20)),
			Range(Time (10, 20), Time (10, 55)),
			Range(Time (11, 00), Time (11, 35)),
			Range(Time (11, 40), Time (12, 15)),
			Range(Time (12, 20), Time (12, 55)),
			Range(Time (1, 00), Time (1, 35)), 
			Range(Time (1, 40), Time (2, 15)),
			Range(Time (2, 15), Time (2, 35)),
			Range(Time (2, 35), Time (3, 10)),
			Range(Time (3, 15), Time (3, 50))
		],
		homeroom: 3,
		mincha: 10
	);

	/// A collection of all the [Special]s
	/// 
	/// Used in the UI
	static const List<Special> specials = [
		regular,
		roshChodesh,
		fastDay,
		friday,
		fridayRoshChodesh,
		winterFriday,
		winterFridayRoshChodesh,
		amAssembly,
		pmAssembly,
		rotate,
		early,
	];

	/// Maps the default special names to their [Special] objects
	static final Map<String, Special> stringToSpecial = Map.fromIterable(
		specials,
		key: (special) => special.name,
	);

	/// The default [Special] for a given [Letter].
	/// 
	/// See [Special.getWinterFriday] for how to determine the Friday schedule.
	static final Map<Letter, Special> defaultSpecials = {
		Letter.A: Special.rotate,
		Letter.B: Special.rotate,
		Letter.C: Special.rotate,
		Letter.M: Special.regular,
		Letter.R: Special.regular,
		Letter.E: Special.getWinterFriday(),
		Letter.F: Special.getWinterFriday(),
	};
}

/// A day at Ramaz. 
/// 
/// Each day has a [letter] and [special] property.
/// The [letter] property decides which schedule to show,
/// while the [special] property decides what time slots to give the periods. 
@immutable
class Day {
	/// Parses the calendar from a JSON map.
	/// 
	/// The key is the date (defaulting to today's month), 
	/// and the value is a JSON representation of a [Day].
	/// 
	/// See [Day.fromJson] for details on how a [Day] looks in JSON
	static Map<DateTime, Day> getCalendar(Map<String, dynamic> data) {
		final DateTime now = DateTime.now();
		final int month = now.month;
		final int year = now.year;
		final Map<DateTime, Day> result = {};
		for (final MapEntry<String, dynamic> entry in data.entries) {
			final int day = int.parse (entry.key);
			final DateTime date = DateTime.utc(
				year, 
				month, 
				day
			);
			result [date] = Day.fromJson(entry.value);
		}
		return result;
	}

	/// The letter of this day. 
	/// 
	/// This decides which schedule of the student is shown. 
	final Letter letter;

	/// The time allotment for this day.
	/// 
	/// See the [Special] class for more details.
	final Special special;

	/// Returns a new Day from a [Letter] and [Special].
	/// 
	/// [special] can be null, in which case 
	/// [Special.defaultSpecials] will be used.
	Day (
		this.letter,
		{special}
	) : special = special ?? Special.defaultSpecials [letter];

	/// Returns a Day from a JSON object.
	/// 
	/// `json ["letter"]` must be one of the specials in [Special.stringToSpecial].
	/// `json ["letter"]` must not be null.
	/// 
	/// `json ["special"]` may be: 
	/// 
	/// 1. One of the specials from [Special.defaultSpecials].
	/// 2. JSON of a special. See [Special.fromJson].
	/// 3. null, in which case [Special.defaultSpecials] will be used.
	/// 
	/// This factory is not a constructor so it can dynamically check 
	/// for a valid [letter] while keeping the field final.
	factory Day.fromJson(Map<dynamic, dynamic> json) {
		if (!json.containsKey("letter")) {
			throw JsonUnsupportedObjectError(json);
		}
		final String jsonLetter = json ["letter"];
		final jsonSpecial = json ["special"];
		if (!stringToLetter.containsKey (jsonLetter)) {
			throw ArgumentError.value(
				jsonLetter,  // invalid value
				"letter",  // arg name
				"$jsonLetter is not a valid letter",  // message
			); 
		}
		final Letter letter = stringToLetter [jsonLetter];
		final Special special = Special.fromJson(jsonSpecial);
		return Day (letter, special: special);
	}

	@override 
	String toString() => name;

	@override
	int get hashCode => name.hashCode;

	@override 
	bool operator == (dynamic other) => other is Day && 
		other.letter == letter &&
		other.special == special;

	/// A human-readable string representation of this day.
	/// 
	/// If the letter is null, returns null. 
	/// Otherwise, returns [letter] and [special].
	/// If [special] was left as the default, will only return the [letter].
	String get name => letter == null
		? null
		: "${letterToString [letter]} day${
			special == Special.regular || special == Special.rotate 
				? '' 
				: ' ${special.name}'
		}";

	/// Whether to say "a" or "an".
	/// 
	/// This method is needed since [letter] is a letter and not a word. 
	/// So a letter like "R" might need "an" while "B" would need "a".
	String get n {
		switch (letter) {
			case Letter.A:
			case Letter.E:
			case Letter.M:
			case Letter.R:
			case Letter.F:
				return "n";
			case Letter.B:
			case Letter.C:
			default: 
				return "";
		}
	}

	/// Whether there is school on this day.
	bool get school => letter != null;

	/// The period right now. 
	/// 
	/// Uses [special] to calculate the time slots for all the different periods,
	/// and uses [DateTime.now()] to look up what period it is right now. 
	/// 
	/// See [Time] and [Range] for implementation details.
	int get period {
		final Time time = Time.fromDateTime (DateTime.now());
		for (int index = 0; index < special.periods.length; index++) {
			final Range range = special.periods [index];
			if (
				range.contains(time) ||  // during class
				(  // between periods
					index != 0 && 
					special.periods [index - 1] < time && 
					range > time
				)
			) {
				return index;
			}
		}
		// A null period means school is out of session.
		// ignore: avoid_returning_null
		return null;
	}
}

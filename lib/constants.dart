library constants;

import "package:flutter/material.dart" show Color;

/// Ramaz-brand colors
class RamazColors {
	/// The standard Ramaz blue.
	static const Color blue = Color(0xFF004B8D);  // (255, 0, 75, 140);

	/// The standard Ramaz gold. 
	static const Color gold = Color(0xFFF9CA15);

	/// A lighter variant of [blue].
	/// 
	/// See [the Material Color Tool](https://material.io/resources/color/#!/?primary.color=004b8d&secondary.color=f9ca15)
	static const Color blueLight = Color(0xFF4A76BE);

	/// A darker variant of [blue]. 
	/// 
	/// See [the Material Color Tool](https://material.io/resources/color/#!/?primary.color=004b8d&secondary.color=f9ca15)
	static const Color blueDark = Color (0xFF00245F);

	/// A darker variant of [gold]. 
	/// 
	/// See [the Material Color Tool](https://material.io/resources/color/#!/?primary.color=004b8d&secondary.color=f9ca15)
	static const Color goldDark = Color (0xFFC19A00);

	/// A lighter variant of [blue]. 
	/// 
	/// See [the Material Color Tool](https://material.io/resources/color/#!/?primary.color=004b8d&secondary.color=f9ca15)
	static const Color goldLight = Color (0xFFFFFD56);
}

/// Specific dates or months that fundamentally mark the calendar.
class Times {
	/// The month school starts (September).
	static const int schoolStart = 9;

	/// The month school ends (July).
	static const int schoolEnd = 7;

	/// The month winter fridays start (November).
	static const int winterFridayMonthStart = 11;

	/// The month winter fridays end (March).
	static const int winterFridayMonthEnd = 3;

	/// The date that winter fridays start.
	static const int winterFridayDayStart = 1;

	/// The date that winter fridays end.
	static const int winterFridayDayEnd = 1;
}

import "package:cloud_firestore/cloud_firestore.dart" as fb;

import "auth.dart";

/// An abstraction wrapper around Cloud Firestore. 
/// 
/// This class only handles raw data transfer to and from Cloud Firestore.
/// Do not attempt to use dataclasses here, as that will create a dependency
/// between this library and the data library. 
class Firestore {
	static final fb.Firestore _firestore = fb.Firestore.instance;

	static final fb.CollectionReference _calendar = 
		_firestore.collection("calendar");

	static final fb.CollectionReference _classes = 
		_firestore.collection("classes");

	static final fb.CollectionReference _feedback = 
		_firestore.collection("feedback");

	static final fb.CollectionReference _notes = _firestore.collection("notes");

	static final fb.CollectionReference _students = 
		_firestore.collection("students");

	static final fb.CollectionReference _admins = 
		_firestore.collection("admin");

	/// Downloads the student's document in the student collection.
	Future<Map<String, dynamic>> get student async => 
		(await _students.document(await Auth.email).get()).data;

	/// Gets the currently signed in user's admin account. 
	static Future<Map<String, dynamic>> get admin async => 
		(await _admins.document(await Auth.email).get()).data;


	/// Downloads the relevant document in the `classes` collection.
	Future<Map<String, dynamic>> getClass (String id) async => 
		(await _classes.document(id).get()).data;

	/// Gets all class documents for a students schedule
	/// 
	/// This function goes over the student's schedule and keeps a record 
	/// of the unique section IDs and queries the database for them afterwards 
	/// using [getClass].
	/// 
	/// This function should be re-written to only accept a list of IDs
	/// instead of a student, as this creates a dependency between this 
	/// library and the data library.
	Future<Map<String, Map<String, dynamic>>> getClasses(Set<String> ids) async {
		final Map<String, Map<String, dynamic>> result = {};
		for (final String id in ids) {
			result [id] = await getClass(id);
		}
		return result;
	}

	/// Downloads the calendar for the current month. 
	static Future<Map<String, dynamic>> get month async => (
		await _calendar.document(DateTime.now().month.toString()).get()
	).data;

	/// Listens to the calendar for changes. 
	static Stream<fb.DocumentSnapshot> listenToCalendar(int month) => 
		_calendar.document(month.toString()).snapshots();

	/// Downloads the notes for the user. 
	/// 
	/// At least for now, these are stored in a spearate collection than
	/// the student profile data. This choice was made since notes are 
	/// updated frequently and this saves the system from processing the
	/// student's schedule every time this happens. 
	static Future<Map<String, dynamic>> get notes async => 
		(await _notes.document(await Auth.email).get()).data;

	/// Uploads the user's notes to the database. 
	/// 
	/// This function saves the notes along with a record of the notes that
	/// were already read. Those notes will be deleted once they are irrelevant.
	/// 
	/// This should be re-written to only accept a list of JSON elements, as 
	/// this creates a dependency between this library and the data library.
	/// This should also probably not persist the read notes in the database 
	/// (ie, keep them local).
	static Future<void> saveNotes(
		List<Map<String, dynamic>> notesList
	) async => _notes
		.document(await Auth.email)
		.setData({"notes": notesList});

	/// Submits feedback. 
	/// 
	/// The feedback collection is write-only, and can only be accessed by admins.
	static Future<void> sendFeedback(
		Map<String, dynamic> json
	) => _feedback.document().setData(json);

	/// Saves an admin's data to the database.
	static Future<void> saveAdmin(Map<String, dynamic> json) async => 
		_admins.document(await Auth.email).setData(json);

	/// Saves the calendar to the database.
	static Future<void> saveCalendar(int month, Map<String, dynamic> json) =>
		_calendar.document(month.toString()).setData(json);
}

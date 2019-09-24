import "dart:io" show File, Directory;
import "dart:typed_data" show Uint8List;
import "package:firebase_storage/firebase_storage.dart";

/// An abstraction around Firebase Cloud Storage.
/// 
/// This class only handles raw data transfer to and from Cloud Storage.
/// Do not attempt to use dataclasses here, as that will create a dependency
/// between this library and the data library. 
class CloudStorage {
	/// The Firebase Cloud Storage instance for this service
	static final StorageReference root = FirebaseStorage().ref();

	/// The separator for lists. 
	/// 
	/// Custom metadata values are restricted to being just Strings, so lists 
	/// are serialized with: `List.join(delimeter)`. 
	/// 
	/// This is a good workaround for now. If the need arises, the values can be 
	/// replaced with full JSON strings to serialize more complex data.
	static const String delimeter = ", ";

	/// The directory for publications.
	final Directory dir;

	/// Creates a connection to Firebase Cloud Storage. 
	/// 
	/// [dir] is initialized here.
	CloudStorage(String path) : 
		dir = Directory("$path/publications");

		/// All available publications.

	/// Returns a path that resides in the app's data directory.
	/// 
	/// This method should be used since it scopes knowledge
	/// of the app's data directory.
	String getPath(String path) => "${dir.path}/$path";

	/// Returns the path to a given publication's cover image. 
	String getImagePath(String publication) => getPath("$publication/$publication.png");

	/// A list of all the publications available.
	Future<List<String>> get publications async => 
		(await root.child("issues.txt").getMetadata())
			.customMetadata ["names"].split(delimeter);

	/// Returns the metadata for a given publication.
	/// 
	/// If this publication does not yet have its own folder (see [getPath]),
	/// this getter will create one synchronously.
	Future<Map<String, String>> getMetadata(String publication) async {
		final Directory publicationDir = Directory(getPath(publication));
		if (!publicationDir.existsSync()) {
			publicationDir.createSync(recursive: true);
		}
		await getImage(publication);
		return (await root.child("$publication/issues.txt").getMetadata()).customMetadata;
	}

	/// Downloads an issue from Firebase Cloud Storage if needed. 
	/// 
	/// The directory for this publication is assumed to exist since 
	/// [getMetadata] will create it if necessary. 
	Future<void> getIssue(String issue) async => 
		root.child(issue).writeToFile(File(getPath(issue))).future;

	/// Downloads the cover image for a given publication if needed.
	/// 
	/// The directory for this publication is assumed to exist since 
	/// [getMetadata] will create it if necessary. 
	Future<void> getImage(String publication) => root
		.child("$publication/$publication.png")
		.writeToFile(File(getImagePath(publication)))
		.future;

	/// Uploads a cover image for a given publication from a file.
	Future<void> uploadImage(String publication, File file) => 
		root.child("$publication/$publication.png").putFile(file).onComplete;

	/// Uploads a new issue from a file. 
	Future<void> uploadIssue(String issue, File file) => 
		root.child(issue).putFile(file).onComplete;

	/// Updates the metadata for a given publication.u
	Future<void> uploadMetadata(
		String publication, 
		Map<String, String> metadata
	) => root.child("$publication/issues.txt").updateMetadata(
		StorageMetadata(customMetadata: metadata)
	);

	/// Creates a new publication. 
	/// 
	/// This involves updating the metadata needed by [publications], 
	/// and creating a directory for the publication in Firebase Storage.
	Future<void> createPublication(String publication) async {
		final List<String> publicationsList = await publications;
		if (publicationsList.contains(publication)) {
			return;  // Will not create duplicate publication.
		}

		await root.child("issues.txt").updateMetadata(
			StorageMetadata(
				customMetadata: {
					"names": [
						...await publications,
						publication  // add this publication
					].join(delimeter)
				}
			)
		);
		await root
			.child("$publication/issues.txt")
			.putData(Uint8List.fromList([]))
			.onComplete;
	}

	/// Deletes an issue from Firebase Storage.
	Future<void> deleteIssue(String issue) => root.child(issue).delete();

	/// Deletes all locally saved data. 
	void deleteLocal() => dir.deleteSync(recursive: true);
}

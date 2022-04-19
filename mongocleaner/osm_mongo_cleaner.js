// Implements various commands to manage orphan files in the mongodb filesystem, that is
// files that do not correspond to any ns, nsr, vnfr or k8s cluster currently active
// in the system, probably leftovers

// How to invoke this script: cat cleaner.js| kubectl exec -i -c mongodb-k8s -n osm mongodb-k8s-0 -- mongo --quiet

// commands
// 	orphan-folders: lists the orphan folders
//  orphan-files: lists the orphan files
//  mark-orphans: prepends "ORPHAN_" to the name of each orphan file, so that they can be later removed.
// 		it is done as a two step process (first changing the name and then deleting) for security
//  delete-orphans: deletes all files and associated chunks whose name starts with ORPHAN (as done in the previous command)
//  revert-orphans: removes the "ORPHAN_" prefix in any files

///////////////////////////////////////////////////////////////////
// Helper functions
///////////////////////////////////////////////////////////////////

// Renames the file object prepending "ORPHAN_"
function setNameAsOrphan(fileName){
	// Make it idempotent
	if(fileName.startsWith("ORPHAN_")) return;
	db.fs.files.updateOne({"filename": fileName}, {$set: { "filename": "ORPHAN_" + fileName}});
}

// Finds file names starting with ORPHAN and removes that prefix
function revertOrphans(){
	orphanFiles = db.fs.files.find({"filename": {$regex: /^ORPHAN_/}});
	count = orphanFiles.count();
	orphanFiles.forEach(function(file){
		db.fs.files.updateOne({"filename": file.filename}, {$set: { "filename": file.filename.substring(7)}});
	});
	return count;
}

// Deletes orphan named files and chunks
function deleteOrphans(){
	orphanFiles = db.fs.files.find({"filename": {$regex: /^ORPHAN_/}});
	count = orphanFiles.count();
	orphanFiles.forEach(function(file){
		// Delete chunks
		deletedChunks = db.fs.chunks.deleteMany({"files_id": file._id});

		// Delete file
		deletedFile = db.fs.files.deleteOne({"filename": file.filename});

		print("deleted " + file.filename + " of type " + file.metadata.type + " with " + deletedChunks.deletedCount + " chunks");
	});

	return count;
}
	
use osm;
// Get array will all k8scluster folders
let k8scluster_folders=[];
db.k8sclusters.find().forEach(function(k8scluster){
	k8scluster_folders.push(k8scluster._id);
});

// Get array with all ns descriptor folders
let nsd_folders=[];
db.nsds.find().forEach(function(nsd){
	nsd_folders.push(nsd._admin.storage.folder);
});

// Get array with all ns record folders
let nsr_folders=[];
db.nsrs.find().forEach(function(nsr){
	nsr_folders.push(nsr._id);
});

// Get array with al vnf descriptor folders
let vnfd_folders=[];
db.vnfds.find().forEach(function(vnfd){
	vnfd_folders.push(vnfd._id);
});

// Get array with al vnf records folders
let vnfr_folders=[];
db.vnfrs.find().forEach(function(vnfr){
	vnfr_folders.push(vnfr._id);
});

// Array of all possible object ids for which a storage folder may exist
var valid_folders=[];
var valid_folders = valid_folders.concat(k8scluster_folders).concat(nsd_folders).concat(nsr_folders).concat(vnfd_folders).concat(vnfr_folders);

use files;
let mongo_folders = [];
db.fs.files.find().forEach(function(file){
	let file_components = file.filename.split("/");
	let folder = file_components[0];
	if (!mongo_folders.includes(folder)){
		mongo_folders.push(folder)
	}
});

// Look for mongo folders that do not correspond to a possible object
let orphan_folders=[];
mongo_folders.forEach(function(mongo_folder){
	if(!valid_folders.includes(mongo_folder)){
		orphan_folders.push(mongo_folder)
	}
});

// Look for mongo files that do not correspond to a possible object
let orphan_files=[];
let mongo_files=[];
db.fs.files.find().forEach(function(file){
	let file_components = file.filename.split("/");
	let folder = file_components[0];
	if (orphan_folders.includes(folder)){
		orphan_files.push(file.filename);
	} 
	mongo_files.push(file.filename);
});

// Execute the specified command
if(action == "all-folders"){
	print("All folders. Found: " + mongo_folders.length);
	mongo_folders;
} else if(action == "all-files"){
	print("All files. Found: " + mongo_files.length);
	mongo_files;
} else if(action == "orphan-folders"){
	print("Orphan Folders. Found: " + orphan_folders.length);
	orphan_folders;
} else if(action == "orphan-files"){
	print("Orphan Files. Found: " + orphan_files.length);
	orphan_files;
} else if(action == "mark-orphans"){
	print("Renaming " + orphan_files.length + " orphan files");
	orphan_files.forEach(function(file){
		setNameAsOrphan(file);
	});
} else if(action == "delete-orphans"){
	print("Deleting orphan files");
	let deleted = deleteOrphans();
	print(deleted + " files deleted");
} else if(action == "revert-orphans"){
	print("Reverting files marked as orphan");
	let reverted = revertOrphans();
	print(reverted + " files reverted");
}

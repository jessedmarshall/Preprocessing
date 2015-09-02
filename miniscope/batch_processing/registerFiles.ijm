// biafra ahanonu
// updated: 2013.09.12 [22:38:38]
// macro to pass command-line inputs to plugin
// TODO: just make this a general macro that accepts two inputs: the plugin to be called and the args. you can split them by comma, e.g.
// java -Dplugins.dir="C:\Program Files\ImageJ" -jar "C:\Program Files\ImageJ\ij.jar" -macro registerFiles.ijm "GCaMP, args"
// changelog
//

macro "registerFiles" {
	// run("Monitor Events...");
	// pass command-line arguments to plugin
	run("mm processMovies 1",getArgument);
}

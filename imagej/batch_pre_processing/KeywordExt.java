import java.io.*;

public class KeywordExt implements FilenameFilter {

	String keyword;
	String ext;

	public KeywordExt(String keyword, String ext) {
		if (!ext.startsWith("."))
			this.ext = "." + ext;
		this.keyword = keyword;
	}

	public boolean accept(File dir, String name) {
		return name.endsWith(ext)&&(-1!=name.indexOf(keyword));
	}

}

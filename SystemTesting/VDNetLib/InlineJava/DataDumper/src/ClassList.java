package dataDumper;

import java.util.ArrayList;

public class ClassList {

	ArrayList<String> classList = new ArrayList<String>();

	public void add(String className){
		classList.add(className);
	}

	public ArrayList<String> getAll(){
		return classList;
	}

	public boolean contains(String className){
		String[] pathElements = className.split("\\.");
		for (String pathElement: pathElements){
			//System.out.println("Path Element: " + pathElement);
			if (classList.contains(pathElement)){
				return true;
			}
		}
		return false;
	}
}

package dataDumper;


import java.lang.reflect.Field;
import java.util.ArrayList;

import org.json.JSONException;
import org.json.JSONObject;

public class DataDumper {

	/**
	 *
	 * @param parseObject: object to be parsed
	 * @param classList: arraylist of strings to look for in full
	 * names of classes you would like parsed further. For e.g.
	 * vcqa or vc
	 * @return string containing the complete dump of elements in the object to be parsed
	 * @throws IllegalArgumentException
	 * @throws IllegalAccessException
	 */
	public static String inspect(Object parseObject, ClassList classList) throws IllegalArgumentException, IllegalAccessException{

		String json = "{";

		for (Field fld : parseObject.getClass().getDeclaredFields()){
			fld.setAccessible(true);
			System.out.println(fld.toString());

			String atr;
			String var;
			try {
				atr = fld.get(parseObject).getClass().getName();
			} catch (Exception e) {
				atr = "";
			}
			var = fld.getName();

			json = json + "\"" + var + "\":";
			String val;

			try {
				val = fld.get(parseObject).toString();
			} catch (Exception e) {
				val = "";
			}

			try{
				java.lang.Iterable obj = (java.lang.Iterable)fld.get(parseObject);
				obj.iterator().hasNext();

				json = json + "[";
				for (Object x:  (java.lang.Iterable)fld.get(parseObject)){

					if (classList.contains(x.getClass().getName())){
						json = json + inspect(x, classList) + ",";
					}
					else{
						json = json + "\"" + x.toString() + "\",";
					}
				}
				json = json + "],";
			}
			catch(Exception e){
				if (fld.get(parseObject) == null)
				{
					json = json + "\"\",";
				}
				else
				{
					if (fld.get(parseObject).getClass().isArray())
					{
						json = json + "[";
						for (Object x: (Object[])fld.get(parseObject))
						{
							if (x == null)
							{
								json = json + "\"\",";
							}
							else
							{
								if (classList.contains(x.getClass().getName()))
								{
									json = json + inspect(x, classList) + ",";
								}
								else
								{
									json = json + "\"" + x.toString() + "\",";
								}
							}
						}
						json = json + "],";
					}
					else
					{
						if (classList.contains(atr))
						{
							System.out.println(fld.get(parseObject));
							json = json + inspect(fld.get(parseObject), classList) + ",";
						}
						else
						{
							json = json + "\"" + val + "\",";
						}
					}
				}
			}
		}
		json = json + "}";

		String json1 = json.replaceAll(",}","}");
		String json2 = json1.replaceAll(",]","]");
		return json2;
	}
}

public class DeXiami {
	public static void main (String [] args) throws Exception
	{
		String code = args[0];
		int i2 = Integer.parseInt(code.substring(0, 1));
		code = code.substring(1);
		int i4 = code.length() / i2;
		int i5 = code.length() % i2;
		String [] arr = new String [i2];

		for (int count = 0; count < i5; count ++)
			arr[count] = code.substring((i4 + 1) * count, (i4 + 1) * (count + 1));
		for (int count = i5; count < i2; count ++)
			arr[count] = code.substring(i4 * count + i5, i4 * (count + 1) + i5);
			//arr[count] = code.substring(i4 * (count - i5) + (i4 + 1) * i5, i4 * (count - i5 + 1) + (i4 + 1) * i5);

		String txt = "";
		for (int count = 0; count < i4 + 1; count ++) {
			for (int j = 0; j < i2; j ++) {
				if (count < arr[j].length())
					txt += arr[j].charAt(count);
			}
		}
		txt = java.net.URLDecoder.decode(txt, "UTF-8");
		txt = txt.replace('^', '0');
		txt = txt.replace('+', ' ');
		System.out.println(txt);
	}
}

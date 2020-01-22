
////////////////////////////////////////////////////////////////////////////////
// STRING PROCEDURES AND FUNCTIONS

//Returns a string array that contains the substrings in input parameter 
//      that are delimited by a specified string.
//      Example,
//      Split(",one,,,two", ",") returns array of 5 elements. Three of them are empty strings. 
//      Split(" one   two", " ") returns array of 2 elements
//
//  Parameters:
//      Str -          string to split
//      Separator  -   delimiter string
//
//  returns:
//      array of substrings
//
Function Split(Val Str, Splitter = ",") Export
	
	ArraySubstrings = New Array();
	If Splitter = " " Then
		Str = TrimAll(Str);
		While 1 = 1 Do
			Pos = Find(Str, Splitter);
			If Pos = 0 Then
				ArraySubstrings.Add(Str);
				Return ArraySubstrings;
			EndIf;
			ArraySubstrings.Add(Left(Str, Pos - 1));
			Str = TrimL(Mid(Str, Pos));
		EndDo;
	Else
		SeparatorLength = StrLen(Splitter);
		While 1 = 1 Do
			Pos = Find(Str, Splitter);
			If Pos = 0 Then
				ArraySubstrings.Add(Str);
				Return ArraySubstrings;
			EndIf;
			ArraySubstrings.Add(Left(Str, Pos - 1));
			Str = Mid(Str, Pos + SeparatorLength);
		EndDo;
	EndIf;
	
EndFunction 




// Replaces the format item in a specified String with the up to 10 text equivalents.
// Parameters are specified as %<index>.
//
// Parameters:
//  Format  – String – string template with parameters %<index>.
// Parameter<n> - String - Parameter
// Returns:
//   String – string with replaced parameters
//
// Example:
// String = Format(НСтр("en='%1 and %2'"), "Parameter1", "Parameter2");
//
Function FormatString(Val Format,
								   Val Parameter1,
								   Val Parameter2 = Undefined,
								   Val Parameter3 = Undefined,
								   Val Parameter4 = Undefined,
								   Val Parameter5 = Undefined,
								   Val Parameter6 = Undefined,
								   Val Parameter7 = Undefined,
								   Val Parameter8 = Undefined,
								   Val Parameter9 = Undefined,
								   Val Parameter10 = Undefined) Export
	
	ResultString = Format;
	
	ResultString = StrReplace(ResultString, "%1", Parameter1);
	
	If Parameter2 <> Undefined Then
		ResultString = StrReplace(ResultString, "%2", Parameter2);
	EndIf;
	
	If Parameter3 <> Undefined Then
		ResultString = StrReplace(ResultString, "%3", Parameter3);
	EndIf;
	
	If Parameter4 <> Undefined Then
		ResultString = StrReplace(ResultString, "%4", Parameter4);
	EndIf;
	
	If Parameter5 <> Undefined Then
		ResultString = StrReplace(ResultString, "%5", Parameter5);
	EndIf;
	
	If Parameter6 <> Undefined Then
		ResultString = StrReplace(ResultString, "%6", Parameter6);
	EndIf;
	
	If Parameter7 <> Undefined Then
		ResultString = StrReplace(ResultString, "%7", Parameter7);
	EndIf;
	
	If Parameter8 <> Undefined Then
		ResultString = StrReplace(ResultString, "%8", Parameter8);
	EndIf;
	
	If Parameter9 <> Undefined Then
		ResultString = StrReplace(ResultString, "%9", Parameter9);
	EndIf;
	
	If Parameter10 <> Undefined Then
		ResultString = StrReplace(ResultString, "%10", Parameter10);
	EndIf;
	
	Return ResultString;
	
EndFunction





// Indicates whether a string contains decimal digits.
//
// Parameters:
//  StringToCheck - string to check.
//  AllowLeadingZeros - Boolean - allow leading zeros or not.
//  AllowSpaces - Boolean - space characters are available.
//
// Returns:
//  True       - string contains digits only;
//  False      - string does not contain digits only.
//
Function IsDigitString(Val StringToCheck, Val AllowLeadingZeros = True, Val AllowSpaces = True) Export
	
	If TypeOf(StringToCheck) <> Type("String") Then
		Return False;
	EndIf;
	
	If NOT ValueIsFilled(StringToCheck) Then
		Return True;
	EndIf;
	
	If NOT AllowSpaces Then
		StringToCheck = StrReplace(StringToCheck, " ", "");
	EndIf;
	
	If NOT AllowLeadingZeros Then
		FirstDigitPosition = 0;
		For a = 1 To StrLen(StringToCheck) Do
			FirstDigitPosition = FirstDigitPosition + 1;
			CharCode = CharCode(Mid(StringToCheck, a, 1));
			If CharCode <> 48 Then
				Break;
			EndIf;
		EndDo;
		StringToCheck = Mid(StringToCheck, FirstDigitPosition);
	EndIf;
	
	For a = 1 To StrLen(StringToCheck) Do
		CharCode = CharCode(Mid(StringToCheck, a, 1));
		If NOT (CharCode >= 48 AND CharCode <= 57) Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction // IsDigitString()




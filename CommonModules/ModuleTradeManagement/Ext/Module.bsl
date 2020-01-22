
// Function builds text to show tabular section messages
//
// Parameters:
//  TabularSectionName - String. Tabular section name.
//  LineNumber - Number. Tabular sectin line number.
//  AttributeName - String. Attribute name.
//
// Returns:
//  String.
//
Function GetMessageByTabularSectionRow(TabularSectionName, LineNumber, AttributeName) Export

	Return TabularSectionName + "[" + Format(LineNumber - 1, "NZ=0; NG=0") + "]." + AttributeName;

EndFunction // GetMessageByTabularSectionRow()





Function GetObjectAttributeValues(Reference, FieldStructure) Export

	Result = New Structure;
	For each KeyAndValue In FieldStructure Do
		Result.Insert(KeyAndValue.Key);
	EndDo;

	QueryText = "";
	
	MetadataObject = Reference.Metadata();

	For each Item In FieldStructure Do
		
		FieldName = Item.Value;
		
		If NOT ValueIsFilled(FieldName) Then
			FieldName = TrimAll(Item.Key);
		EndIf;
		
		QueryText  = QueryText + ?(IsBlankString(QueryText), "", ",") + "
		|	" + FieldName + " AS " + TrimAll(Item.Key);
	EndDo;

	Query = New Query();

	Query.Text =
	"SELECT ALLOWED" + QueryText + "
	|FROM
	|	" + MetadataObject.FullName() + " AS ObjectTable
	|WHERE
	|	Ref = &Reference";

	Query.SetParameter("Reference" , Reference);

	Selection = Query.Execute().Choose();
	
	If Selection.Next() Then
		For each KeyAndValue In FieldStructure Do
			Result[KeyAndValue.Key] = Selection[KeyAndValue.Key];
		EndDo;
	EndIf;
	
	Return Result;

EndFunction





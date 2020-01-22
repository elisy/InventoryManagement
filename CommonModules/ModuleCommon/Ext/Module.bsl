
// Builds object table request using input structure
//
// Parameters:
//  Reference       - object reference.
//  FieldStructure - structure, key is the request field alias, value is the request string.
//
// Returns:
//  Structure containing request results with input fields.
//
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
		|	TableObject." + FieldName + " AS " + TrimAll(Item.Key);
	EndDo;

	Query = New Query();

	Query.Text =
	"SELECT ALLOWED" + QueryText + "
	|FROM
	|	" + MetadataObject.FullName() + " AS TableObject
	|WHERE
	|	TableObject.Ref = &Reference";

	Query.SetParameter("Reference" , Reference);

	Selection = Query.Execute().Choose();
	
	If Selection.Next() Then
		For each KeyAndValue In FieldStructure Do
			Result[KeyAndValue.Key] = Selection[KeyAndValue.Key];
		EndDo;
	EndIf;
	
	Return Result;

EndFunction



// Get attribute value by reference
//
Function GetAttributeValue(Reference, AttributeName) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Table." + AttributeName + " AS Attribute
	|FROM
	|	" + Reference.Metadata().FullName() + " AS Table
	|WHERE
	|	Table.Ref = &Reference";
	Query.SetParameter("Reference", Reference);
	
	Selection = Query.Execute().Choose();
	Selection.Next();
	Return Selection.Attribute;
	
EndFunction





// Check if type description consists of single value type and matches it.
//
// Returns:
//   Boolean      - Contains or not
//
Function TypeDescriptionConsistsOfType(TypeDescription, ValueType) Export
	
	If TypeDescription.Types().Count() = 1 Then
		If TypeDescription.Types().Get(0) = ValueType Then
			Return True;
		EndIf;
	EndIf;
	
	Return False;

EndFunction





// Returns object mamager by reference.
// Does not process Route Points.
Function ObjectManagerByReference(Reference) Export
	ObjectName = Reference.Metadata().Name;
	ReferenceType = TypeOf(Reference);
	If Catalogs.AllRefsType().ContainsType(ReferenceType) Then
		Return Catalogs[ObjectName];

	ElsIf Documents.AllRefsType().ContainsType(ReferenceType) Then
		Return Documents[ObjectName];

	ElsIf BusinessProcesses.AllRefsType().ContainsType(ReferenceType) Then
		Return BusinessProcesses[ObjectName];

	ElsIf ChartsOfCharacteristicTypes.AllRefsType().ContainsType(ReferenceType) Then
		Return ChartsOfCharacteristicTypes[ObjectName];

	ElsIf ChartsOfAccounts.AllRefsType().ContainsType(ReferenceType) Then
		Return ChartsOfAccounts[ObjectName];

	ElsIf ChartsOfCalculationTypes.AllRefsType().ContainsType(ReferenceType) Then
		Return ChartsOfCalculationTypes[ObjectName];

	ElsIf Tasks.AllRefsType().ContainsType(ReferenceType) Then
		Return Tasks[ObjectName];

	ElsIf ExchangePlans.AllRefsType().ContainsType(ReferenceType) Then
		Return ExchangePlans[ObjectName];

	ElsIf Enums.AllRefsType().ContainsType(ReferenceType) Then
		Return Enums[ObjectName];

	Else
		Return Undefined;

	EndIf;
	
EndFunction


// Function reads XML from string parameter and fills value table 
// with column from XML description.
//
Function ReadXMLIntoTable(TextXML) Export
	
	Reader = New XMLReader;
	Reader.SetString(TextXML);
	
	// Read the first node and check it
	If NOT Reader.Read() Then
		Raise("Empty XML");
	ElsIf Reader.Name <> "Items" Then
		Raise("XML error structure");
	EndIf;
	
	// Get table description and create it
	TableName = Reader.GetAttribute("Description");
	ColumnNames = StrReplace(Reader.GetAttribute("Columns"), ",", Chars.LF);
	ColumnCount = StrLineCount(ColumnNames);
	
	Table = New ValueTable;
	For Inxex = 1 To ColumnCount Do
		Table.Columns.Add(StrGetLine(ColumnNames, Inxex), New TypeDescription("String"));
	EndDo;
	
	// Fill table values
	While Reader.Read() Do
		
		If Reader.NodeType <> XMLNodeType.StartElement Then
			Continue;
		ElsIf Reader.Name <> "Item" Then
			Raise("en = 'Error in XML structure'; ru = 'Ошибка в структуре XML'""");
		EndIf;
		
		newString = Table.Add();
		For Inxex = 1 To ColumnCount Do
			ColumnName = StrGetLine(ColumnNames, Inxex);
			newString[Inxex - 1] = Reader.GetAttribute(ColumnName);
		EndDo;
		
	EndDo;
	
	// Fill results
	Result = New Structure;
	Result.Insert("TableName", TableName);
	Result.Insert("Data", Table);
	
	Return Result;
	
EndFunction





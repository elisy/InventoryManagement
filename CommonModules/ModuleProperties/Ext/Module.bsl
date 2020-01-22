
////////////////////////////////////////////////////////////////////////////////
// EXPORT PROCEDURES AND FUNCTIONS

// Is called from OnCreateAtServer form event handler
Procedure OnCreateAtServer(ThisForm, Object, ContainerControlName, PropertySet = Undefined) Export
	
	// Create form main objects
	CreateFormMainObjects(ThisForm, ContainerControlName, PropertySet);
	
	// Check if enable properties functional option is enabled
	If NOT ThisForm.__Properties_EnableProperties Then
		Return;
	EndIf;
	
	// Get object property set
	If PropertySet = Undefined Then
		ThisForm.__Properties_MainList = GetObjectMainPropertySet(Object.Ref);
	Else
		ThisForm.__Properties_MainList = PropertySet;
	EndIf;
	
	// Create additional attributes and place them on the form
	FillAdditionalFormAttributes(ThisForm, Object, PropertySet);
	
EndProcedure


// Procedure is called from BeforeWriteAtServer form event handler
Procedure BeforeWriteAtServer(ThisForm, CurrentObject) Export
	
	If ThisForm.__Properties_EnableProperties Then
		// Transfer property values from attributes into object
		TransferPropertyValuesFromFormAttributes(ThisForm, CurrentObject);
	EndIf;
	
EndProcedure


// Refreshes property data on the form
Procedure RefreshAdditionalPropertyControls(ThisForm, Object, PropertySet = Undefined) Export
	
	// Transfer additional property values from form attributes
	TransferPropertyValuesFromFormAttributes(ThisForm, Object);
	
	// Create attributes and place them on the form
	FillAdditionalFormAttributes(ThisForm, Object, PropertySet)
	
EndProcedure


// Get filled object property values table
Function GetPropertyValuesTable(AdditionalProperties, List, IsAdditionalInformation) Export
	
	arrayProperties = AdditionalProperties.UnloadColumn("Property");
	
	QueryText =
	"SELECT
	|	PropertySetsContent.Property,
	|	MIN(PropertySetsContent.LineNumber) AS Order
	|INTO ListProperties
	|FROM
	|	Catalog.PropertySets.Content AS PropertySetsContent
	|WHERE
	|	PropertySetsContent.Ref IN(&List)
	|	AND (NOT PropertySetsContent.Ref.DeletionMark)
	|	AND (NOT PropertySetsContent.Ref.IsFolder)
	|	AND PropertySetsContent.Property.IsAdditionalInformation = &IsAdditionalInformation
	|
	|GROUP BY
	|	PropertySetsContent.Property
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AdditionalPropertiesAndInformation.Ref AS Property
	|INTO FilledProperties
	|FROM
	|	ChartOfCharacteristicTypes.AdditionalPropertiesAndInformation AS AdditionalPropertiesAndInformation
	|WHERE
	|	AdditionalPropertiesAndInformation.Ref IN(&arrayProperties)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ListProperties.Property,
	|	ListProperties.Order,
	|	FALSE AS IsDeleted
	|INTO AllProperties
	|FROM
	|	ListProperties AS ListProperties
	|
	|UNION ALL
	|
	|SELECT
	|	FilledProperties.Property,
	|	0,
	|	TRUE
	|FROM
	|	FilledProperties AS FilledProperties
	|		LEFT JOIN ListProperties AS ListProperties
	|		ON FilledProperties.Property = ListProperties.Property
	|WHERE
	|	ListProperties.Property IS NULL 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllProperties.Property,
	|	AdditionalPropertiesAndInformation.Description,
	|	AdditionalPropertiesAndInformation.ValueType,
	|	AllProperties.IsDeleted AS IsDeleted
	|FROM
	|	AllProperties AS AllProperties
	|		INNER JOIN ChartOfCharacteristicTypes.AdditionalPropertiesAndInformation AS AdditionalPropertiesAndInformation
	|		ON AllProperties.Property = AdditionalPropertiesAndInformation.Ref
	|
	|ORDER BY
	|	IsDeleted,
	|	AllProperties.Order";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("IsAdditionalInformation", IsAdditionalInformation);
	Query.SetParameter("arrayProperties", arrayProperties);
	Query.SetParameter("List", List);
	
	PropertyTable = Query.Execute().Unload();
	PropertyTable.Indexes.Add("Property");
	PropertyTable.Columns.Add("Value");
	
	For each Row In AdditionalProperties Do
		PropertyRow = PropertyTable.Find(Row.Property, "Property");
		If PropertyRow <> Undefined Then
			PropertyRow.Value = Row.Value;
		EndIf;
	EndDo;
	
	Return PropertyTable;
	
EndFunction


////////////////////////////////////////////////////////////////////////////////
// SERVICE FUNCTION AND PROCEDURES

// Get object property set by object reference.
// For example calling the function with Files catalog reference it returns
// Catalog_Files predefined item.
//
Function GetObjectMainPropertySet(Reference)
	
	ReferenceType = TypeOf(Reference);
	
	GroupName = "";
	If Catalogs.AllRefsType().ContainsType(ReferenceType) Then
		If IsFolder(Reference) Then
			Return Undefined;
		EndIf;
		GroupName = "Catalog";
		
	ElsIf Documents.AllRefsType().ContainsType(ReferenceType) Then
		GroupName = "Document";
		
	ElsIf ChartsOfCharacteristicTypes.AllRefsType().ContainsType(ReferenceType) Then
		If IsFolder(Reference) Then
			Return Undefined;
		EndIf;
		GroupName = "ChartOfCharacteristicTypes";
		
	ElsIf ChartsOfAccounts.AllRefsType().ContainsType(ReferenceType) Then
		GroupName = "ChartOfAccounts";
		
	ElsIf ChartsOfCalculationTypes.AllRefsType().ContainsType(ReferenceType) Then
		GroupName = "ChartOfCalculationTypes";
		
	ElsIf BusinessProcesses.AllRefsType().ContainsType(ReferenceType) Then
		GroupName = "BusinessProcess";
		
	ElsIf Tasks.AllRefsType().ContainsType(ReferenceType) Then
		GroupName = "Task";
		
	EndIf;
		
	
	ItemName = GroupName + "_" + Reference.Metadata().Name;
	Return Catalogs.PropertySets[ItemName];
	
EndFunction



// Checks if the refereince is a folder
Function IsFolder(Reference)
	
	If NOT ValueIsFilled(Reference) Then
		Return False;
	EndIf;
	
	ObjectMetadata = Reference.Metadata();
	If ObjectMetadata.Hierarchical AND ObjectMetadata.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then
		Return ModuleCommon.GetAttributeValue(Reference, "IsFolder");
	Else
		Return False;
	EndIf;
	
EndFunction



// Create main form objects (properties, commands, controls) supporting properties
Procedure CreateFormMainObjects(ThisForm, ContainerControlName, PropertySet)
	
	arrayAttributes = New Array;
	
	// Check Enable Properties functional option
	OptionEnableProperties = ThisForm.GetFormFunctionalOption("EnableProperties");
	AttributeEnableProperties = New FormAttribute("__Properties_EnableProperties", New TypeDescription("Boolean"));
	arrayAttributes.Add(AttributeEnableProperties);
	
	If OptionEnableProperties Then
		
		// Add Main List attribute
		TypeName = ?(TypeOf(PropertySet) = Type("ValueList"), "ValueList", "CatalogRef.PropertySets");
		AttributeMainList = New FormAttribute("__Properties_MainList", New TypeDescription(TypeName));
		arrayAttributes.Add(AttributeMainList);
		
		// Add "AdditionalPropertyDesctiption" value table and columns
		DesctiptionName = "__Properties_AdditionalPropertyDesctiption";
		AttributeDescription_0 = New FormAttribute(DesctiptionName,         New TypeDescription("ValueTable"));
		AttributeDescription_1 = New FormAttribute("ValueAttributeName",    New TypeDescription("String"), DesctiptionName);
		AttributeDescription_2 = New FormAttribute("PropertyAttributeName", New TypeDescription("String"), DesctiptionName);
		AttributeDescription_3 = New FormAttribute("Property",              New TypeDescription("ChartOfCharacteristicTypesRef.AdditionalPropertiesAndInformation"), DesctiptionName);
		arrayAttributes.Add(AttributeDescription_0);
		arrayAttributes.Add(AttributeDescription_1);
		arrayAttributes.Add(AttributeDescription_2);
		arrayAttributes.Add(AttributeDescription_3);
		
		// Add property UI control name attribute
		AttributeControlName = New FormAttribute("__Properties_ContainerControlName", New TypeDescription("String"));
		arrayAttributes.Add(AttributeControlName);
		
	EndIf;
	
	ThisForm.ChangeAttributes(arrayAttributes);
	ThisForm.__Properties_EnableProperties = OptionEnableProperties;
	If OptionEnableProperties Then
		ThisForm.__Properties_ContainerControlName = ContainerControlName;
	EndIf;
	
EndProcedure


// Create additional attributes and place them on the form
Procedure FillAdditionalFormAttributes(ThisForm, Object, PropertySet)
	
	If PropertySet = Undefined Then
		List = ThisForm.__Properties_MainList;
	Else
		List = PropertySet;
	EndIf;
	
	Table = GetPropertyValuesTable(Object.UserDefinedProperties.Unload(), List, False);
	Table.Columns.Add("ValueAttributeName");
	Table.Columns.Add("PropertyAttributeName");
	Table.Columns.Add("Boolean");
	
	DeleteOldAttributes(ThisForm);
	ThisForm.__Properties_AdditionalPropertyDesctiption.Clear();
	
	// Create attributes
	Index = 0;
	NewAttributes = New Array();
	For each RowAttribute In Table Do
		
		Index = Index + 1;
		PropertyValueType = RowAttribute.ValueType;
		
		RowAttribute.ValueAttributeName = "AdditionalAttributeValue" + Format(Index, NStr("en = 'NG=0'; ru = 'ЧГ=0'"));
		Attribute = New FormAttribute(RowAttribute.ValueAttributeName, PropertyValueType, , RowAttribute.Description, True);
		NewAttributes.Add(Attribute);
		
		RowAttribute.PropertyAttributeName = "";
		If ValueTypeContainsPropertyValues(PropertyValueType) Then
			RowAttribute.PropertyAttributeName = "AdditionalAttributeProperty" + Format(Index, NStr("en = 'NG=0'; ru = 'ЧГ=0'"));
			Attribute = New FormAttribute(RowAttribute.PropertyAttributeName, New TypeDescription("ChartOfCharacteristicTypesRef.AdditionalPropertiesAndInformation"), , , True);
			NewAttributes.Add(Attribute);
		EndIf;
		
		RowAttribute.Boolean = ModuleCommon.TypeDescriptionConsistsOfType(PropertyValueType, Type("Boolean"));
		
	EndDo;
	ThisForm.ChangeAttributes(NewAttributes);
	
	// Create form controls
	For each RowAttribute In Table Do
		
		NewRow = ThisForm.__Properties_AdditionalPropertyDesctiption.Add();
		NewRow.ValueAttributeName    = RowAttribute.ValueAttributeName;
		NewRow.PropertyAttributeName = RowAttribute.PropertyAttributeName;
		NewRow.Property              = RowAttribute.Property;
		
		ThisForm[RowAttribute.ValueAttributeName] = RowAttribute.Value;
		
		ContainerControlName = ThisForm.__Properties_ContainerControlName;
		Parent = ?(ContainerControlName = "", Undefined, ThisForm.Items[ContainerControlName]);
		Control = ThisForm.Items.Add(RowAttribute.ValueAttributeName, Type("FormField"), Parent);
		Control.Type = ?(RowAttribute.Boolean, FormFieldType.CheckBoxField, FormFieldType.InputField);
		Control.DataPath = RowAttribute.ValueAttributeName;
		
		If RowAttribute.IsDeleted Then
			Control.TitleTextColor = New Color(255, 0, 0);
			Control.TitleFont = New Font(Control.TitleFont, ,,,,,True);
		EndIf;
		
		If RowAttribute.PropertyAttributeName <> "" Then
			Link = New ChoiceParameterLink("Filter.Owner", RowAttribute.PropertyAttributeName);
			arrayLinks = New Array;
			arrayLinks.Add(Link);
			Control.ChoiceParameterLinks = New FixedArray(arrayLinks);
			ThisForm[RowAttribute.PropertyAttributeName] = RowAttribute.Property;
		EndIf;
		
	EndDo;
	
EndProcedure


// Transfer property values from form attributes into object value type
Procedure TransferPropertyValuesFromFormAttributes(ThisForm, Object)
	
	Object.UserDefinedProperties.Clear();
	
	For each Row In ThisForm.__Properties_AdditionalPropertyDesctiption Do
		Value = ThisForm[Row.ValueAttributeName];
		If ValueIsFilled(Value) Then
			If TypeOf(Value) = Type("Boolean") AND Value = False Then
				Continue;
			EndIf;
			
			newRow = Object.UserDefinedProperties.Add();
			newRow.Property = Row.Property;
			newRow.Value = Value;
		EndIf;
	EndDo;
	
EndProcedure



// Clear old form attributes and controls
Procedure DeleteOldAttributes(ThisForm)
	
	// Delete old attributes and controls
	arrayDelete = New Array;
	For each AttributeRow In ThisForm.__Properties_AdditionalPropertyDesctiption Do
		
		arrayDelete.Add(AttributeRow.ValueAttributeName);
		If NOT IsBlankString(AttributeRow.PropertyAttributeName) Then
			arrayDelete.Add(AttributeRow.PropertyAttributeName);
		EndIf;
		
		ThisForm.Items.Delete(ThisForm.Items[AttributeRow.ValueAttributeName]);
		
	EndDo;
	
	If arrayDelete.Count() Then
		ThisForm.ChangeAttributes(, arrayDelete);
	EndIf;
	
EndProcedure



// Check if property value type contains catalog PropertyValues reference
Function ValueTypeContainsPropertyValues(ValueType)
	
	Return ValueType.Types().Find(Type("CatalogRef.PropertyValues")) <> Undefined;
	
EndFunction



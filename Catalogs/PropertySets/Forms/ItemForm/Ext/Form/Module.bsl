
////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.Predefined Then
		Items.Description.ReadOnly = True;
	EndIf;
	
	PropertyListHasBeenWritten = False;
	
	PropertyTree.Parameters.SetParameterValue("arraySelected", Object.Content.Unload().UnloadColumn("Property"));
	
	If Object.Content.Count() > 0 Then
		
		ValueTable = New ValueTable;
		ValueTable.Columns.Add("RowNumber", New TypeDescription("Number"));
		ValueTable.Columns.Add("AdditionalProperty", New TypeDescription("ChartOfCharacteristicTypesRef.AdditionalPropertiesAndInformation"));
		
		RowNumber = 0;
		For each Row In Object.Content Do
			RowNumber = RowNumber + 1;
			newRow = ValueTable.Add();
			newRow.RowNumber = RowNumber;
			newRow.RowNumber = Row.Property;
		EndDo;
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	Content.AdditionalProperty,
		|	Content.RowNumber
		|INTO Content
		|FROM
		|	&Content AS Content
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Content.AdditionalProperty,
		|	AdditionalPropertiesAndInformation.IsAdditionalInformation
		|FROM
		|	ChartOfCharacteristicTypes.AdditionalPropertiesAndInformation AS AdditionalPropertiesAndInformation
		|		INNER JOIN Content AS Content
		|		ON AdditionalPropertiesAndInformation.Ref = Content.AdditionalProperty
		|
		|ORDER BY
		|	Content.RowNumber";
		Query.SetParameter("Content", ValueTable);
		Selection = Query.Execute().Choose();
		
		While Selection.Next() Do
			newRow = ?(Selection.IsAdditionalInformation, TableInformation.Add(), TableAttributes.Add());
			newRow.Property = Selection.AdditionalProperty;
		EndDo;
		
	EndIf;
	
EndProcedure


&AtClient
Procedure OnOpen(Cancel)
	
	RefreshDataRepresentation();
	
EndProcedure


&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "OnAdditionalPropertyWritten" Then
		CheckTableContentsAfterPropertyHasBeenWritten(Parameter);
	EndIf;
	
EndProcedure



&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.Content.Clear();
	
	For each Row In TableAttributes Do
		newRow = CurrentObject.Content.Add();
		newRow.Property = Row.Property;
	EndDo;
	
	For each Row In TableInformation Do
		newRow = CurrentObject.Content.Add();
		newRow.Property = Row.Property;
	EndDo;
	
	PropertyListHasBeenWritten = True;
	
EndProcedure


&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If PropertySetHasBeenWritten Then
		Notify("OnPropertyListChanged", Object.Ref);
	EndIf;

EndProcedure




////////////////////////////////////////////////////////////////////////////////
// FORM CONTROL EVENT HANDLERS

&AtClient
Procedure OnAddProperty(Command)
	AddProperty();
EndProcedure


&AtClient
Procedure TableAttributesSelection(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	Items.PropertyTree.CurrentRow = Item.CurrentData.Property;
EndProcedure

&AtClient
Procedure TableAttributesAfterDeleteRow(Item)
	RefreshSelected();
EndProcedure

&AtClient
Procedure TableAttributesBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	Cancel = True;
EndProcedure

&AtClient
Procedure TableInformationSelection(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	Items.PropertyTree.CurrentRow = Item.CurrentData.Property;
EndProcedure

&AtClient
Procedure PropertyTreeSelection(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	AddProperty();
EndProcedure

&AtClient
Procedure PropertyTreeBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	If Items.PropertyTree.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If (Items.PropertyTree.CurrentData.InformationIconNumber % 3 = 0) Then
		FormName = "GroupForm";
	Else
		FormName = "ItemForm";
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("Key", Items.PropertyTree.CurrentRow);
	Parameters.Insert("FromPropertyList", True);
	OpenForm("ChartOfCharacteristicTypes.AdditionalPropertiesAndInformation.Form." + FormName, Parameters);
	
EndProcedure

&AtClient
Procedure PropertyTreeBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	// Standard processint if itme is Group
	If Folder = True Then
		Return;
	ElsIf Clone AND (Items.PropertyTree.CurrentData.InformationIconNumber % 3 = 0) Then
		Return;
	EndIf;
	
	Cancel = True;
	Parameters = New Structure;
	
	Parameters.Insert("FromPropertyList", True);
	If Clone Then
		Parameters.Insert("Cloning", Items.PropertyTree.CurrentRow);
	Else
		Parameters.Insert("Parent", Parent);
	EndIf;
	OpenForm("ChartOfCharacteristicTypes.AdditionalPropertiesAndInformation.Form.ItemForm", Parameters);

EndProcedure


////////////////////////////////////////////////////////////////////////////////
// COMMON PROCEDURES AND FUNCTIONS
 
&AtClient
Procedure RefreshSelected()
	
	arraySelected = New Array;
	
	For each Row In TableAttributes Do
		arraySelected.Add(Row.Property);
	EndDo;
	
	For each Row In TableInformation Do
		arraySelected.Add(Row.Property);
	EndDo;
	
	PropertyTree.Parameters.SetParameterValue("arraySelected", arraySelected);
	
EndProcedure


&AtClient
Procedure SetCurrentInTable(Table, Item, Property)
	
	If Property = Undefined Then
		Return;
	EndIf;
	
	Filter = New Structure("Property", Property);
	Rows = Table.FindRows(Filter);
	If Rows.Count() <> 0 Then
		Item.CurrentRow = Table.IndexOf(Rows[0]);
	EndIf;
	
EndProcedure


&AtServerNoContext 
Function AddSelectedProperties(arrayReferences, arrayAttributes, arrayInformation)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	AdditionalPropertiesAndInformation.Ref AS Property
	|INTO Temp
	|FROM
	|	ChartOfCharacteristicTypes.AdditionalPropertiesAndInformation AS AdditionalPropertiesAndInformation
	|WHERE
	|	(AdditionalPropertiesAndInformation.Ref IN (&arrayAttributes)
	|			OR AdditionalPropertiesAndInformation.Ref IN (&arrayInformation))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AdditionalPropertiesAndInformation.Ref,
	|	AdditionalPropertiesAndInformation.IsAdditionalInformation
	|FROM
	|	ChartOfCharacteristicTypes.AdditionalPropertiesAndInformation AS AdditionalPropertiesAndInformation
	|		LEFT JOIN Temp AS Temp
	|		ON AdditionalPropertiesAndInformation.Ref = Temp.Property
	|WHERE
	|	AdditionalPropertiesAndInformation.Ref IN HIERARCHY(&arrayReferences)
	|	AND (NOT AdditionalPropertiesAndInformation.IsFolder)
	|	AND Temp.Property IS NULL 
	|	AND (NOT AdditionalPropertiesAndInformation.DeletionMark)
	|
	|ORDER BY
	|	AdditionalPropertiesAndInformation.Description";
	
	Query.SetParameter("arrayReferences", arrayReferences);
	Query.SetParameter("arrayAttributes", arrayAttributes);
	Query.SetParameter("arrayInformation", arrayInformation);
	
	Selection = Query.Execute().Choose();
	
	arrayAttributes.Clear();
	arrayInformation.Clear();
	
	If Selection.Count() = 0 Then
		Return False;
	EndIf;
	
	While Selection.Next() Do
		
		If Selection.IsAdditionalInformation Then
			arrayInformation.Add(Selection.Ref);
		Else
			arrayAttributes.Add(Selection.Ref);
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction


&AtClient
Procedure AddProperty()
	
	arrayAdd = New Array;
	LastAttribute = Undefined;
	LastInformation = Undefined;

	For each selectedReference In Items.PropertyTree.SelectedRows Do
		Filter = New Structure("Property", selectedReference);
		If TableAttributes.FindRows(Filter).Count() <> 0 Then
			LastAttribute = selectedReference;
		ElsIf TableInformation.FindRows(Filter).Count() <> 0 Then
			LastInformation = selectedReference;
		Else
			arrayAdd.Add(selectedReference);
		EndIf;
	EndDo;
	
	If arrayAdd.Count() > 0 Then
		
		arrayAttributes = New Array;
		For each Row In TableAttributes Do
			arrayAttributes.Add(Row.Property);
		EndDo;
		
		arrayInformation = New Array;
		For each Row In TableInformation Do
			arrayInformation.Add(Row.Property);
		EndDo;
		
		If AddSelectedProperties(arrayAdd, arrayAttributes, arrayInformation) Then
			Modified = True;
			
			For each Property In arrayAttributes Do
				newRow = TableAttributes.Add();
				newRow.Property = Property;
				LastAttribute = Property;
			EndDo;
			
			For each Property In arrayInformation Do
				newRow = TableInformation.Add();
				newRow.Property = Property;
				LastInformation = Property;
			EndDo;
			
		EndIf;
	EndIf;
	
	SetCurrentInTable(TableAttributes, Items.TableAttributes, LastAttribute);
	SetCurrentInTable(TableInformation,  Items.TableInformation,  LastInformation);
	
	RefreshSelected();
	
EndProcedure


&AtClient
Procedure CheckTableContentsAfterPropertyHasBeenWritten(NotificationStructure)
	
	// Check source and destination tables
	If NotificationStructure.IsAdditionalInformation Then
		Table1 = TableInformation;
		Table2 = TableAttributes;
	Else
		Table1 = TableAttributes;
		Table2 = TableInformation;
	EndIf;
	
	// Check if property is included into the source table
	Property = NotificationStructure.Reference;
	Rows = Table2.FindRows(New Structure("Property", Property));
	If Rows.Count() = 0 Then
		Return;
	EndIf;
	
	// Delete from the source table
	Index = Table2.IndexOf(Rows[0]);
	Table2.Delete(Index);
	
	// Add to the destination table
	newRow = Table1.Add();
	newRow.Property = Property;
	
	// Set the appropriate flag
	PropertyListHasBeenWritten = True;
	
EndProcedure



////////////////////////////////////////////////////////////////////////////////
// EXPORT PROCEDURES AND FUNCTIONS

// BeforeWrite event handler
Procedure BeforeWrite(Object, Cancel) Export
	
	// In case of Cancel flag do not process new order
	If Cancel Then
		Return;
	EndIf;
	
	// Check if there is a Row Order attribute of the object
	Info = GetMovementMetadataInfo(Object.Ref);
	If NOT ObjectHasRowOrderAttribute(Object, Info) Then
		Return;
	EndIf;
	
	// Calculate new row order value
	If Object.RowOrder = 0 Then
		Object.RowOrder = GetNewRowOrderValue(Info, Object, "");
	EndIf;
		
EndProcedure


// OnCopy event handler
Procedure OnCopy(Object) Export
	
	Info = GetMovementMetadataInfo(Object.Ref);
	If ObjectHasRowOrderAttribute(Object, Info) Then
		Object.RowOrder = 0;
	EndIf;
	
EndProcedure


// Function moves row up or down
Function ChangeRowOrder(Reference, SetFilters, IsListRepresentation, Single, MoveUp) Export
	
	Info = GetMovementMetadataInfo(Reference);
	
	// Для иерархических справочников может быть установлен отбор по родителю, если нет,
	// то способ отображения должен быть иерархический или в виде дерева
	If Info.HasParent AND IsListRepresentation AND NOT SetFilters.FilterByParentExists Then
		Return NStr("en = 'Please set list representation as tree or hierarchically before moving the rows.'; ru = 'Перед перемещением необходимо установить отображение в виде дерева или иерархического списка!'");
	EndIf;
	
	// Для подчиненных справочников должен быть установлен отбор по владельцу
	If Info.HasOwner AND NOT SetFilters.FilterByOwnerExists Then
		Return NStr("en = 'Please set filter by owner before moving the rows.'; ru = 'Перед перемещением необходимо установить отбор по владельцу!'");
	EndIf;
	
	If Single Then
		// Check if the selected object has Row Order attribute
		If Info.HasFolders Then
			IsFolder = ModuleCommon.GetAttributeValue(Reference, "IsFolder");
			If IsFolder AND NOT Info.ForFolders Then
				// It's a folder and there is no row order for groups
				Return "";
			ElsIf NOT IsFolder AND NOT Info.ForItems Then
				// It's an item and there is no row order for items
				Return "";
			EndIf;
		EndIf;
	EndIf;
	
	Query = New Query;
	arrayContitions = New Array;
	
	// Add contigion by the parent
	If Info.HasParent Then
		arrayContitions.Add("Table.Parent = &Parent");
		Query.SetParameter("Parent", ModuleCommon.GetAttributeValue(Reference, "Parent"));
	EndIf;
	
	//Add condition by the ownter
	If Info.HasOwner Then
		arrayContitions.Add("Table.Owner = &Owner");
		Query.SetParameter("Owner", ModuleCommon.GetAttributeValue(Reference, "Owner"));
	EndIf;
	
	// And folder condition
	If Info.HasFolders Then
		If Info.ForFolders AND NOT Info.ForItems Then
			arrayContitions.Add("Table.IsFolder");
		ElsIf NOT Info.ForFolders AND Info.ForItems Then
			arrayContitions.Add("NOT Table.IsFolder");
		EndIf;
	EndIf;
	
	// Add condition by row order attribute
	If Single Then
		arrayContitions.Add("Table.RowOrder " + ?(MoveUp, "<", ">") + " &RowOrder");
		RowOrder = ModuleCommon.GetAttributeValue(Reference, "RowOrder");
	EndIf;
	
	StringWhereClause = "";
	StringCondition = "
	|WHERE
	|	";
	For each Condition In arrayContitions Do
		StringWhereClause = StringWhereClause + StringCondition + Condition;
		StringCondition = "
		|	AND ";
	EndDo;
	
	
	QueryText = 
	"SELECT" + ?(Single, " TOP 1", "") + "
	|	Table.Ref,
	|	Table.RowOrder КАК RowOrder
	|From
	|	" + Reference.Metadata().FullName() + " AS Table
	|" + StringWhereClause + "
	|
	|ORDER BY
	|	RowOrder";
	
	If Single AND MoveUp Then
		QueryText = QueryText + " Desc";
	EndIf;
	
	
	Query.Text = QueryText;
	Query.SetParameter("RowOrder", RowOrder);
	Selection = Query.Execute().Choose();
	
	mapReplacements = New Map;
	
	If Single Then
		If NOT Selection.Next() Then
			Return "";
		EndIf;
		
		mapReplacements.Insert(Reference,     Selection.RowOrder);
		mapReplacements.Insert(Selection.Ref, Query.Parameters.RowOrder);
	Else
		Order = 0;
		While Selection.Next() Do
			Order = Order + 1;
			If Selection.RowOrder <> Order Then
				mapReplacements.Insert(Selection.Ref, Order);
			EndIf;
		EndDo;
	EndIf;
	
	If mapReplacements.Count() = 0 Then
		Return "";
	EndIf;
	
	BeginTransaction();
	
	For each ItemReplacement In mapReplacements Do
		Object = ItemReplacement.Key.GetObject();
		Object.RowOrder = ItemReplacement.Value;
		Object.Write();
	EndDo;
	
	CommitTransaction();
	
	
	Return "";
	
EndFunction



////////////////////////////////////////////////////////////////////////////////
// GET OBJECT INFORMATION

// Get object metadata information structure
Function GetMovementMetadataInfo(Reference)
	
	Info = New Structure;
	
	ObjectMetadata = Reference.Metadata();
	AttributeMetadata = ObjectMetadata.Attributes.RowOrder;
	
	Info.Insert("FullName", ObjectMetadata.FullName());
	
	IsCatalog                    = Metadata.Catalogs.Contains(ObjectMetadata);
	IsChartOfCharacteristicTypes = Metadata.ChartsOfCharacteristicTypes.Contains(ObjectMetadata);
	
	If IsCatalog OR IsChartOfCharacteristicTypes Then
		
		Info.Insert("HasFolders",   ObjectMetadata.Hierarchical AND ObjectMetadata.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems);
		Info.Insert("ForFolders",   (AttributeMetadata.Use <> Metadata.ObjectProperties.ИспользованиеРеквизита.ForItem));
		Info.Insert("ForItems",     (AttributeMetadata.Use <> Metadata.ObjectProperties.AttributeUse.ForFolder));
		Info.Insert("HasParent",    ObjectMetadata.Hierarchical);
		Info.Insert("FoldersOnTop", ?(NOT Info.HasParent, False, ObjectMetadata.FoldersOnTop));
		Info.Insert("HasOwner",     ?(IsChartOfCharacteristicTypes, False, (ObjectMetadata.Owners.Count() <> 0)));
		
	Else
		
		Info.Insert("HasFolders",   False);
		Info.Insert("ForFolders",   False);
		Info.Insert("ForItems",     True);
		Info.Insert("HasParent",    False);
		Info.Insert("HasOwner",     False);
		Info.Insert("FoldersOnTop", False);
		
	EndIf;
	
	Return Info;
	
EndFunction


// Function checks if the object contains Row Order attribute
Function ObjectHasRowOrderAttribute(Object, Info)
	
	If NOT Info.HasParent Then
		// Catalog is not hierarchical
		Return True;
		
	ElsIf Object.IsFolder AND NOT Info.ForFolders Then
		// It is folder and order cannot be set
		Return False;
		
	ElsIf NOT Object.IsFolder AND NOT Info.ForItems Then
		// It is item and order cannot be set
		Return False;
		
	Else
		Return True;
		
	EndIf;
	
EndFunction


// Get Row Order new value
Function GetNewRowOrderValue(Info, Object, StringConditions)
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	Table.RowOrder AS RowOrder
	|FROM
	|	" + Info.FullName + " AS Table";
	
	If Info.HasParent Then
		StringConditions = StringConditions + ?(StringConditions = "", "", " AND ") + "(Table.Parent = &Parent)";
		Query.SetParameter("Parent", Object.Parent);
	EndIf;
	If Info.HasOwner Then
		StringConditions = StringConditions + ?(StringConditions = "", "", " AND ") + "(Table.Owner = &Owner)";
		Query.SetParameter("Owner", Object.Owner);
	EndIf;
	
	If StringConditions <> "" Then
		Query.Text = Query.Text + "
		|WHERE
		|	" + StringConditions;
	EndIf;


	Query.Text = Query.Text + "
	|
	|ORDER BY
	|	RowOrder DESC
	|";
	
	
	Selection = Query.Execute().Choose();
	
	Selection.Next();
	Return ?(NOT ValueIsFilled(Selection.RowOrder), 1, Selection.RowOrder + 1);
	
EndFunction




Procedure OnWrite(Cancel)
	
	If ValueIsFilled(Parent) Then
		MainObject = Parent.GetObject();
		MainObject.Write();
	EndIf;

EndProcedure

Procedure BeforeWrite(Cancel)

	If NOT IsFolder Then
		
		// Delete doubles and empty strings
		mapSelected = New Map;
		arrayDelete = New Array;
		
		For each Row In Content Do
			If Row.Property.IsEmpty() OR mapSelected.Get(Row.Property) <> Undefined Then
				arrayDelete.Add(Row);
			Else
				mapSelected.Insert(Row.Property, True);
			EndIf;
		EndDo;
		
		For each Row In arrayDelete Do
			mapSelected.Delete(Row);
		EndDo;
		
	ElsIf Predefined Then
		
		// Gather all linked to root lists
		
		Query = New Query;
		Query.Text =
		"SELECT DISTINCT
		|	PropertySetsContent.Property
		|FROM
		|	Catalog.PropertySets.Content AS PropertySetsContent
		|WHERE
		|	PropertySetsContent.Ref.Parent = &Parent";
		
		Query.SetParameter("Parent", Ref);
		
		TableProperties = Query.Execute().Unload();
		Content.Load(TableProperties);
		
	EndIf;
	
EndProcedure




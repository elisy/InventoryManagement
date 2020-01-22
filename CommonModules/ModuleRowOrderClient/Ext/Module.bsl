
////////////////////////////////////////////////////////////////////////////////
// EXPORT PROCEDURES AND FUNCTIONS

Procedure MoveRowUp(ListAttribute, ListControl) Export
	
	MoveRow(ListAttribute, ListControl, True, True);
	
EndProcedure


Procedure MoveRowDown(ListAttribute, ListControl) Export
	
	MoveRow(ListAttribute, ListControl, True, False);
	
EndProcedure


Procedure RestoreRowOrder(ListAttribute, ListControl) Export
	
	MoveRow(ListAttribute, ListControl, False);
	
EndProcedure



////////////////////////////////////////////////////////////////////////////////
// PRIVATE PROCEDURES AND FUNCTIONS


Procedure MoveRow(ListAttribute, ListControl, Single, MoveUp = Undefined)
	
	SetFilters = New Structure;
	
	If NOT CheckList(ListAttribute, ListControl, SetFilters) Then
		Return;
	EndIf;
	
	Reference = ListControl.CurrentRow;
	IsListRepresentation = (ListControl.Representation = TableRepresentation.List);
	
	StringError = ModuleRowOrder.ChangeRowOrder(Reference, SetFilters, IsListRepresentation, Single, MoveUp);
		
	If StringError = "" Then
		ListControl.Refresh();
	Else
		DoMessageBox(StringError);
	EndIf;
	
EndProcedure


// Function checks initial list configuration
Function CheckList(ListAttribute, ListControl, SetFilters)
	
	// Check the current row existance
	If ListControl.CurrentRow = Undefined Then
		Return False;
	EndIf;
	
	// Check set order
	If NOT CheckListOrder(ListAttribute) Then
		DoMessageBox(NStr("en = 'Pleas set list order by Row Order ascending before moving the rows.'; ru = 'Перед изменением порядка элементов необходимо установить сортировку по реквизиту доп. упорядочивания по возрастанию!'"));
		Return False;
	EndIf;
	
	// Check set filters
	If NOT CheckListSetFilters(ListAttribute, SetFilters) Then
		DoMessageBox(NStr("en = 'Invalid filter has been set.'; ru = 'В списке неверно установлен отбор!'"));
		Return False;
	EndIf;
	
	Return True;
	
EndFunction



// Function checks list order
Function CheckListOrder(ListAttribute)
	
	OrderItems = ListAttribute.Order.Items;
	
	// Find the first order item that is in use
	Item = Undefined;
	For each OrderItem In OrderItems Do
		If OrderItem.Use Then
			Item = OrderItem;
			Break;
		EndIf;
	EndDo;
	
	If Item = Undefined Then
		// There is no order
		Return False;
	EndIf;
	
	If TypeOf(Item) = Type("DataCompositionOrderItem") Then
		If Item.OrderType = DataCompositionSortDirection.Asc Then
			AttributeField = New DataCompositionField("RowOrder");
			If Item.Field = AttributeField Then
				Return True;
			EndIf;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction


// Function gets information about set filters and checks them partially
Function CheckListSetFilters(ListAttribute, SetFilters)
	
	SetFilters.Insert("FilterByParentExists",  False);
	SetFilters.Insert("FilterByOwnerExists", False);
	
	FieldParent1 = New DataCompositionField("Родитель");
	FieldParent2 = New DataCompositionField("Parent");
	FieldOwner1  = New DataCompositionField("Владелец");
	FieldOwner2  = New DataCompositionField("Owner");
	
	For each Filter In ListAttribute.Filter.Items Do
		
		If NOT Filter.Use Then
			// Filter is not in use
			Continue;
		ElsIf TypeOf(Filter) <> Type("DataCompositionFilterItem") Then
			// Filter item group is invalid
			Return False;
		ElsIf Filter.ComparisonType <> DataCompositionComparisonType.Equal Then
			// Equal comparison type is valid only
			Return False;
		EndIf;
		
		If (Filter.LeftValue = FieldParent1) OR (Filter.LeftValue = FieldParent2) Then
			// Filter by parent
			SetFilters.FilterByParentExists = True;
		ElsIf (Filter.LeftValue = FieldOwner1) OR (Filter.ЛевоеЗначение = FieldOwner2) Then
			// Filter by owner
			SetFilters.FilterByOwnerExists = True;
		Else
			// The filter is by invalid attribute
			Return False;
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction



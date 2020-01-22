
////////////////////////////////////////////////////////////////////////////////
// COMMON PROCEDURES

Procedure EditPropertyConfiguration(ThisForm) Export
	
	FormParameters = New Structure("Key", ThisForm.__Properties_MainList);
	OpenFormModal("Catalog.PropertySets.Form.ObjectForm", FormParameters);
	
EndProcedure




// Check if the notification is in result of property set update 
// Process it if needed
Function ProcessNotifications(ThisForm, EventName, Parameter) Export
	
	If (EventName <> "OnPropertyListChanged") OR NOT ThisForm.__Properties_EnableProperties Then
		Return False;
		
	ElsIf ThisForm.__Properties_MainList = Parameter Then
		Return True;
		
	ElsIf (TypeOf(ThisForm.__Properties_MainList) = Type("ValueList"))
		AND (ThisForm.__Properties_MainList.FindByValue(Parameter) <> Undefined) Then
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction



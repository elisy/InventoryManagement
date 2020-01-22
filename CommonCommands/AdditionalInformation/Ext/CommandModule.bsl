
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If CommandParameter = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure("Reference", CommandParameter);
	OpenForm("CommonForm.EditPropertyValues", FormParameters, , CommandParameter);

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ModuleKeyAttributes.DisableAttributes(ThisForm);
	
EndProcedure


&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ModuleKeyAttributes.AssignWritingSettings(ThisForm, CurrentObject);
	
EndProcedure


&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ModuleKeyAttributes.DisableAttributes(ThisForm);
	
EndProcedure


// Handler of the command created by Disable Key Attributes system.
//
&AtClient
Procedure EnableKeyAttributes(Command)

	Result = OpenFormModal("Catalog.NomenclatureCategories.Form.KeyAttributes");
	
	If TypeOf(Result) = Type("Array") AND Result.Count() > 0 Then

		ModuleKeyAttributesClient.EnableFormControls(ThisForm, Result);

	EndIf;


EndProcedure




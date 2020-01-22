



// Initialize version control system from the form
//
Procedure OnCreateAtServer(Form) Export
	
	ArrayFormName = ModuleStringFunctionsClientServer.Split(Form.FormName, ".");
	MetadataName = ArrayFormName[0] + "." + ArrayFormName[1];
	Form.SetFormFunctionalOptionParameters(New Structure("ObjectType", MetadataName));
	
EndProcedure



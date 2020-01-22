
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Version control
	ModuleVersionControl.OnCreateAtServer(ThisForm);
	
	// Properties
	PropertySet = ModulePropertiesOverride.GetPropertySetByNomenclatureCategory(Object.Category);
	ModuleProperties.OnCreateAtServer(ThisForm, Object, "AdditionalPropertiesGroup", PropertySet);

	ModuleKeyAttributes.DisableAttributes(ThisForm);
	
EndProcedure


&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
//	Properties
	If ModulePropertiesClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		RefreshAdditionalPropertyControls();
	EndIf;

EndProcedure


&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Properties
	ModuleProperties.BeforeWriteAtServer(ThisForm, CurrentObject);

	ModuleKeyAttributes.AssignWritingSettings(ThisForm, CurrentObject);

EndProcedure


&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ModuleKeyAttributes.DisableAttributes(ThisForm);
	
EndProcedure


&AtServer
Procedure RefreshNomenclatureCategory()

	If Object.Type <> Object.Category.Type Then
		Object.Type = Object.Category.Type;
	EndIf;

EndProcedure


///////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS

&AtClient
Procedure CategoryOnChange(Item)
	
	RefreshAdditionalPropertyControls();

	RefreshNomenclatureCategory();

	EnableAttributes();

EndProcedure


&AtClient
Procedure DescriptionLongStartListChoice(Item, StandardProcessing)
	
	StandardProcessing = False;

	List = New ValueList;
	List.Add(Object.Description);

	Result = ChooseFromList(List, Items.DescriptionLong);
	If Result <> Undefined Then
		Object.DescriptionLong = Result.Value;
		Modified = True;
	EndIf;

EndProcedure


&AtClient
Procedure DescriptionOnChange(Item)
	
	If IsBlankString(Object.DescriptionLong) Then
		Object.DescriptionLong = Object.Description;
	EndIf;

EndProcedure

 
//&AtClient
Procedure EnableAttributes()

	IsProduct = Object.Type = PredefinedValue("Enum.NomenclatureTypes.Product");

	Items.EnableCustomsDeclarations.Enabled = IsProduct;
	Items.EnableSerialNumbers.Enabled = IsProduct;

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// PROPERTY SYSTEM PROCEDURES


&AtClient
Procedure EditPropertyConfiguration(Command)
	
	ModulePropertiesClient.EditPropertyConfiguration(ThisForm);
	
EndProcedure


&AtServer
Procedure RefreshAdditionalPropertyControls()
	
	If ThisForm.__Properties_EnableProperties Then
		PropertySet = ModulePropertiesOverride.GetPropertySetByNomenclatureCategory(Object.Category);
		ModuleProperties.RefreshAdditionalPropertyControls(ThisForm, Object, PropertySet);
	EndIf;
	
EndProcedure



//////////////////////////////////////////////////////////////////////////
// FORM COMMAND HANDLERS

// Handler of the command created by Disable Key Attributes system.
//
&AtClient
Procedure EnableKeyAttributes(Command)

	If NOT Object.Ref.IsEmpty() Then
		Result = OpenFormModal("Catalog.Nomenclature.Form.KeyAttributes");
		If TypeOf(Result) = Type("Array") AND Result.Count() > 0 Then

			ModuleKeyAttributesClient.EnableFormControls(ThisForm, Result);

		EndIf;
	EndIf;

EndProcedure


&AtClient
Procedure OnOpen(Cancel)
	
	EnableAttributes();
	
EndProcedure






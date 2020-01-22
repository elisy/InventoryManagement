// Procedure disables key attributes editing
// Parameters:
//  Form - managed form
//  Reference - InfoBase object reference
//  DisableButtonGroupName - form group to place editing button
Procedure DisableAttributes(Form,
						    DisableButtonGroupName = Undefined) Export
	
	// Check if thf form is ready (required controls and attributes have been created)
	FormIsPrepared = False;
	FormAttributes = Form.GetAttributes();
	For each FormAttribute In FormAttributes Do
		If FormAttribute.Name = "__DisableAttributesParameters" Then
			FormIsPrepared = True;
			Break;
		EndIf;
	EndDo;
	
	If NOT FormIsPrepared Then
		PrepareForm(Form, Form.Object.Ref, DisableButtonGroupName);
	EndIf;
	
	NewObject = Form.Object.Ref.IsEmpty();
	
	// Блокируем ключевые реквизиты
	For each Item In Form.__DisableAttributesParameters Do
		FormControl = Form.Items.Find(Item.Value.ControlName);
		If FormControl <> Undefined Then
			FormControl.ReadOnly = ?(NewObject, False, True);
		EndIf;
		Item.Value.Enabled = ?(NewObject, True, False);
	EndDo;
	
EndProcedure



// Procedure prepares the form to support disable key attributes system.
// Adds attribute __DisableAttributesParameters as FixedMap
//            Key - String - key attribute name
//            Value - Structure:
//               ControlName - String - form control name
//               Presentation - String - user attribute presentation
//               Enable - Boolean - Attribute editing is enabled
//
Procedure PrepareForm(Form, Reference, DisableButtonGroupName = Undefined)
	
	// Add form attribute __DisableAttributesParameters
	NewAttributes = New Array;
	NewAttributes.Add(New FormAttribute("__DisableAttributesParameters", New TypeDescription));
	Form.ChangeAttributes(NewAttributes);
	
	KeyAttributes = ModuleCommon.ObjectManagerByReference(Reference).GetKeyAttributes();
	
	MapDescription = New Map;
	
	For each KeyAttribute In KeyAttributes Do
		MapDescription.Insert(KeyAttribute, New Structure("ControlName,Presentation,Enabled"));
		MapDescription[KeyAttribute].ControlName = GetFormControlNameByAttribute(Form, KeyAttribute);
		
		If MapDescription[KeyAttribute].ControlName <> Undefined Then
			If      ValueIsFilled(Form.Items[MapDescription[KeyAttribute].ControlName].Title) Then
				MapDescription[KeyAttribute].Presentation = Form.Items[MapDescription[KeyAttribute].ControlName].Title;
			ElsIf Reference.Metadata().Attributes.Find(KeyAttribute) <> Undefined
					AND ValueIsFilled(Reference.Metadata().Attributes[KeyAttribute].Synonym) Then
				MapDescription[KeyAttribute].Presentation = Reference.Metadata().Attributes[KeyAttribute].Synonym;
			ElsIf IsStandardAttribute(Reference, KeyAttribute)
					AND ValueIsFilled(Reference.Metadata().StandardAttributes[KeyAttribute].Synonym) Then
				MapDescription[KeyAttribute].Presentation = Reference.Metadata().StandardAttributes[KeyAttribute].Synonym;
			Else
				MapDescription[KeyAttribute].Presentation = MapDescription[KeyAttribute].ControlName;
			EndIf;
		EndIf;
		MapDescription[KeyAttribute].Enabled = False;
	EndDo;
	
	Form.__DisableAttributesParameters = New FixedMap(MapDescription);
	
	// Add form command in case of EditKeyAttributes role
	If IsInRole(Metadata.Roles.EditKeyAttributes)
	   OR AccessRight("Administration", Metadata) Then
		// Add command
		Command = Form.Commands.Add("EnableKeyAttributes");
		Command.Title = NStr("en = 'Enable editing of key attributes'; ru = 'Разрешить редактирование ключевых реквизитов'");
		Command.Action = "EnableKeyAttributes";
		Command.Picture = PictureLib.EnableKeyAttributes;
		
		// Add form button
		If DisableButtonGroupName <> Undefined Then
			ParentGroup = DisableButtonGroupName;
		Else
			ParentGroup = Form.CommandBar;
		EndIf;
		
		Button = Form.Items.Add("EnableKeyAttributes", Type("FormButton"), ParentGroup);
		Button.OnlyInAllActions = True;
		Button.CommandName = "EnableKeyAttributes";
	EndIf;
	
EndProcedure



// Check if the current attribute is a standard object attribute
//
Function IsStandardAttribute(Reference, Name)
	
	For each StandardAttribute In Reference.Metadata().StandardAttributes Do
		If StandardAttribute.Name = Name Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction



// Returns form control name by key attribute name
//
Function GetFormControlNameByAttribute(Form, KeyAttribute)
	
	For each Control In Form.Items Do
		If TypeOf(Control) = Type("FormField") AND Control.Type <> FormFieldType.LabelField Then
			DataPath = ModuleStringFunctionsClientServer.Split(Control.DataPath, ".");
			If DataPath.Count() > 1 AND DataPath[1] = KeyAttribute Then
				Return Control.Name;
			EndIf;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction



// Assigns the object the settings of attribute editing
//
Procedure AssignWritingSettings(Form, Object) Export
	
	Object.AdditionalProperties.Insert("__DisableAttributesParameters", New Map);
	
	For each Item In Form.__DisableAttributesParameters Do
		Object.AdditionalProperties.__DisableAttributesParameters.Insert(Item.Key, Item.Value.Enabled);
	EndDo;
	
EndProcedure



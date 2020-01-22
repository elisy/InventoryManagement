

// Function implements user interaction
//
Function EnableKeyAttributeEditing(Form) Export

	Return False;

EndFunction


// Procedure enables form controls of key attributes.
// If all the key attributes are enabled enables button too.
// Parameters:
// Form         - ManagedForm - form to enable key attributes
// KeyAttributes - Array - enabled attributes
//
Procedure EnableFormControls(Form, Val KeyAttributes = Undefined) Export
	
	If KeyAttributes <> Undefined Then
		For each Attribute In KeyAttributes Do
			Form.__DisableAttributesParameters.Get(Attribute).Enabled = True;
		EndDo;
	EndIf;
	
	For each Item In Form.__DisableAttributesParameters Do
		If Item.Value.Enabled Then
			Control = Form.Items.Find(Item.Value.ControlName);
			If Control <> Undefined Then
				Control.ReadOnly = False
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure


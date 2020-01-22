
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	For each Item In Parameters.Filter Do
		RequiredFilterList.Add(Item.Key);
	EndDo;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	For each FilterName In RequiredFilterList Do
		For each Item In ThisForm.List.Filter.Items Do
			If Item.LeftValue = New DataCompositionField(FilterName) Then
				Item.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
			EndIf;
		EndDo;
	EndDo;

EndProcedure


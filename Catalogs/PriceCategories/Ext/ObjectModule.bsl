////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS

Procedure BeforeWrite(Cancel)
	
	ModuleRowOrder.BeforeWrite(ThisObject, Cancel);
	
EndProcedure


Procedure OnCopy(CopiedObject)
	
		ModuleRowOrder.OnCopy(ThisObject);
		
		Identifier = "";
	
EndProcedure


Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If NOT IsIdentifierUnique() Then
		Cancel = True;
		Message = New UserMessage();
		Message.Text = NStr("en = 'Database already has identifier ''%Identifier%''. Identifier should be unique.'; ru = 'В базе данных уже содержится вид цены с идентификатором ''%Identifier%''. Идентификатор должен быть уникальным.'");
		Message.Text = StrReplace(Message.Text, "%Identifier%", Identifier);
		Message.Field = "Object.Identifier";
		Message.SetData(ThisObject);
		Message.Message();
	EndIf;	
EndProcedure


Function IsIdentifierUnique()
	
	Query = New Query();
	Query.Text = "SELECT
	             |	1 AS Field1
	             |FROM
	             |	Catalog.PriceCategories AS PriceCategories
	             |WHERE
	             |	PriceCategories.Identifier = &Identifier
	             |	AND PriceCategories.Ref <> &Reference";
	Query.SetParameter("Reference", Ref);
	Query.SetParameter("Identifier", Identifier);
	
	Return Query.Execute().IsEmpty();
	
EndFunction



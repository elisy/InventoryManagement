&AtClient
Procedure InsertTextIntoExpression(TextToInsert, Shift = 0)
	
	StringBegin = 0;
	StringEnd   = 0;
	ColumnBegin = 0;
	ColumnEnd   = 0;
	
	Items.Expression.GetTextSelectionBounds(StringBegin, ColumnBegin, StringEnd, ColumnEnd);	
	
	If (ColumnEnd = ColumnBegin) AND (ColumnEnd + StrLen(TextToInsert)) > Items.Expression.Width / 8 Then
		Items.Expression.SelectedText = "";		
	EndIf;
		
	Items.Expression.SelectedText = TextToInsert;
	
	If NOT Shift = 0 Then		
		Items.Expression.GetTextSelectionBounds(StringBegin, StringEnd, StringEnd, ColumnEnd);		
		Items.Expression.SetTextSelectionBounds(StringBegin, StringEnd - Shift, StringEnd, ColumnEnd - Shift);
	EndIf;
		
	CurrentItem = Items.Expression;
																				
EndProcedure



&AtClient
Procedure ParametersSelection(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	InsertParameterIntoExpression();
EndProcedure


&НаКлиенте
Процедура InsertParameterIntoExpression()
	InsertTextIntoExpression(ModuleExpressionsClient.GetParameterTextToInsert(Items.Parameters.CurrentData.Value));
КонецПроцедуры



&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	Expression = Parameters.Expression;
	AttributeParameters.LoadValues(Parameters.Parameters);
	
	OperatorTreeStorageAddress = Undefined;
	If Parameters.Property("Operators", OperatorTreeStorageAddress) Then
		OperatorsValue = GetFromTempStorage(OperatorTreeStorageAddress);
	Else
		OperatorsValue = ModuleExpressions.GetDefaultOperatorTree();
	EndIf;
	ValueToFormAttribute(OperatorsValue, "Operators");
	
	If Parameters.Property("ParametersTitle") Then
		Items.GroupParameters.Title = Parameters.ParametersTitle;
		Items.GroupParameters.ToolTip = Parameters.ParametersTitle;
	EndIf;

EndProcedure


&AtClient
Procedure InsertOperatorIntoExpression()
	InsertTextIntoExpression(Items.Operators.CurrentData.Operator, Items.Operators.CurrentData.Shift);
EndProcedure


&AtClient
Procedure OperatorsSelection(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	InsertOperatorIntoExpression();
EndProcedure


&AtClient
Procedure Check(Command)
	ModuleExpressionsClient.CheckExpressionInteractively(Expression, AttributeParameters, "Expression");
EndProcedure


&AtClient
Procedure OK(Command)
	If ModuleExpressionsClient.CheckExpression(Expression, AttributeParameters, "Expression") Then
		Close(Expression);
	EndIf;           	
EndProcedure


&AtClient
Procedure ParametersDragStart(Item, DragParameters, StandardProcessing)
	DragParameters.Value = ModuleExpressionsClient.GetParameterTextToInsert(Item.CurrentData.Value);
EndProcedure


&AtClient
Procedure OperatorsDragStart(Item, DragParameters, StandardProcessing)
	
	If ValueIsFilled(Item.CurrentData.Operator) Then
		DragParameters.Value = Item.CurrentData.Operator;
	Else
		StandardProcessing = False;
	EndIf;

EndProcedure
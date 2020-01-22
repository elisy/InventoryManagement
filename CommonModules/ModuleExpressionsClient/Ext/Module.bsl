Function GetParameterTextToInsert(Parameter) Export
	Return "[" + Parameter + "]";
EndFunction


Function CheckExpression(Expression, Parameters, Field = Undefined, ErrorMessage = "") Export
	
	Result = True;
	
	CalculationText = Expression;
	If ValueIsFilled(CalculationText) Then				
		For each Parameter In Parameters Do
			CalculationText = StrReplace(CalculationText, GetParameterTextToInsert(Parameter), " 1 ");
		EndDo;
		Try
			EvalResult = Eval(CalculationText);
		Except
			Result = False;
			Info = ErrorInfo();
			Message = New UserMessage();
			Message.Text = ?(ValueIsFilled(ErrorMessage), ErrorMessage + ": ", "") + Info.Description;
			Message.Field = "Expression";
			Message.Message();
		EndTry;
	EndIf;
	
	Return Result;
	
EndFunction


Procedure CheckExpressionInteractively(Expression, Parameters, Field = Undefined) Export
	If ValueIsFilled(Expression) AND CheckExpression(Expression, Parameters, Field) Then
		DoMessageBox(NStr("en = 'Expression is valid.'; ru = 'Ошибок не обнаружено'"), , NStr("en = 'Test expression'; ru = 'Проверка формулы'"));
	EndIf;
EndProcedure


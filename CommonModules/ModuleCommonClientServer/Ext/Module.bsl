
////////////////////////////////////////////////////////////////////////////////
// Common client and server procedures and functions

// Composes and shows error message
//
// Parameters
//  MessageText  - String - message text.
//  Object  - Reference of form data - object editing in a form.
//  Field  - String - form control identifier.
//  Cancel  - Boolean - returns True.
//
// Example:
//   ModuleCommonClientServer.InformUser(
//	    NStr("en = 'Reason of task was failed.'; ru = 'Необходимо указать причину, по которой задача не выполнена.'"),
//	    Object,
//	    "ResultDescription",
//	    Cancel);
//
Procedure InformUser(Val MessageText,
							   Val Object = Undefined,
							   Val Field = "",
							   Cancel = False) Export

	Message = New UserMessage();
	Message.Text = MessageText;
	Message.Field = Field;
	Message.SetData(Object);
	Message.Message();
	Cancel = True;

EndProcedure





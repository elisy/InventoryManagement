////////////////////////////////////////////////////////////////////////////////
// Procedures are requiring the privileged mode

// Procedure determines user running the application and tries to find his/her in Users catalog.
// If user is not found creats new item. 
//Returns the CurrentUser session parameter as catalog item.
//
Procedure GetCurrentUserSessionParameter(Val ParameterName, SetParameters) Export
	
	If ParameterName <> "CurrentUser" Then
		Return;
	EndIf;
	
	UserName = UserName();
	UserFullName = UserFullName();
	
	If IsBlankString(UserName) Then
		UserName           = "<N/a>";
		UserFullName       = "<N/a>";
	Else
		If IsBlankString(UserFullName) Then
			UserFullName = UserName;
		EndIf;
	EndIf;
	
	ValidDescriptionLength = Metadata.Catalogs.Users.DescriptionLength;
	If StrLen(UserName) > ValidDescriptionLength Then
		UserName = Left(UserName, ValidDescriptionLength);
	EndIf;
	
	Query = New Query;
	Query.Text = "SELECT TOP 1
	             |	Users.Ref AS Ref
	             |FROM
	             |	Catalog.Users AS Users
	             |WHERE
	             |	Users.Code = &UserName";
	
	Query.Parameters.Insert("UserName", UserName);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		
		NewRef = Catalogs.Users.GetRef();
		SessionParameters.CurrentUser = NewRef;
		
		NewUser = Catalogs.Users.CreateItem();
		NewUser.Code        = UserName;
		NewUser.Description = UserFullName;
		NewUser.SetNewObjectRef(NewRef);
		
		Try
			NewUser.Write();
		Except
			ErrorMessage = ModuleStringFunctionsClientServer.FormatString(
			                                     NStr("en = 'User %1 was not found in the Users catalog. While creating user the following error has been occured:
                                                       |%2'; ru = 'Пользователь: %1 не был найден в справочнике пользователей. Возникла ошибка при добавлении пользователя в справочник.
                                                       |%2'"),
			                                     UserName, ErrorDescription() );
			Raise ErrorMessage;
		EndTry;
		
	Else
		Selection = Result.Choose();
		Selection.Next();
		SessionParameters.CurrentUser = Selection.Ref;
	EndIf;
	
	SetParameters.Insert(ParameterName);
	
EndProcedure


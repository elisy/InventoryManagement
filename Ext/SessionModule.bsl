
Procedure SessionParametersSetting(RequiredParameters)
	If RequiredParameters = Undefined Then
		
	Else
		//Session parameters setting by request
		
		SetParameters = New Structure;
		For each ParameterName In RequiredParameters Do
			SetSessionParameterValue(ParameterName, SetParameters);
		EndDo;
		
	EndIf;
EndProcedure


// Set session parameter values and return parameter names were changed in SetParameters
//
// Parameters
//  ParameterName  - String - parameter name to initialize.
//  SetParameters  - Structure - structure containing initialized parameter names as keys.
//
Procedure SetSessionParameterValue(Val ParameterName, SetParameters)
	
	If SetParameters.Property(ParameterName) Then
		Return;
	EndIf;
	
	// Users
	ModuleUsersFullRights.GetCurrentUserSessionParameter(ParameterName, SetParameters);

	If ParameterName = "ClientComputerName" Then
		SetParameters.Insert("ClientComputerName", "");
		SessionParameters[ParameterName] = SetParameters.ClientComputerName;
	EndIf;

EndProcedure

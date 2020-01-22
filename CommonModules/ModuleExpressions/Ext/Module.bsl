

Function GetEmptyOperatorTree() Export
	
	Tree = New ValueTree();
	Tree.Columns.Add("Description");
	Tree.Columns.Add("Operator");
	Tree.Columns.Add("Shift", New TypeDescription("Number"));
	
	Return Tree;
	
EndFunction



Function AddOperatorGroup(Tree, Description) Export
	
	NewGroup = Tree.Rows.Add();
	NewGroup.Description = Description;
	
	Return NewGroup;
	
EndFunction



Function AddOperator(Tree, Parent = Undefined, Description, Operator = Undefined, Shift = 0) Export
	
	NewRow = ?(Parent <> Undefined, Parent.Rows.Add(), Tree.Rows.Add());
	NewRow.Description = Description;
	NewRow.Operator = ?(ValueIsFilled(Operator), Operator, Description);
	NewRow.Shift = Shift;
	
	Return NewRow;
	
EndFunction



Function GetDefaultOperatorTree() Export
	
	Tree = GetEmptyOperatorTree();
	OperatorGroup = ModuleExpressions.AddOperatorGroup(Tree, "Operators");
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "+", " + ");
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "-", " - ");
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "*", " * ");
	ModuleExpressions.AddOperator(Tree, OperatorGroup, "/", " / ");
	
	Return Tree;
	
EndFunction


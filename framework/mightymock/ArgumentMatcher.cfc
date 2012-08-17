<cfcomponent output="false">
<cfscript>

  /*
  Requirement: Matches both the order or name of arguments. This is
  accomplished by understanding how the method being mocked is invoked
  by the component under tests; e.g.,

  script:
  function doSomething(foo,bar){
    obj.theMethod(foo,bar);
  }
  This is invoked using positional style and can be mocked like this:
  mock.theMethod( '{string}','{query}' ).returns(''); or
  mock.theMethod( foo='{string}', bar='{query}' ).returns(''); or
  It's more reliable to use named parameters as argumentcollection is
  an unordered map.

  CFML
  <cffunction name="doSomething">
	 <cfargument name="foo" />
	 <cfargument name="bar" />
	 <cfinvoke object="obj" method="theMethod"
	 					              foo="#foo#" bar="#bar#" />
	</cffunction>

   The above should be mocked using named parameter syntax to ensure
   argument matching:

   mock.theMethod( foo='{string}', bar='{query}' ).returns('');
*/

//the order here is very important because if you move string up you will never be able to get a numeric or a boolean
//array of supported data types
dataTypes = ['{binary}','{image}','{date}','{object}','{struct}','{udf}','{numeric}','{array}','{query}','{xml}','{boolean}','{string}','{any}'];
wildCardPattern = '{*}';
oneOrMorePattern = '{+}';

  function match(literal,pattern){
    var i = 0;
    var argType = '';
    var element = '';
    var key = '';
    var oArg = '';
    var flag = false;
    var oStringVal = '';
//crumpstar 08/17/2012 these are never used    
    var literalKeyString = structKeyArray(literal).toString();
    var patternKeyString = structKeyArray(pattern).toString();
    //var patternArgValues = arguments.pattern.values().toArray();
    //ensure the arguments passed are of treemap otherwise the order of the keys can not be guarnteed for comparisons
    if(!IsInstanceOf(literal, 'java.util.TreeMap')) literal = createObject('java','java.util.TreeMap').init(literal);
    if(!IsInstanceOf(pattern, 'java.util.TreeMap')) pattern = createObject('java','java.util.TreeMap').init(pattern);

   //maybe a wildcard
   if(pattern.size() == 1){
     flag = patternContainsWildCard( pattern,wildCardPattern );
     if(flag) return flag;
     flag = patternContainsWildCard( pattern,oneOrMorePattern );
     if(literal.size() && flag) return flag; //make sure there's at least one arg
   }

 //Validation ... extract method
   if( literal.size() != pattern.size() ){
     $throw('MismatchedArgumentNumberException',
            'Different number of parameters.',
            'Make sure the same number of paramters are passed in.');
   }
//i fear this is downright wrong 
// if(literal.equals(pattern)){
//	 the above expression is failing sometimes. argh/
//crumpstar 08-17-2012 I think this will accomplish the intended check as if the keys are different then there is no way a match can be made
if(structKeyList(literal) != structKeyList(pattern)){
  	  $throw('NamedArgumentConflictException',
          'Different parameter type definition.',
          'It appears that you defined a mock using named or ordered arguments, but attempted to invoke it otherwise. Please use either named or ordered argument, but not both.<br/>
          literal=#structKeyList(literal)#<br/>Pattern=#structKeyList(pattern)#');
   }

   for(key in literal){
     element = literal[key];
     oArg = pattern[key];
     if(oArg == '{any}') continue; //allow for 'ANY' type
     argType = getArgumentType(element);
     if(isValid('string', element)){
     	 if ((element == oArg) || (element =='{any}')) continue;  //allow for patterns that contain any
     	 if(arrayFind(dataTypes, element) > 0)argType=element;
     }     
     if( argType != oArg){
       if(isObject(element)){
        oStringVal = 'cfc or java class';
       }
       else{
        oStringVal = element.toString();
       }
      $throw('MismatchedArgumentPatternException',
             'Was looking at "#key# = #oStringVal#" and trying to match it to type: #oArg.toString()#',
             'Make sure the component being mocked matches parameter patterns, e.g., struct={struct}');
     }
   }

    return true;
  }



/*
  there's probably a better way to look up the type ...
*/
  function getArgumentType(arg){
  
   if (isBinary(arg)) return '{binary}';
   if (isImage(arg)) return '{image}';
   if (isDate(arg)) return '{date}';
   if (isObject(arg)) return '{object}';
   if (isStruct(arg)) return '{struct}';
   if (isCustomFunction(arg)) return '{udf}';
   if (isNumeric(arg)) return '{numeric}';
   if (isArray(arg)) return '{array}';
   if (isQuery(arg)) return '{query}';
   if (isXML(arg)) return '{xml}';
   if (isBoolean(arg)) return '{boolean}';   
   return '{string}';
   $throw('UnknownTypeException', 'Unknown type for #arg.toString()#'); //probably dead code here.
  }

  function buildPatternFromArguments(arg){
   var rtn = {};
   var key = '';		
   for(key in arg){
     rtn[key] = getArgumentType(arg[key]);
	}
	return createObject('java','java.util.TreeMap').init(rtn);
	//return rtn;
  }


  function patternContainsWildCard(pattern, wildcard){
    var results = structFindValue(pattern,wildcard);
    return arrayLen(results) > 0;
  }
	</cfscript>


 



<cffunction name="$throw">
	<cfargument name="type" required="false" default="mxunit.exception.AssertionFailedError">
	<cfargument name="message" required="false" default="failed behaviour">
	<cfargument name="detail" required="false" default="Details details ...">
  <cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#" />
</cffunction>

</cfcomponent>
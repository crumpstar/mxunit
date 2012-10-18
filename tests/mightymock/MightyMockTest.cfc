<cfcomponent output="false" extends="BaseTest">
<cfscript>

function $mockShouldBeAbleToReturnOtherMock(){
   mock2 = createObject('component','mxunit.framework.mightymock.MightyMock').init(mockery,true);
   //debug(mock2);
   mock.foo('asd').returns(mock2);
   t = mock.foo('asd');
   assertIsTypeOf(t, mockery);
}

function methodShouldBeAbleToReturnObject(){
   mock.reset();
   mock.foo('asd').returns(this);
   t = mock.foo('asd');
   assertIsTypeOf(t,'mxunit.tests.mightymock.MightyMockTest');
}

function clearOrResetMock(){
  mock.foo('asd').returns('asd');
  mock.foo('asd');
  debug(mock.debugMock());
  mock.reset();
  reg = mock._$getRegistry();
  debug(reg.invocationRecord);
  assert( reg.invocationRecord.recordCount == 0, 'invocation records still there' );
  assert( reg.registry.recordCount == 0, 'registry items still there' );

}


function simpleVerifyTest(){
//register new mock method
  mock.foo('asd').returns('asd');
  mock.foo('asd');  
  mock.verifyTimes(1).foo('asd');


  mock.foo2('asd').returns('123');
  mock.foo2('asd');
  mock.verify().foo2('asd');


  mock.verifyAtLeast(1).foo('asd');


  mock.foo2('asd');
  mock.foo2('asd');
  debug( mock.debugMock() );
  mock.verifyAtMost(3).foo2('asd');

  mock.verifyNever().xxx('asd');

  mock.bling(a).returns(true);
  mock.bling(a);
  mock.verifyOnce().bling(a);

}

function literalVerifyPatternTest(){
	
	//mock.literal(q).returns(q);
	
	
//register new mock method
	mock.literal('asd').returns('asd');
	debug(mock.debugMock());
	//should never have been called yet
	mock.verifyNever().literal('{string}');
	assertEquals('asd', mock.literal('asd'));
	//should pass as it has now been called once
	mock.verify().literal('{string}');
	mock.verify().literal('{+}');
	mock.verify().literal('{*}');
	mock.verify().literal('{any}');
	//simulate the mock being called with an unregistered signature
	mock.literal('dsa');
	mock.verifyTimes(2).literal('{string}');
	mock.verifyTimes(2).literal('{+}');
	mock.verifyTimes(2).literal('{*}');
	mock.verifyTimes(2).literal('{any}');
	//simulate the mock being called with completely different argument type
	mock.literal(true);
	
	//mock._$getRegistry().getInvocationRecords('literal', {1='{string}'}, true);
	
	mock.verifyTimes(2).literal('{string}');
	mock.verifyTimes(3).literal('{+}');
	mock.verifyTimes(3).literal('{*}');
	mock.verifyTimes(3).literal('{any}');
	//simulate the mock being called with no arguments this should increase the count
	//for 0+ wildcard but leave the count for 1+ wild card
	mock.literal();
	mock.verifyTimes(3).literal('{+}');
	mock.verifyTimes(4).literal('{*}');
	mock.verifyTimes(3).literal('{any}');
	//now lets crazy and really streatch the legs of the pattern matching
	
	mock.literal(now(),
				 this,
				 {'foo'="bar"},
				 this.setUp,
				 1000,
				 a,
				 x,
				 true,
				 toBinary(toBase64('stringer')),
				 imageNew(),
				 'stringer'
				 );
	//first and foremost the wildcars should have increased by one				 
	mock.verifyTimes(4).literal('{+}');
	mock.verifyTimes(5).literal('{*}');
	//a single argument should have stayed the same
	//mock._$getRegistry().getInvocationRecordsByPattern('literal', {1='{any}'}, true);
	
	mock.verifyTimes(3).literal('{any}');
	mock.verifyTimes(2).literal('{string}');
	//the following should have never been called because it was never called with these single arg
	mock.verifyNever().literal('{date}');
	mock.verifyNever().literal('{object}');
	mock.verifyNever().literal('{struct}');
	mock.verifyNever().literal('{udf}');
	mock.verifyNever().literal('{numeric}');
	mock.verifyNever().literal('{array}');
	mock.verifyNever().literal('{query}');
	mock.verifyNever().literal('{xml}');
	//check above we did call it with a boolean ;-)
	mock.verify().literal('{boolean}');
	mock.verifyNever().literal('{binary}');
	//mock._$getRegistry().getInvocationRecordsByPattern('literal', {1='{image}'}, true);
	mock.verifyNever().literal('{image}');
	//verify some mixed patterns
	mock.verify().literal('{date}','{object}','{struct}','{udf}','{numeric}','{array}','{xml}','{boolean}','{binary}','{image}','{string}');
	mock.verify().literal('{any}','{object}','{struct}','{udf}','{numeric}','{array}','{xml}','{boolean}','{binary}','{image}','{string}');
	mock.verify().literal('{any}','{object}','{any}','{udf}','{any}','{array}','{any}','{boolean}','{any}','{image}','{any}');
	mock.verify().literal('{date}','{object}','{struct}','{udf}',1000,'{array}','{xml}','{boolean}','{binary}','{image}','{string}');
	mock.verify().literal('{date}', this,{'foo'="bar"},'{udf}',1000,'{any}',x,true,toBinary(toBase64('stringer')),imageNew(),'{any}');
	mock.verify().literal('{any}', '{any}','{any}','{any}','{any}','{any}','{any}','{any}','{any}','{any}','{any}');
	
	
}


function patternVerifyLiteralTest(){
	
//register new mock method
	mock.pattern('{string}').returns('value');
	//should never have been called yet
	mock.verifyNever().pattern('arg1');
	mock.verifyNever().pattern('{string}');
	mock.verifyNever().pattern('{boolean}');
	mock.verifyNever().pattern('{any}');
	mock.verifyNever().pattern('{*}');
	mock.verifyNever().pattern('{+}');
//simulate CUT calling Mock	
	assertEquals('value', mock.pattern('arg1'));
	//should pass as it has now been called once
	mock.verify().pattern('{string}');
	mock.verify().pattern('arg1');
	mock.verify().pattern('{*}');
	mock.verify().pattern('{+}');
	mock.verifyNever().pattern('{boolean}');
	mock.verifyNever().pattern();
//Simulate the cut calling mock with unregistered params
	mock.pattern(1000);
	mock.verify().pattern('{string}');
	mock.verify().pattern('arg1');
	mock.verifyTimes(2).pattern('{any}');
	mock.verifyTimes(2).pattern('{*}');
	mock.verify(2).pattern('{+}');
	mock.verifyNever().pattern('{boolean}');
	mock.verifyNever().pattern();
	//now lets crazy and really streatch the legs of the pattern matching	
	mock.pattern('{date}','{object}','{struct}','{udf}','{numeric}','{array}','{xml}','{boolean}','{binary}','{image}','{string}').returns('booya');
	//first and foremost the everything should remain the same as we didn't call it				 
	mock.verify().pattern('{string}');
	mock.verify().pattern('arg1');
	mock.verifyTimes(2).pattern('{any}');
	mock.verifyTimes(2).pattern('{*}');
	mock.verify(2).pattern('{+}');
	mock.verifyNever().pattern('{boolean}');
	mock.verifyNever().pattern();
	//simulate CUT callin Mock
//Query and udf seem to fubar things because of byref vs byval	
	mock.pattern(now(),
				 this,
				 {'foo'="bar"},
				 1000,
				 a,
				 x,
				 true,
				 toBinary(toBase64('stringer')),
				 imageNew(),
				 'stringer'
				 );	
	//the following should have never been called because it was never called with these single arg
	mock.verifyNever().literal('{date}');
	mock.verifyNever().literal('{object}');
	mock.verifyNever().literal('{struct}');
	mock.verifyNever().literal('{udf}');
	mock.verifyNever().literal('{numeric}');
	mock.verifyNever().literal('{array}');
	mock.verifyNever().literal('{query}');
	mock.verifyNever().literal('{xml}');
	mock.verifyNever().literal('{binary}');
	mock.verifyNever().literal('{image}');
	//verify some mixed patterns
	mock.verify().pattern('{date}','{object}','{struct}','{numeric}','{array}','{xml}','{boolean}','{binary}','{image}','{string}');
	mock.verify().pattern('{any}','{object}','{struct}','{numeric}','{array}','{xml}','{boolean}','{binary}','{image}','{string}');
	mock.verify().pattern('{any}','{object}','{any}','{any}','{array}','{any}','{boolean}','{any}','{image}','{any}');
	mock.verify().pattern('{date}','{object}','{struct}',1000,'{array}','{xml}','{boolean}','{binary}','{image}','{string}');
	mock.verify().pattern('{date}', this,{'foo'="bar"},1000,'{any}',x,true,toBinary(toBase64('stringer')),imageNew(),'{any}');
	mock.verify().pattern('{any}', '{any}','{any}','{any}','{any}','{any}','{any}','{any}','{any}','{any}');
	
	
}


 function testRegisterNewMock(){
  mock.foo('bar').returns('foo');
  debug( mock.$debugReg());

 }

 function testThrows(){
   mock.foo('bar').throws( 'foobar' );
   try{
     mock.foo('bar');
     fail('should not get here.');
   }
   catch(foobar e){}
 }

 function testInvokeMock(){
  mock.foo('bar').returns( 'foobar' );
  actual = mock.foo('bar');
  debug( actual );
  assertEquals('foobar', actual);

 }

 function testStubalicous(){
   mock.foo('bar').returns( getQ() );
   actual = mock.foo('bar');
   debug( actual );
   assert(1,actual.recordCount);
 }


  function setUp(){
    mock = createObject('component','mxunit.framework.mightymock.MightyMock').init('my.mock');
  }

  function tearDown(){
    mock.reset();
  }



</cfscript>


<cffunction name="getQ" access="private">
<cf_querysim>
logger
foo,bar
1|2
</cf_querysim>
<cfreturn logger/>
</cffunction>

</cfcomponent>

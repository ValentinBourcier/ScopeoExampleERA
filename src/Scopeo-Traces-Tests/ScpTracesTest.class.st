Class {
	#name : 'ScpTracesTest',
	#superclass : 'TestCase',
	#instVars : [
		'traces'
	],
	#category : 'Scopeo-Traces-Tests',
	#package : 'Scopeo-Traces-Tests'
}

{ #category : 'running' }
ScpTracesTest >> setUp [

	super setUp.
	traces := ScpTraces new
		tracer: ScpInstrumenterTracer new;
		traceStorage: ScpTraceMemoryStorage new;
		forPackages: { ScpExampleObjectA package name };
		yourself.
]

{ #category : 'running' }
ScpTracesTest >> tearDown [

	super tearDown.

	traces clean
]

{ #category : 'tests' }
ScpTracesTest >> testExampleAccessorCall [

	| stateUdpates messagesToAccessor |
	traces scan: [
		|objectA objectB|
		objectB := ScpExampleObjectB new.
		objectA := ScpExampleObjectA new
			exampleObjectB: objectB;
			yourself.		
		objectA exampleAccessorCall.
	].

	stateUdpates := traces fetch: ScpIsStateUpdate new.
	messagesToAccessor := traces fetch: (ScpIsMessage new and: (ScpMessageSelectorEq value: #exampleAccessor)).

	self assert: stateUdpates size equals: 1.
	
	self assert: messagesToAccessor size equals: 1.
	self assert: messagesToAccessor first sender class equals: ScpExampleObjectA.
	self assert: messagesToAccessor first senderSelector equals: #exampleAccessorCall.
	self assert: messagesToAccessor first selector equals: #exampleAccessor.
	self assert: messagesToAccessor first receiver class equals: ScpExampleObjectB.
	self assert: messagesToAccessor first arguments size equals: 0.
]

{ #category : 'tests' }
ScpTracesTest >> testExampleInit [

	| stateUdpates |
	traces scan: [
		|objectA objectB|
		objectB := ScpExampleObjectB new.
		objectA := ScpExampleObjectA new
			exampleObjectB: objectB;
			yourself.
	].

	stateUdpates := traces fetch: ScpIsStateUpdate new.

	self assert: stateUdpates size equals: 1.
	self
		assert: stateUdpates first object class
		equals: ScpExampleObjectA.
	self assert: stateUdpates first variable equals: #exampleObjectB.
	self
		assert: stateUdpates first newValue class
		equals: ScpExampleObjectB
]

{ #category : 'tests' }
ScpTracesTest >> testExampleSetterCall [

	| stateUdpates messagesToSetter |
	traces scan: [
		|objectA objectB|
		objectB := ScpExampleObjectB new.
		objectA := ScpExampleObjectA new
			exampleObjectB: objectB;
			yourself.		
		objectA exampleSetterCall.
	].

	stateUdpates := traces fetch: ScpIsStateUpdate new.
	messagesToSetter := traces fetch:
		                    (ScpIsMessage new and:
			                     (ScpMessageSelectorEq value: #exampleSetter:)).

	self assert: stateUdpates size equals: 2.
	self
		assert: stateUdpates second object class
		equals: ScpExampleObjectB.
	self
		assert: stateUdpates second variable
		equals: #exampleInstanceVariable.
	self assert: stateUdpates second newValue equals: 'example'.

	self assert: messagesToSetter size equals: 1.
	self
		assert: messagesToSetter first sender class
		equals: ScpExampleObjectA.
	self
		assert: messagesToSetter first senderSelector
		equals: #exampleSetterCall.
	self assert: messagesToSetter first selector equals: #exampleSetter:.
	self
		assert: messagesToSetter first receiver class
		equals: ScpExampleObjectB.
	self assert: messagesToSetter first arguments size equals: 1.
	self assert: messagesToSetter first arguments first equals: 'example'
]

{ #category : 'tests' }
ScpTracesTest >> testExampleSetterCallInBlock [

	| stateUdpates messagesToSetter |
	traces scan: [
		|objectA objectB|
		objectB := ScpExampleObjectB new.
		objectA := ScpExampleObjectA new
			exampleObjectB: objectB;
			yourself.		
		objectA exampleSetterCallInBlock.
	].

	stateUdpates := traces fetch: ScpIsStateUpdate new.
	messagesToSetter := traces fetch:
		                    (ScpIsMessage new and:
			                     (ScpMessageSelectorEq value: #exampleSetter:)).

	self assert: stateUdpates size equals: 2.
	self
		assert: stateUdpates second object class
		equals: ScpExampleObjectB.
	self
		assert: stateUdpates second variable
		equals: #exampleInstanceVariable.
	self assert: stateUdpates second newValue equals: 'exampleInBlock'.

	self assert: messagesToSetter size equals: 1.
	self
		assert: messagesToSetter first sender class
		equals: ScpExampleObjectA.
	self
		assert: messagesToSetter first senderSelector
		equals: #exampleSetterCallInBlock.
	self assert: messagesToSetter first selector equals: #exampleSetter:.
	self
		assert: messagesToSetter first receiver class
		equals: ScpExampleObjectB.
	self assert: messagesToSetter first arguments size equals: 1.
	self
		assert: messagesToSetter first arguments first
		equals: 'exampleInBlock'
]

{ #category : 'tests' }
ScpTracesTest >> testExampleSetterCallInBlockInBlock [

	| stateUdpates messagesToSetter |
	traces scan: [
		|objectA objectB|
		objectB := ScpExampleObjectB new.
		objectA := ScpExampleObjectA new
			exampleObjectB: objectB;
			yourself.		
		objectA exampleSetterCallInBlockInBlock.
	].

	stateUdpates := traces fetch: ScpIsStateUpdate new.
	messagesToSetter := traces fetch:
		                    (ScpIsMessage new and:
			                     (ScpMessageSelectorEq value: #exampleSetter:)).

	self assert: stateUdpates size equals: 2.
	self
		assert: stateUdpates second object class
		equals: ScpExampleObjectB.
	self
		assert: stateUdpates second variable
		equals: #exampleInstanceVariable.
	self
		assert: stateUdpates second newValue
		equals: 'exampleInBlockInBlock'.

	self assert: messagesToSetter size equals: 1.
	self
		assert: messagesToSetter first sender class
		equals: ScpExampleObjectA.
	self assert: messagesToSetter first senderSelector equals: #exampleSetterCallInBlockInBlock.
	self assert: messagesToSetter first selector equals: #exampleSetter:.
	self
		assert: messagesToSetter first receiver class
		equals: ScpExampleObjectB.
	self assert: messagesToSetter first arguments size equals: 1.
	self
		assert: messagesToSetter first arguments first
		equals: 'exampleInBlockInBlock'
]

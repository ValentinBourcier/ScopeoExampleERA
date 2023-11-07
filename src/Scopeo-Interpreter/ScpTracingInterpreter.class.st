Class {
	#name : #ScpTracingInterpreter,
	#superclass : #ScpInterpreter,
	#instVars : [
		'defaultInterpreter',
		'storage',
		'packages'
	],
	#classInstVars : [
		'logger'
	],
	#category : #'Scopeo-Interpreter'
}

{ #category : #services }
ScpTracingInterpreter >> clean [

	"Do nothing"
]

{ #category : #environments }
ScpTracingInterpreter >> forPackages: aPackageNameCollection [

	packages := aPackageNameCollection
]

{ #category : #'as yet unclassified' }
ScpTracingInterpreter >> getSenderContext: aContext [

	aContext isBlockContext
		ifTrue: [ ^ self getSenderContext: aContext closure outerContext ]
		ifFalse: [ ^ aContext  ]
	 
]

{ #category : #initialization }
ScpTracingInterpreter >> initialize [

	defaultInterpreter := ScpDefaultInterpreter new.
]

{ #category : #'as yet unclassified' }
ScpTracingInterpreter >> isRejected: anObject [

	| senderClass|
	senderClass := anObject class.
	^ (senderClass ~~ UndefinedObject) and: [ 
			(packages includes: senderClass package name) not 
		]
]

{ #category : #'as yet unclassified' }
ScpTracingInterpreter >> senderSelectorFromContext: aContext [
	
	| context |
	context := (self getSenderContext: aContext).
	^  context receiver ifNotNil: [ context messageNode selector ]
]

{ #category : #services }
ScpTracingInterpreter >> traceExpressionString: anExpressionString [

	^ self evaluateAST: (RBParser parseExpression: anExpressionString)
]

{ #category : #initialization }
ScpTracingInterpreter >> traceStorage: aScpTraceStorage [

	storage := aScpTraceStorage
]

{ #category : #private }
ScpTracingInterpreter >> visitAssignmentNode: aRBAssignmentNode [

	| variable name value |
	variable := aRBAssignmentNode variable.
	name := variable name.
	value := self stackTop.

	variable isInstanceVariable ifTrue: [
		storage addStateUpdate: (ScpStateUpdate new
				 id: programCounter;
				 object: self currentContext receiver;
				 variable: variable variable name;
				 newValue: value;
				 yourself) ].

	self currentContext assignVariable: name value: value
]

{ #category : #visiting }
ScpTracingInterpreter >> visitBlockNode: aRBBlockNode [

	self stackPush: (DASTBlock new
			 initializeWith: aRBBlockNode;
			 outerContext: currentContext)
]

{ #category : #private }
ScpTracingInterpreter >> visitMessageNode: aRBMessageNode [

	| arguments receiver method newContext |

	(self isRejected: self currentContext receiver)
		ifTrue: [ ^ self visitMessageNodeWithoutTracing: aRBMessageNode ].

	arguments := (self stackPop: aRBMessageNode numArgs) reverse.
	(aRBMessageNode isCascaded and: [ aRBMessageNode isFirstCascaded not ])
		ifTrue: [ self stackPop ].
	receiver := self stackPop.

	" Current context initialization (implicit lookup)"
	newContext := DASTContext
		              newWithSender: self currentContext
		              receiver: receiver
		              messageNode: aRBMessageNode
		              evaluator: self evaluator.

	" Lookup"
	method := newContext methodOrBlock.
	
	storage addMessage: (ScpMessage new
			 id: programCounter;
			 sender: self currentContext receiver;
			 senderSelector: (self senderSelectorFromContext: self currentContext);
			 selector: method selector;
			 receiver: receiver;
			 arguments: arguments;
			 yourself).

	" Apply - invoke method "
	(aRBMessageNode isCascaded and: [
		 aRBMessageNode parent messages last ~= aRBMessageNode ]) ifTrue: [
		self stackPush: receiver ].
	(method isPrimitive and: [
		 method isMessageValue not and: [ method isOnDo not ] ]) ifTrue: [
		[
		^ self
			  solvePrimitive: method
			  receiver: receiver
			  arguments: arguments ]
			on: DASTPrimitiveFailed
			do: [ " Remove pragma node from method body to prevent infinit loop 
			  and continue with the excecution of the method body"
				newContext := newContext
					              removePrimitiveFromMethod;
					              yourself ] ].
	" Set new context "
	currentContext := newContext.
	currentContext
		setTemporalVariablesNamed: method argumentNames
		values: arguments
]

{ #category : #private }
ScpTracingInterpreter >> visitMessageNodeWithoutTracing: aRBMessageNode [

	defaultInterpreter currentContext: self currentContext.
	self currentContext evaluator interpreter: defaultInterpreter.
	
	defaultInterpreter visitMessageNode: aRBMessageNode.
				
	self currentContext: defaultInterpreter currentContext.
	self currentContext evaluator interpreter: self.
	
]
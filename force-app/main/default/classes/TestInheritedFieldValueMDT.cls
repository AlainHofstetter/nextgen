@IsTest
public class TestInheritedFieldValueMDT {
  @IsTest
  private static void callingGoShouldNotRegisterDirty() {
    // Create mock
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(
      mocks
    );

    // Given
    Invoice__c inv = new Invoice__c(
      ProjectName__c = fflib_IDGenerator.generate(Project__c.SObjectType),
      InvoiceDescription__c = 'Test'
    );
    List<InheritedFieldValue__mdt> meta = new InheritedFieldValueMDTSelector()
      .getInheritedFieldValueMDTTest();
    Application.UnitOfWork.setMock(uowMock);

    // When
    IInheritedFieldValueMDT domain = InheritedFieldValueMDT.newInstance(meta);
    domain.go(uowMock, new List<SObject>{ inv });

    // Then
  }

  private static InheritedFieldValue__mdt rule(
    String srcObj,
    String srcQuery,
    String relField,
    String targetField,
    Boolean ins,
    Boolean upd,
    Boolean userWins
  ) {
    return (InheritedFieldValue__mdt) JSON.deserialize(
      '{"UserValuesWinsOnInsert__c":' +
        userWins +
        ',"Insert__c":' +
        ins +
        ',"Update__c":' +
        upd +
        ',"SourceQuery__c":"' +
        srcQuery +
        '"' +
        ',"SourceObject__r":{"APIName__c":"' +
        srcObj +
        '"}' +
        ',"RelationshipField__r":{"APIName__c":"' +
        relField +
        '"}' +
        ',"TargetField__r":{"APIName__c":"' +
        targetField +
        '"}}',
      InheritedFieldValue__mdt.class
    );
  }

  @IsTest
  private static void goCoversRuleBranchesWithoutSourceRows() {
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(
      mocks
    );
    Application.UnitOfWork.setMock(uowMock);

    Invoice__c withValue = new Invoice__c(
      ProjectName__c = fflib_IDGenerator.generate(Project__c.SObjectType),
      InvoiceDescription__c = 'user supplied'
    );
    Invoice__c withoutValue = new Invoice__c(
      ProjectName__c = fflib_IDGenerator.generate(Project__c.SObjectType)
    );
    Invoice__c noRelation = new Invoice__c(); // relationship field null -> skipped via instanceof check

    List<InheritedFieldValue__mdt> meta = new List<InheritedFieldValue__mdt>{
      // first rule creates the query factory and the related-field set
      rule(
        'Project__c',
        'Name',
        'ProjectName__c',
        'InvoiceDescription__c',
        true,
        false,
        false
      ),
      // same source object again: reuses the factory, appends to the rule list
      rule(
        'Project__c',
        'Name',
        'ProjectName__c',
        'InvoiceDescription__c',
        true,
        false,
        false
      ),
      // user value wins on insert: skips records that already carry a value
      rule(
        'Project__c',
        'Name',
        'ProjectName__c',
        'InvoiceDescription__c',
        true,
        false,
        true
      ),
      // not enabled for insert: guard branch
      rule(
        'Project__c',
        'Name',
        'ProjectName__c',
        'InvoiceDescription__c',
        false,
        false,
        false
      )
    };

    IInheritedFieldValueMDT domain = InheritedFieldValueMDT.newInstance(meta);
    domain.go(
      uowMock,
      new List<SObject>{ withValue, withoutValue, noRelation }
    );
    domain.go(null, new List<SObject>{ withoutValue });

    // no Project__c rows exist in the test context, so nothing is applied
    System.assertEquals('user supplied', withValue.InvoiceDescription__c);
    System.assertEquals(null, withoutValue.InvoiceDescription__c);
  }
}

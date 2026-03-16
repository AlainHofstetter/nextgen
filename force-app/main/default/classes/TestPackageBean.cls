@IsTest
private class TestPackageBean {

  @IsTest
  private static void testSetBudgetAndServicesTotal() {

    JSONGenerator gen = JSON.createGenerator(true);
    gen.writeStartObject();
    gen.writeNumberField('BudgetAssignPackage__c', 0);
    gen.writeNumberField('ServicesTotalAmountCHF__c', 0);
    gen.writeEndObject();

    Package__c pck = (Package__c) JSON.deserialize(gen.getAsString(), Package__c.class);

    PackageBean bpGroup = new PackageBean();
    bpGroup.budget = 1;
    bpGroup.servicesTotal = 1;

    PackageBean bp = new PackageBean();
    bp.pck = pck;
    bp.setBudgetAndServicesTotal(bpGroup);

    System.assertEquals(10, bp.budget);
    System.assertEquals(0, bp.servicesTotal);
    System.assertEquals(11, bpGroup.budget);
    System.assertEquals(1, bpGroup.servicesTotal);
  }

  @IsTest
  private static void testSetPositionShouldSumPostionAmountInPackageGroup() {

    Package__c pck = new Package__c(
      Id = fflib_IDGenerator.generate(Package__c.SObjectType)
    );

    InvoicePos__c pos = new InvoicePos__c(
      Id = fflib_IDGenerator.generate(InvoicePos__c.SObjectType),
      InvoicePositionAmount__c = 10
    );

    Package__c fullPck
      = ((List<Package__c>) fflib_ApexMocksUtils.makeRelationship(
        List<Package__c>.class,
        new List<Package__c> {pck},
        InvoicePos__c.PackageName__c,
        new List<List<InvoicePos__c>> { new List<InvoicePos__c> {pos}}
      ))[0];

    PackageBean bpGroup = new PackageBean();
    bpGroup.setPosition(null);

    System.assertEquals(0, bpGroup.position.InvoicePositionAmount__c);

    PackageBean bp = new PackageBean();
    bp.pck = fullPck;
    bp.setPosition(bpGroup);

    System.assertEquals(bp.position.Id, pos.Id);
    System.assertEquals(bpGroup.position.InvoicePositionAmount__c, pos.InvoicePositionAmount__c);

  }

  @IsTest
  private static void testSetInvoiceAndInvoiceNoDraftTypeTime() {

    JSONGenerator gen = JSON.createGenerator(true);
    gen.writeStartObject();
    gen.writeStringField('PackageType__c', 'Time');
    gen.writeNumberField('InvoicePOSTotalTime__c', 1);
    gen.writeEndObject();

    Package__c pck = (Package__c) JSON.deserialize(gen.getAsString(), Package__c.class);
    pck.Id = fflib_IDGenerator.generate(Package__c.SObjectType);

    InvoicePos__c pos = new InvoicePos__c(
      Id = fflib_IDGenerator.generate(InvoicePos__c.SObjectType),
      InvoicePositionAmount__c = 10
    );

    PackageBean bpGroup = new PackageBean();
    bpGroup.invoice = 10;
    bpGroup.invoiceNoDraft = 2;

    PackageBean bp = new PackageBean();
    bp.pck = pck;
    bp.position = pos;
    bp.setInvoiceAndInvoiceNoDraft(bpGroup);

    System.assertEquals(1, bp.invoice);
    System.assertEquals(1, bp.invoiceNoDraft);
    System.assertEquals(11, bpGroup.invoice);
    System.assertEquals(3, bpGroup.invoiceNoDraft);
  }

  @IsTest
  private static void testSetInvoiceAndInvoiceNoDraftTypeExpense() {

    JSONGenerator gen = JSON.createGenerator(true);
    gen.writeStartObject();
    gen.writeStringField('PackageType__c', PackageDomain.TYPE_EXPENSE);
    gen.writeNumberField('InvoicePOSTotalExpense__c', 1);
    gen.writeEndObject();

    Package__c pck = (Package__c) JSON.deserialize(gen.getAsString(), Package__c.class);
    pck.Id = fflib_IDGenerator.generate(Package__c.SObjectType);

    InvoicePos__c pos = new InvoicePos__c(
      Id = fflib_IDGenerator.generate(InvoicePos__c.SObjectType),
      InvoicePositionAmount__c = 10
    );

    PackageBean bpGroup = new PackageBean();
    bpGroup.invoice = 10;
    bpGroup.invoiceNoDraft = 2;

    PackageBean bp = new PackageBean();
    bp.pck = pck;
    bp.position = pos;
    bp.setInvoiceAndInvoiceNoDraft(bpGroup);

    System.assertEquals(1, bp.invoice);
    System.assertEquals(1, bp.invoiceNoDraft);
    System.assertEquals(11, bpGroup.invoice);
    System.assertEquals(3, bpGroup.invoiceNoDraft);
  }

  @IsTest
  private static void testSetInvoiceAndInvoiceNoDraftTypeSupplierCosts() {

    JSONGenerator gen = JSON.createGenerator(true);
    gen.writeStartObject();
    gen.writeStringField('PackageType__c', PackageDomain.TYPE_SUPPLIER_COSTS);
    gen.writeNumberField('InvoicePOSTotalSupplierCosts__c', 1);
    gen.writeEndObject();

    Package__c pck = (Package__c) JSON.deserialize(gen.getAsString(), Package__c.class);
    pck.Id = fflib_IDGenerator.generate(Package__c.SObjectType);

    InvoicePos__c pos = new InvoicePos__c(
      Id = fflib_IDGenerator.generate(InvoicePos__c.SObjectType),
      InvoicePositionAmount__c = 10
    );

    PackageBean bpGroup = new PackageBean();
    bpGroup.invoice = 10;
    bpGroup.invoiceNoDraft = 2;

    PackageBean bp = new PackageBean();
    bp.pck = pck;
    bp.position = pos;
    bp.setInvoiceAndInvoiceNoDraft(bpGroup);

    System.assertEquals(1, bp.invoice);
    System.assertEquals(1, bp.invoiceNoDraft);
    System.assertEquals(11, bpGroup.invoice);
    System.assertEquals(3, bpGroup.invoiceNoDraft);
  }

  @IsTest
  private static void testSetAvailableFunds() {

    JSONGenerator gen = JSON.createGenerator(true);
    gen.writeStartObject();
    gen.writeNumberField('BudgetAssignPackage__c', 10);
    gen.writeEndObject();

    Package__c pck = (Package__c) JSON.deserialize(gen.getAsString(), Package__c.class);

    PackageBean bpGroup = new PackageBean();

    PackageBean bp = new PackageBean();
    bp.pck = pck;
    bp.invoice = 5;
    bp.setAvaliableFunds(bpGroup);

    System.assertEquals(5, bp.availableFunds);
    System.assertEquals(5, bpGroup.availableFunds);
  }

  @IsTest
  private static void testSetServiceTotalDRTime() {

    JSONGenerator pJSON = JSON.createGenerator(true);
    pJSON.writeStartObject();
    pJSON.writeStringField('PackageType__c', PackageDomain.TYPE_TIME);
    pJSON.writeEndObject();

    Package__c pck = (Package__c) JSON.deserialize(pJSON.getAsString(), Package__c.class);
    pck.Id = fflib_IDGenerator.generate(Package__c.SObjectType);

    JSONGenerator tJSON = JSON.createGenerator(true);
    tJSON.writeStartObject();
    tJSON.writeNumberField('ServiceTotalTime__c', 10);
    tJSON.writeEndObject();

    Time__c t = (Time__c) JSON.deserialize(tJSON.getAsString(), Time__c.class);
    t.Id = fflib_IDGenerator.generate(Time__c.SObjectType);

    Package__c fullPck
      = ((List<Package__c>) fflib_ApexMocksUtils.makeRelationship(
        List<Package__c>.class,
        new List<Package__c> {pck},
        Time__c.Package__c,
        new List<List<Time__c>> { new List<Time__c> {t}}
      ))[0];

    PackageBean bpGroup = new PackageBean();
    bpGroup.servicesTotalDR = 5;

    PackageBean bp = new PackageBean();
    bp.pck = fullPck;
    bp.setServicesTotalDR(bpGroup);

    System.assertEquals(10, bp.servicesTotalDR);
    System.assertEquals(15, bpGroup.servicesTotalDR);

  }

  @IsTest
  private static void testSetServiceTotalDRExpenses() {

    JSONGenerator pJSON = JSON.createGenerator(true);
    pJSON.writeStartObject();
    pJSON.writeStringField('PackageType__c', PackageDomain.TYPE_EXPENSE);
    pJSON.writeEndObject();

    Package__c pck = (Package__c) JSON.deserialize(pJSON.getAsString(), Package__c.class);
    pck.Id = fflib_IDGenerator.generate(Package__c.SObjectType);

    JSONGenerator eJSON = JSON.createGenerator(true);
    eJSON.writeStartObject();
    eJSON.writeNumberField('ServiceExpenseNet__c', 10);
    eJSON.writeEndObject();

    Expense__c e = (Expense__c) JSON.deserialize(eJSON.getAsString(), Expense__c.class);
    e.Id = fflib_IDGenerator.generate(Expense__c.SObjectType);

    Package__c fullPck
      = ((List<Package__c>) fflib_ApexMocksUtils.makeRelationship(
        List<Package__c>.class,
        new List<Package__c> {pck},
        Expense__c.Package__c,
        new List<List<Expense__c>> { new List<Expense__c> {e}}
      ))[0];

    PackageBean bpGroup = new PackageBean();
    bpGroup.servicesTotalDR = 5;

    PackageBean bp = new PackageBean();
    bp.pck = fullPck;
    bp.setServicesTotalDR(bpGroup);

    System.assertEquals(10, bp.servicesTotalDR);
    System.assertEquals(15, bpGroup.servicesTotalDR);

  }

  @IsTest
  private static void testSetServiceTotalDRSuplierCosts() {

    JSONGenerator pJSON = JSON.createGenerator(true);
    pJSON.writeStartObject();
    pJSON.writeStringField('PackageType__c', PackageDomain.TYPE_SUPPLIER_COSTS);
    pJSON.writeEndObject();

    Package__c pck = (Package__c) JSON.deserialize(pJSON.getAsString(), Package__c.class);
    pck.Id = fflib_IDGenerator.generate(Package__c.SObjectType);

    JSONGenerator scJSON = JSON.createGenerator(true);
    scJSON.writeStartObject();
    scJSON.writeNumberField('ServiceSupplierCostsNetPM__c', 10);
    scJSON.writeEndObject();

    SupplierCosts__c sc = (SupplierCosts__c) JSON.deserialize(scJSON.getAsString(), SupplierCosts__c.class);
    sc.Id = fflib_IDGenerator.generate(SupplierCosts__c.SObjectType);

    Package__c fullPck
      = ((List<Package__c>) fflib_ApexMocksUtils.makeRelationship(
        List<Package__c>.class,
        new List<Package__c> {pck},
        SupplierCosts__c.PackageName__c,
        new List<List<SupplierCosts__c>> { new List<SupplierCosts__c> {sc}}
      ))[0];

    PackageBean bpGroup = new PackageBean();
    bpGroup.servicesTotalDR = 5;

    PackageBean bp = new PackageBean();
    bp.pck = fullPck;
    bp.setServicesTotalDR(bpGroup);

    System.assertEquals(10, bp.servicesTotalDR);
    System.assertEquals(15, bpGroup.servicesTotalDR);

  }

  @IsTest
  private static void testEquals() {
    Package__c pck = new Package__c(Id = fflib_IDGenerator.generate(Package__c.SObjectType));

    PackageBean pb1 = new PackageBean();
    PackageBean pb2 = new PackageBean();
    pb1.pck = pck;
    pb2.pck = pck;

    System.assert(pb1.equals(pb2), 'oh, they are equal!');
  }


  @IsTest
  private static void testHashCode() {
    Package__c pck = new Package__c(Id = fflib_IDGenerator.generate(Package__c.SObjectType));

    PackageBean pb1 = new PackageBean();
    PackageBean pb2 = new PackageBean();
    pb1.pck = pck;
    pb2.pck = pck;

    System.assert(pb1.hashCode() == pb1.hashCode(), 'oh, they are equal!');
  }


}
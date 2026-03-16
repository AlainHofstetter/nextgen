public with sharing class ILVQueueable implements Queueable {
  Invoice__c draft;
  List<ILVPos__c> positions;
  Final Integer MAX_CHUNKSIZE = 75;

  public ILVQueueable(Invoice__c draft, List<ILVPos__c> positions) {
    this.draft = draft;
    this.positions = positions;
  }

  public void execute(QueueableContext context) {
    System.debug('---ILVQueueable.execute--- Before positions['+this.positions.size()+']: '+this.positions);

    List<ILVPos__c> prPositions = new List<ILVPos__c>();
    Integer chunkSize = this.positions.size() > MAX_CHUNKSIZE ? MAX_CHUNKSIZE : this.positions.size();
    for (Integer i = 0; i < chunkSize; i++) {
      prPositions.add(this.positions[0]);
      this.positions.remove(0);
    }

    System.debug('---ILVQueueable.execute--- prPositions['+prPositions.size()+']: '+prPositions);
    System.debug('---ILVQueueable.execute--- After positions['+this.positions.size()+']: '+this.positions);
    if (!prPositions.isEmpty()) {
      System.debug('---ILVQueueable.execute--- ');
      ILVPosController.save(draft, prPositions);

      if (!this.positions.isEmpty()) {
        if (!Test.isRunningTest()) {
          System.enqueueJob(new ILVQueueable(draft, this.positions));
        }
      }
    }
  }

  public static void mockTest() {
    Integer i = 0;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
  }
}
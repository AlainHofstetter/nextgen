public class AbacusTransferNGStaffHourScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new AbacusTransferNGStaffHourBatch(), 200);
    }
}
